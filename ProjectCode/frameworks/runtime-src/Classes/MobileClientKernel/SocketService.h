#pragma once
#include <MobileClientKernel.h>
#include "MCKernel.h"
#include "TCPSocket.h"

#pragma execution_character_set("utf-8") 



//gcc的c++对象的虚表内存布局貌似是:第一个接口的虚函数序列完了接本对象增加的虚函数序列再接第二个接口的虚函数序列
class CSocketService :public IObj,public ISocketServer
{
	bool m_bServe;
	bool m_bRun;
	char m_szUrl[256];
	WORD m_wPort;
	int m_nHandler;
	unsigned char m_Validate[128];
	bool m_bHeartBeatKeep;
	long long m_lDelayTime;
	IMsgHandler *m_pSocketEvent;
	CTCPSocket *m_pSocket;
	int m_lWaitTime;//不使用long是因为long在64位ios/linux下是64位的
private:
	enum SocketServiceRunErrorCode
	{
		sser_NoError,
		sser_SocketCreateFailed,
		sser_SocketSendValidatePackageFailed,
		sser_SocketConnectFailed,
		sser_UnUsed1,
		sser_SocketIsInvalid,
		sser_TimeIsError,
		sser_UnUsed2,
		sser_MsgHandlerPtrIsInvalid,
		sser_SocketSendHeartBeatPackageFailed,
	};
public:
	CSocketService(int nHandler, IMsgHandler *pEvent);
	virtual ~CSocketService();
public:
	//IObj
	virtual bool Release();
public:
	//ISocketServer
	virtual bool Connect(const char* szUrl, unsigned short wPort, unsigned char* pValidate = nullptr);
	virtual bool SendSocketData(unsigned short wMain, unsigned short wSub, const void* pData = nullptr, unsigned short wDataSize = 0);
	virtual void StopServer();
	virtual bool IsServer();
	virtual void SetHeartBeatKeep(bool bKeep);
	virtual void SetDelayTime(long time);
	virtual void SetWaitTime(long time);
	virtual void SetOverTime(long time);
	virtual void SetStopTime(long time);
private:
	void OnRun();
	void FinishRun();
};

