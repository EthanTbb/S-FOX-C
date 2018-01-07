#pragma once
#include <MobileClientKernel.h>
#include <vector>
#include <mutex>

//���c++���������������������gcc/clang���ɵ��������������������:
//��һ���ǳ���������������ڶ������õ�һ��������������+delete������
//����gcc/clang��delete obj_ptr_with_virtual_destructor_func;�ᱻ�����ֱ�ӵ��øö���ĵڶ���������������
interface IObj
{
	virtual bool Release() = 0;
};

interface IReleaseCash
{
	virtual void AddToCash(IObj *obj) = 0;
};

//http://www.debugease.com/vc/1982282.html
//std::list��ʵ�ֲ��� �����أ�std::vector�����飬��capacity������ʱ�򣬻�����newһ������ġ�
//std::map��set��ʵ�֣����Ǻ������
//stack��deque��ʵ����vector.
//string��typedef�����ģ�ԭ���Ǹ�����basic_string<T, ..., ...>
class CMCKernel :public IMCKernel,public IReleaseCash
{
	std::vector<IObj *> *m_pCashList;
	std::vector<CMessage *> *m_pMsgArray;
	std::mutex m_utex;
	ILog *m_log;
public:
	CMCKernel();
	virtual ~CMCKernel();
public:
	//IMsgHandler
	virtual bool HanderMessage(unsigned short wType, int nHandler, unsigned short wMain, unsigned short wSub, unsigned char *pBuffer/* = nullptr*/, unsigned short wSize/* = 0*/);
public:
	//IMCKernel
	virtual bool CheckVersion(unsigned long dwVersion);
	virtual const char* GetVersion();
	virtual ISocketServer* CreateSocket(int handler);
	virtual void OnMainLoop(IMessageRespon* respon, int maxCount = 0);
	virtual void SetLogOut(ILog *log);
public:
	//IReleaseCash
	virtual void AddToCash(IObj *obj);
public:
	void LogOut(const char *message);
private:
	static CMCKernel* instance;
public:
	static CMCKernel *GetInstance();
};

