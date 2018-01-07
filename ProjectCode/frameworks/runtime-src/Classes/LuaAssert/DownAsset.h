#ifndef DOWN_ASSETS
#define DWON_ASSETS

#include <string>
#include "cocos2d.h"


using namespace cocos2d;
using namespace std;

// CURL下载类
class CDownAsset :public cocos2d::Node
{
protected:
	std::string	m_szDownUrl;			//下载地址
	std::string	m_szSavePath;			//保存目录
	std::string m_szFileName;			//文件名
	int m_nHandler;						//回调通知
	int m_nPrecent;						//下载进度
protected:
	//构造函数
	CDownAsset(const char* szUrl,const char* szFileName,const char* szSavePath,int nHandler);
	
public:
	//析构函数
	virtual ~CDownAsset();

public:
	//创建函数
	static void DownFile(const char* szUrl,const char* szFileName,const char* szSavePath,int nHandler);

public:
	//更新进度
	void upDatePro(int precent);

protected:
	//通知UI
	void Notify(int wMain,int wSub);
	//下载函数
	void DownRun();

};
#endif