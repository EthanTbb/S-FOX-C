#include "SocketService.h"
#include "Define.h"
#include <thread>
#include "Cipher.h"
#include <assert.h>
#include "cocos2d.h"

//AppDelegate.cpp中有实现
long long getCurrentTime();

#ifdef WIN32
int win32_gettimeofday(struct timeval * val, struct timezone *)
{
	if (val)
	{
		SYSTEMTIME wtm;
		GetLocalTime(&wtm);

		struct tm tTm;
		tTm.tm_year = wtm.wYear - 1900;
		tTm.tm_mon = wtm.wMonth - 1;
		tTm.tm_mday = wtm.wDay;
		tTm.tm_hour = wtm.wHour;
		tTm.tm_min = wtm.wMinute;
		tTm.tm_sec = wtm.wSecond;
		tTm.tm_isdst = -1;

		val->tv_sec = (long)mktime(&tTm);	   // time_t is 64-bit on win32
		val->tv_usec = wtm.wMilliseconds * 1000;
	}
	return 0;
}
#endif

long long getCurrentTime()
{
	struct timeval tv;
#ifdef WIN32
	win32_gettimeofday(&tv, NULL);
#else
	gettimeofday(&tv, NULL);
#endif 
	long long ms = tv.tv_sec;
	return ms * 1000 + tv.tv_usec / 1000;
}

#ifndef INFINITE
#define INFINITE            0xFFFFFFFF  // Infinite timeout
#endif

//默认的授权码
#ifdef _WIN32
const TCHAR wValidate[64] = L"B3D44854-9C2F-4C78-807F-8C08E940166D";
#else
const char16_t wValidate[64] = u"B3D44854-9C2F-4C78-807F-8C08E940166D";
#endif

CSocketService::CSocketService(int nHandler, IMsgHandler *pEvent)
{
	this->m_wPort = 0;
	this->m_bServe = true;
	this->m_bRun = false;
	memset(this->m_szUrl, 0, sizeof(m_szUrl));
	this->m_nHandler = nHandler;
	this->m_pSocketEvent = pEvent;
	this->m_pSocket = nullptr;
	this->m_bHeartBeatKeep = false;
	this->m_lDelayTime = 90000LL;
	this->m_lWaitTime = INFINITE;
}


CSocketService::~CSocketService()
{

}

bool CSocketService::Release()
{
	bool bResult;
	CTCPSocket *pSocket;

	if (this->m_bRun)
	{
		bResult = false;
	}
	else if (this->m_bServe)
	{
		bResult = false;
	}
	else
	{
		pSocket = this->m_pSocket;
		bResult = true;
		if (pSocket)
		{
			delete pSocket;
			bResult = true;
			this->m_pSocket = NULL;
		}
	}
	return bResult;
}

bool CSocketService::Connect(const char* szUrl, unsigned short wPort, unsigned char* pValidate)
{
	bool result;
	unsigned char *pCurpValidate;
	CTCPSocket *pSocket;
	std::thread *CSocketService_thread;

	if (this->m_bServe)
	{
		if (this->m_bRun)
		{
			result = false;
		}
		else if (this->m_pSocket)
		{
			result = false;
		}
		else
		{
			result = false;
			if (szUrl && this->m_pSocketEvent)
			{
				if (*szUrl)
				{
					memset(this->m_szUrl, 0, sizeof(this->m_szUrl));
					strcpy(this->m_szUrl, szUrl);
					pCurpValidate = pValidate;
					this->m_wPort = wPort;
					this->m_bRun = true;
					if (!pValidate)
						pCurpValidate = (unsigned char *)wValidate;
					memcpy(this->m_Validate, pCurpValidate, sizeof(this->m_Validate));
					pSocket = new CTCPSocket(INVALID_SOCKET);
					this->m_pSocket = pSocket;
					CSocketService_thread = new std::thread(&CSocketService::OnRun, this);
					CSocketService_thread->detach();
					result = true;
				}
				else
				{
					result = false;
				}
			}
		}
	}
	else
	{
		result = false;
	}
	return result;
}
bool CSocketService::SendSocketData(unsigned short wMain, unsigned short wSub, const void* pData, unsigned short wDataSize)
{
	bool result;
	TCP_Buffer TcpBuffer;
	if (this->m_bServe)
	{
		if (this->m_bRun)
		{
			if (this->m_pSocket)
			{
				if (wDataSize < sizeof(TcpBuffer.cbBuffer))
				{
					memset(&TcpBuffer, 0, sizeof(TcpBuffer));
					TcpBuffer.Head.CommandInfo.wMainCmdID = wMain;
					TcpBuffer.Head.CommandInfo.wSubCmdID = wSub;
					TcpBuffer.Head.TCPInfo.wPacketSize = wDataSize + sizeof(TCP_Head);
					if (pData && wDataSize)
						memcpy(&TcpBuffer.cbBuffer, pData, wDataSize);
					CCipher::encryptBuffer(&TcpBuffer, (wDataSize + sizeof(TCP_Head)));
					result = this->m_pSocket->OnEventSocketSend(
						(const char *)&TcpBuffer, TcpBuffer.Head.TCPInfo.wPacketSize, 0);
				}
				else
				{
					result = false;
				}
			}
			else
			{
				result = false;
			}
		}
		else
		{
			result = false;
		}
	}
	else
	{
		result = false;
	}

	return result;
}

void CSocketService::StopServer()
{
	this->m_bServe = false;
}

bool CSocketService::IsServer()
{
	return this->m_bServe;
}
void CSocketService::SetHeartBeatKeep(bool bKeep)
{
	this->m_bHeartBeatKeep = bKeep;
}
void CSocketService::SetDelayTime(long time)
{
	this->m_lDelayTime = time;
}
void CSocketService::SetWaitTime(long time)
{
	this->m_lWaitTime = time;
}

void CSocketService::SetOverTime(long time)
{

}
void CSocketService::SetStopTime(long time)
{

}

void CSocketService::OnRun()
{
	bool bRet1;
	CMCKernel *pMCKernel;
	bool bRet;
	bool bContinueLoop;
	BYTE *cbBuffer;
	int LastLen;
	int nSelect;
	long long lCurTime;
	long long lHeartTime;
	long long lDelayTime;
	int RevCurLen;
	bool bReadedInfo;
	int DstLen;
	int RevSumLen;
	signed int nBackCode;
	unsigned char szValidate[128];
	IMsgHandler *pSocketEvent;
	CTCPSocket *pSocket;
	CSocketService *pThis;
	BYTE reciveBuffer[SOCKET_TCP_BUFFER];

	pThis = this;
	pSocket = this->m_pSocket;
	try
	{
		if (pSocket)
		{
			pSocketEvent = this->m_pSocketEvent;
			if (this->m_bServe && this->m_bRun)
			{
				if (!pSocket->OnEventSocketCreate(AF_INET, SOCK_STREAM, 0))
				{
					throw sser_SocketCreateFailed;
				}
				if (!pSocket->OnEventSocketConnet(this->m_szUrl, this->m_wPort))
				{
					throw sser_SocketConnectFailed;
				}
				ZeroMemory(szValidate, sizeof(szValidate));
				memcpy(szValidate, this->m_Validate, sizeof(szValidate));
				if (!this->SendSocketData(MDM_KN_COMMAND, SUB_KN_VALIDATE_SOCKET, szValidate, sizeof(szValidate)))
				{
					throw sser_SocketSendValidatePackageFailed;
				}
				if (!pSocketEvent)
				{
					throw sser_MsgHandlerPtrIsInvalid;
				}
				bRet1 = pSocketEvent->HanderMessage(MSG_SOCKET_CONNECT, this->m_nHandler, 0, 0, NULL, 0);
				nBackCode = 0;
				RevSumLen = 0;
				DstLen = sizeof(TCP_Info);
				bReadedInfo = false;
				memset(reciveBuffer, 0, sizeof(reciveBuffer));
				lDelayTime = getCurrentTime();
				lHeartTime = getCurrentTime();
				do
				{
					if (!this->m_bServe || !this->m_bRun)
						break;
					lCurTime = getCurrentTime();
					if (this->m_lDelayTime)
					{
						if (lDelayTime)
						{
							if (lCurTime - lDelayTime >= this->m_lDelayTime)
							{
								throw sser_TimeIsError;
							}
						}
						else
						{
							lDelayTime = lCurTime;
						}
					}
					if (lHeartTime)
					{
						if (lCurTime - lHeartTime > 15000)
						{
							//CCLOG("发送心跳包 this=0x%p lCurTime=%I64d", this,lCurTime);
							if (!this->SendSocketData(MDM_KN_COMMAND, SUB_KN_DETECT_SOCKET, NULL, 0))
							{
								pMCKernel = CMCKernel::GetInstance();
								pMCKernel->LogOut("send heartbeat package fail");
								throw sser_SocketSendHeartBeatPackageFailed;
							}
							lHeartTime = lCurTime;
						}
					}
					else
					{
						lHeartTime = lCurTime;
					}
					nSelect = pSocket->OnEventSocketSelect();
					if (nSelect == -1)
					{
						throw sser_SocketIsInvalid;
					}
					if (nSelect == -2)
					{
						RevCurLen = pSocket->OnEventSocketRecv((char *)&reciveBuffer[RevSumLen], DstLen - RevSumLen, 0);
						if (RevCurLen <= 0)
						{
							throw sser_SocketIsInvalid;
						}
						RevSumLen += RevCurLen;
						if (RevSumLen >= DstLen)
						{
							if (bReadedInfo)
							{
								lHeartTime = lCurTime;
								CCipher::decryptBuffer(reciveBuffer, DstLen);
								TCP_Buffer* pTcpBuffer = (TCP_Buffer*)reciveBuffer;
								if (pTcpBuffer->Head.CommandInfo.wMainCmdID || pTcpBuffer->Head.CommandInfo.wSubCmdID != SUB_KN_DETECT_SOCKET)
								{
									if (this->m_lDelayTime)
										lDelayTime = getCurrentTime();
									if (pSocketEvent && this->m_bServe)
									{
										if (RevSumLen == sizeof(TCP_Head))
											cbBuffer = NULL;
										else
											cbBuffer = pTcpBuffer->cbBuffer;
										nBackCode = pSocketEvent->HanderMessage(MSG_SOCKET_DATA, this->m_nHandler,
											pTcpBuffer->Head.CommandInfo.wMainCmdID, pTcpBuffer->Head.CommandInfo.wSubCmdID,
											cbBuffer, RevSumLen - sizeof(TCP_Head));
									}
									else
									{
										nBackCode = -1;
									}
								}
								LastLen = RevSumLen - DstLen;
								if (RevSumLen - DstLen > 0)
									memmove(reciveBuffer, &reciveBuffer[DstLen], LastLen);
								DstLen = sizeof(TCP_Info);
								bReadedInfo = false;
								RevSumLen = LastLen;
							}
							else
							{
								TCP_Buffer* pTcpBuffer = (TCP_Buffer*)reciveBuffer;
								DstLen = pTcpBuffer->Head.TCPInfo.wPacketSize;
								bReadedInfo = true;
							}
						}
					}
					if (nBackCode == -1)
					{
						this->m_bRun = false;
					}
					else if (this->m_lWaitTime != INFINITE)
					{
						//long long llCurTime = getCurrentTime();
						//CCLOG("执行等待【开始】 this=0x%p lWaitTime=%d llCurTime=%I64d", this, this->m_lWaitTime, llCurTime);
						//long long llStartTime = getCurrentTime();
						sleep_ms(this->m_lWaitTime);
						//long long llTaskTime = getCurrentTime() - llStartTime;
						//CCLOG("执行等待【结束】 this=0x%p llTaskTime=%d", this, llTaskTime);
					}
					bContinueLoop = false;
					if (this->m_bServe)
					{
						bContinueLoop = false;
						if (this->m_bRun)
						{
							bContinueLoop = false;
							if (this->m_pSocket)
								bContinueLoop = pSocketEvent != NULL;
						}
					}
				} while (bContinueLoop);
				if (this->m_bServe && pSocketEvent)
					bRet = pSocketEvent->HanderMessage(MSG_SOCKET_CLOSED, this->m_nHandler, 0, 0, NULL, 0);
			}
			this->FinishRun();
		}
	}
	catch (SocketServiceRunErrorCode e)
	{
		if (this->m_bServe)
		{
			char szError[260];
			snprintf(szError, CountArray(szError), "SocketService throw error %d this=0x%p\r\n", e, this);
			//assert(!szError);
			printf("s",szError);
		}
	}
}

void CSocketService::FinishRun()
{
	int nRet;
	CMCKernel *pMCKernel;
	bool bRet;

	this->m_bRun = false;
	if (CMCKernel::GetInstance())
	{
		nRet = this->m_pSocket->OnEventSocketClose();
		pMCKernel = CMCKernel::GetInstance();
		pMCKernel->AddToCash(this);
	}
	else
	{
		this->m_bServe = false;
		bRet = this->Release();
	}
}
