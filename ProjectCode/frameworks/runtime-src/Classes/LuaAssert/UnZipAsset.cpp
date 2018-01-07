#include "UnZipAsset.h"
#include "FileAsset.h"
#include <thread>
#include "MobileClientKernel.h"
#include "Define.h"
#ifdef MINIZIP_FROM_SYSTEM
#include <minizip/unzip.h>
#else
#include "unzip/unzip.h"
#endif

static unsigned long  _maxUnzipBufSize = 0x500000;
//解压zip
static bool unzip(const char *zipPath,const char *dirpath,const char *passwd,bool bAsset)
{
    CCLOG("unzip info:zippath[%s]\n dirpath[%s]",zipPath,dirpath);
    if (false == FileUtils::getInstance()->isFileExist(zipPath))
    {
        CCLOG("zipfile [%s] not exist",zipPath);
        return false;
    }
    unzFile pFile;
    if(!bAsset)
    {
         pFile = unzOpen(zipPath);
    }
    else
    {
        ssize_t len = 0;
        unsigned char *data = CCFileUtils::getInstance()->getFileData(zipPath, "rb", &len);
        pFile = unzOpenBuffer(data,len);
    }
    if(!pFile)
    {
        CCLOG("unzip error get zip file false");
        return false;
    }
    std::string szTmpDir = dirpath;
    if (szTmpDir[szTmpDir.length()-1]!='/'){
        szTmpDir = szTmpDir+"/";
    }
    int err = unzGoToFirstFile(pFile);
    bool ret = true;
    while (err == UNZ_OK)
    {
        int nRet = 0;
        int openRet = 0;
        do
        {
            if(passwd)
            {
                openRet = unzOpenCurrentFilePassword( pFile,passwd);
                CCLOG("openRet %d",openRet);
            }
            else
            {
                openRet = unzOpenCurrentFile(pFile);
            }
            CC_BREAK_IF(UNZ_OK != openRet);
            unz_file_info FileInfo;
            char szFilePathA[260];
            nRet = unzGetCurrentFileInfo(pFile, &FileInfo, szFilePathA, sizeof(szFilePathA), NULL, 0, NULL, 0);
            CC_BREAK_IF(UNZ_OK != nRet);
            //如果szFilePathA为中文的话，请使用iocnv转码后再使用。

            std::string newName = szTmpDir +szFilePathA;
            if (newName[newName.length()-1]=='/')
            {
                createDirectory(newName.c_str());
                continue;
            }

            FILE* pFile2 = fopen(newName.c_str(), "w");
            if (pFile2)
            {
                fclose(pFile2);
            }
            else
            {
                CCLOG("unzip can not create file");
                return false;
            }

            unsigned long savedSize = 0;
            pFile2 = fopen(newName.c_str(), "wb");
            while(pFile2 != NULL && FileInfo.uncompressed_size > savedSize)
            {
                unsigned char *pBuffer = NULL;
                unsigned long once = FileInfo.uncompressed_size - savedSize;
                if(once > _maxUnzipBufSize)
                {
                    once = _maxUnzipBufSize;
                    pBuffer = new unsigned char[once];
                }
                else
                {
                    pBuffer = new unsigned char[once];
                }
                int nSize = unzReadCurrentFile(pFile, pBuffer, once);
                fwrite(pBuffer, once, 1, pFile2);
                
                savedSize += nSize;
                delete []pBuffer;
            }
            if (pFile2)
            {
                fclose(pFile2);
            }
            
        } while (0);
        if(nRet != UNZ_OK)
        {
            ret = false;
        }
        else
        {
            unzCloseCurrentFile(pFile);
        }
        err = unzGoToNextFile(pFile);
    }
    
    if(err != UNZ_END_OF_LIST_OF_FILE)
    {
        ret = false;
    }
    unzClose(pFile);
    return ret;
}

CUnZipAsset::CUnZipAsset(const char* szFilePath,const char* szUnZipPath,int nHandler)
: m_szFilePath(szFilePath)
, m_szUnZipPath(szUnZipPath)
, m_nHandler(nHandler)
{

}

CUnZipAsset::~CUnZipAsset()
{

}

void CUnZipAsset::UnZipFile(const char* szFilePath,const char* szUnZipPath,int nHandler)
{
	CUnZipAsset *pUnzipAsset = new CUnZipAsset(szFilePath,szUnZipPath,nHandler);
	pUnzipAsset->autorelease();
	pUnzipAsset->retain();
    std::thread thr(&CUnZipAsset::UnZipRun, pUnzipAsset);
    thr.detach();
}

void CUnZipAsset::UnZipRun()
{
     //解压
    int result = 0;
     //创建解压
    if (createDirectory(m_szUnZipPath.c_str()))
    {
        if(unzip(m_szFilePath.c_str(),m_szUnZipPath.c_str(),NULL,true))
      	{
      		result = 1;
      	}
    }else{
    	CCLOG("download unzippath create fail [%s]",m_szUnZipPath.c_str());
    }

    if(m_nHandler != 0)
    {
		GetMCKernel()->HanderMessage(MSG_UN_ZIP,m_nHandler,result,0);
    }
    release();
}
