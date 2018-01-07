#include "DownAsset.h"

#include <thread>
#include "MobileClientKernel.h"
#include "FileAsset.h"

#include <curl/curl.h>
#include <curl/easy.h>
#include "Define.h"
#include <sys/stat.h>

#ifndef LOW_SPEED_LIMIT
#define LOW_SPEED_LIMIT 1L
#endif
#ifndef LOW_SPEED_TIME
#define LOW_SPEED_TIME 5L
#endif

//下载数据保存
static size_t downLoadPackage(void *ptr, size_t size, size_t nmemb, void *userdata)
{
     FILE *fp = (FILE*)userdata;
     size_t written = fwrite(ptr, size, nmemb, fp);
     return written;
}

//http下载进度回调
static int progressFunc(void *ptr, double totalToDownload, double nowDownloaded, double totalToUpLoad, double nowUpLoaded)
{
    if (totalToDownload <=0.000001)
    {
        return 0;
    }
    CDownAsset* tmpAssets = (CDownAsset*)ptr;
    if (tmpAssets)
    {
        int tmp = (int)(nowDownloaded / totalToDownload * 100);
        tmpAssets->upDatePro(tmp);
    }
    return 0;
}

//构造函数
CDownAsset::CDownAsset(const char* szUrl,const char* szFileName,const char* szSavePath,int nHandler)
: m_szDownUrl (szUrl)
, m_szFileName (szFileName)
, m_szSavePath (szSavePath)
, m_nHandler (nHandler)
{
	m_nPrecent = 0;
}

//析构函数
CDownAsset::~CDownAsset()
{

}

//创建函数
void CDownAsset::DownFile(const char* szUrl,const char* szFileName,const char* szSavePath,int nHandler)
{
	CDownAsset *pDownAsset = new CDownAsset(szUrl,szFileName,szSavePath,nHandler);
	//自动释放
	pDownAsset->autorelease();
	pDownAsset->retain();
    std::thread thr(&CDownAsset::DownRun, pDownAsset);
    thr.detach();
}

//更新进度
void CDownAsset::upDatePro(int precent)
{
	 if(precent != m_nPrecent)
	 {
	 	 m_nPrecent = precent;
	 	if((m_nPrecent % 2) == 0)
        {
            Notify(DOWN_PRO_INFO,m_nPrecent);
        }
	 }
}

//通知UI
void CDownAsset::Notify(int wMain,int wSub)
{
	if (m_nHandler != 0)
	{
		GetMCKernel()->HanderMessage(MSG_HTTP_DOWN,m_nHandler,(WORD)wMain,(WORD)wSub);
	}
}

// 下载工作函数
void CDownAsset::DownRun()
{
	//参数定义
	CURL *_curl = nullptr;
	std::string outFileName;
	FILE *fp  = nullptr;
	CURLcode res;

	do
	{
		
		//创建目录
		if (createDirectory(m_szSavePath.c_str()) == false)
		{
			CCLOG("download savepath create failed [%s]",m_szSavePath.c_str());
			Notify(DOWN_ERROR_PATH,0);
			break;
		}

		//保存文件
	    if (m_szSavePath[m_szSavePath.length()-1]=='/')
		    outFileName  = m_szSavePath + m_szFileName;
	    else
	        outFileName = m_szSavePath + "/" + m_szFileName;

	    fp= fopen(outFileName.c_str(), "wb+");
		if (! fp)
		{
			CCLOG("create outfile failed [%s]",outFileName.c_str());
			Notify(DOWN_ERROR_CREATEFILE,0);
			break;	
		}

	    //http协议
		_curl = curl_easy_init();
		if (! _curl)
		{
		 	Notify(DOWN_ERROR_CREATEURL,0);
		 	break;
		}

		curl_easy_setopt(_curl, CURLOPT_URL, m_szDownUrl.c_str());         	//下载地址
		curl_easy_setopt(_curl, CURLOPT_WRITEFUNCTION, downLoadPackage);   	//写入函数
		curl_easy_setopt(_curl, CURLOPT_WRITEDATA, fp);					   	//写入文件
		curl_easy_setopt(_curl, CURLOPT_NOPROGRESS, false);				   	//为了使CURLOPT_PROGRESSFUNCTION被调用. CURLOPT_NOPROGRESS必须被设置为false.
		curl_easy_setopt(_curl, CURLOPT_PROGRESSFUNCTION, progressFunc);   	//下载进度回调
		curl_easy_setopt(_curl, CURLOPT_PROGRESSDATA, this);			   	//进度回调参数
		curl_easy_setopt(_curl, CURLOPT_NOSIGNAL, 1L);					   	//屏蔽其它信号
		curl_easy_setopt(_curl, CURLOPT_LOW_SPEED_LIMIT, LOW_SPEED_LIMIT);	//控制传送字节
		curl_easy_setopt(_curl, CURLOPT_LOW_SPEED_TIME, 15);	//控制多少秒传送CURLOPT_LOW_SPEED_LIMIT
		curl_easy_setopt(_curl, CURLOPT_FOLLOWLOCATION, 1 );				//设置支持302重定向
		curl_easy_setopt(_curl, CURLOPT_CONNECTTIMEOUT, 15);					//设置超时

		//下载结果
		res = curl_easy_perform(_curl);
		if (res == CURLE_OK)
		{
			long retcode = 0;
			res = curl_easy_getinfo(_curl, CURLINFO_RESPONSE_CODE, &retcode);
			if (res == CURLE_OK && retcode == 200)
			{
				//下载长度
				double downsize = 0;
				res = curl_easy_getinfo(_curl, CURLINFO_CONTENT_LENGTH_DOWNLOAD, &downsize);
				if(res == CURLE_OK && downsize>0)
				{
					CCLOG("downfile ok downsize is %ld",(long)downsize);
					// //fflush(fp);
					// fseek( fp, 0, SEEK_END );
					// long file_size = ftell( fp );
					// fseek( fp, 0, SEEK_SET );
					// CCLOG("downfile_succeed downsize:%ld filesize:%ld",(long)downsize,file_size);
				}else{
					CCLOG("downfile_warn res:%d downsize is %ld",res,(long)downsize);
				}
			}
			else{
				CCLOG("downfile-http-faild res:%d code:%ld", res, retcode);
				res = CURL_LAST;
			}
		}else{
			CCLOG("downfile-curl_easy_perform-faild res:%d",res);
		}

		//清理
		curl_easy_cleanup(_curl);
		if(fp)
		{
			fclose(fp);
			fp = nullptr;
		}

		//通知结果
		Notify((res != CURLE_OK)?DOWN_ERROR_NET:DOWN_COMPELETED,res);
	}while(false);

	//释放清理
	if(fp)
	{
		fclose(fp);
		fp = nullptr;
	}
	release();
}


/************************************************************************/  
/* 获取要下载的远程文件的大小                                            */  
/************************************************************************/  
static long getDownloadFileLenth(const char *url){  
    double downloadFileLenth = 0;  
    CURL *handle = curl_easy_init();  
    curl_easy_setopt(handle, CURLOPT_URL, url);  
    curl_easy_setopt(handle, CURLOPT_HEADER, 1);    //只需要header头  
    curl_easy_setopt(handle, CURLOPT_NOBODY, 1);    //不需要body  
    if (curl_easy_perform(handle) == CURLE_OK)   
    {  
        curl_easy_getinfo(handle, CURLINFO_CONTENT_LENGTH_DOWNLOAD, &downloadFileLenth);  
    }   
    else   
    {  
        downloadFileLenth = -1;  
    }  
    curl_easy_cleanup(handle);
    return downloadFileLenth;  
}


