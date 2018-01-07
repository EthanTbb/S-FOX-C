#include "MCKernel.h"
#include "SocketService.h"

CMCKernel * CMCKernel::instance = new CMCKernel;

CMCKernel::CMCKernel()
{
	std::vector<IObj *, std::allocator<IObj *> > *pCashList;
	std::vector<CMessage *, std::allocator<CMessage *> > *pMsgArray;

	pCashList = new std::vector<IObj *, std::allocator<IObj *>>;
	this->m_pCashList = pCashList;
	pMsgArray = new std::vector<CMessage *, std::allocator<CMessage *>>;
	this->m_pMsgArray = pMsgArray;
	this->m_log = NULL;
}

CMCKernel::~CMCKernel()
{
	std::vector<IObj *> *pCashList;
	std::vector<IObj *>::iterator ppCash;
	std::vector<CMessage *> *pMsgArray;
	std::vector<CMessage *>::iterator ppMsg;
	CMessage *pMsg;

	pCashList = this->m_pCashList;
	ppCash = pCashList->begin();
	while (ppCash != pCashList->end())
	{
		(*ppCash)->Release();
		++ppCash;
		pCashList = this->m_pCashList;
	}
	if (pCashList)
	{
		pCashList->clear();
		delete pCashList;
		this->m_pCashList = NULL;
	}
	pMsgArray = this->m_pMsgArray;
	for (ppMsg = pMsgArray->begin(); ppMsg != pMsgArray->end(); ++ppMsg)
	{
		pMsg = *ppMsg;
		if (*ppMsg)
		{
			delete pMsg;
			*ppMsg = NULL;
			pMsgArray = this->m_pMsgArray;
		}
	}
	if (pMsgArray)
	{
		pMsgArray->clear();
		delete pMsgArray;
		this->m_pMsgArray = NULL;
	}
}

bool CMCKernel::HanderMessage(unsigned short wType, int nHandler, unsigned short wMain, unsigned short wSub, unsigned char *pBuffer, unsigned short wSize)
{
	CMessage *pMsg;
	bool result;

	pMsg = new CMessage;
	pMsg->nHandler = nHandler;
	pMsg->wType = wType;
	pMsg->wMain = wMain;
	pMsg->wSub = wSub;
	if (pBuffer && wSize)
	{
		pMsg->pData = new unsigned char[wSize];
		pMsg->wSize = wSize;
		memcpy(pMsg->pData, pBuffer, wSize);
	}

	this->m_utex.lock();
	this->m_pMsgArray->push_back(pMsg);
	this->m_utex.unlock();

	result = true;
	return result;
}

bool CMCKernel::CheckVersion(unsigned long dwVersion)
{
	return true;
}

const char* CMCKernel::GetVersion()
{
	return "beta 0.1";
}

ISocketServer* CMCKernel::CreateSocket(int handler)
{
	CSocketService *pSocketService;

	pSocketService = new CSocketService(handler, this);
	return pSocketService;
}

void CMCKernel::OnMainLoop(IMessageRespon* respon, int maxCount)
{
	CMCKernel *pThis;
	int RemainCount;
	std::vector<IObj *> *pCashList;
	std::vector<IObj *>::iterator ppCash;
	IObj *pCash;
	ILog *log;
	const char *message;
	std::vector<CMessage *> *pMsgArray;
	CMessage *pMsg1;
	int LastRemainCount1;
	std::vector<CMessage *>::iterator ppMsg;
	CMessage *pMsg;
	int LastRemainCount;


	pThis = this;
	RemainCount = maxCount + 1;
	while (TRUE)
	{
		this->m_utex.lock();

		LastRemainCount = RemainCount;

		//删除当前待释放对象队列中第一个待释放对象
		pCashList = pThis->m_pCashList;
		ppCash = pCashList->begin();
		if (pCashList->end() != pCashList->begin())
		{
			pCash = *ppCash;
			if (*ppCash && pCash->Release())
			{
				pCashList->erase(ppCash);
				delete pCash;

				log = pThis->m_log;
				if (!log)
					goto _PEEK_MSG_;

				message = "delete cash";
				goto _LOG_OUT_;
			}
			log = pThis->m_log;
			if (log)
			{
				message = "didnot delete cash";
			_LOG_OUT_:
				log->LogOut(message);
				goto _PEEK_MSG_;
			}
		}
	_PEEK_MSG_:
		pMsgArray = pThis->m_pMsgArray;
		ppMsg = pMsgArray->begin();
		if (pMsgArray->end() == pMsgArray->begin())
		{
			this->m_utex.unlock();

			LastRemainCount1 = LastRemainCount;
		}
		else
		{
			//删除当前消息队列中第一个消息
			pMsg = *pMsgArray->begin();
			pMsgArray->erase(ppMsg);

			this->m_utex.unlock();

			pThis = this;
			pMsg1 = pMsg;
			if (respon && pMsg)
			{
				respon->OnMessageRespon(pMsg);
				pMsg1 = pMsg;
			}
			LastRemainCount1 = LastRemainCount;

			if (pMsg1)
			{
				delete pMsg1;
			}
		}
		RemainCount = LastRemainCount1 - 1;
		if (RemainCount <= 1)
			return;
	}
}

void CMCKernel::SetLogOut(ILog *log)
{
	this->m_log = log;
}

void CMCKernel::LogOut(const char *message)
{
	ILog *log;

	log = this->m_log;
	if (log)
		log->LogOut(message);
}

void CMCKernel::AddToCash(IObj *obj)
{
	ILog *log;

	CMCKernel* pThis = this;
	if (!obj)
	{
		goto _RESULT_;
	}

	pThis->m_utex.lock();
	pThis->m_pCashList->push_back(obj);
	pThis->m_utex.unlock();

	log = CMCKernel::instance->m_log;
	if (log)
		log->LogOut("m_pCashList push_back");
_RESULT_:
	return;
}

CMCKernel *CMCKernel::GetInstance()
{
	return CMCKernel::instance;
}