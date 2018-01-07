#pragma once
#include <MobileClientKernel.h>
#include <vector>
#include <mutex>

//如果c++对象包含虚拟析构函数，gcc/clang生成的虚表会包含两个析构函数:
//第一个是常规的析构函数，第二个调用第一个虚拟析构函数+delete本对象
//所以gcc/clang中delete obj_ptr_with_virtual_destructor_func;会被翻译成直接调用该对象的第二个虚拟析构函数
interface IObj
{
	virtual bool Release() = 0;
};

interface IReleaseCash
{
	virtual void AddToCash(IObj *obj) = 0;
};

//http://www.debugease.com/vc/1982282.html
//std::list的实现才是 链表呢，std::vector是数组，在capacity不够的时候，会重新new一个更大的。
//std::map和set的实现，总是红黑树，
//stack和deque的实现是vector.
//string是typedef出来的，原来那个类是basic_string<T, ..., ...>
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

