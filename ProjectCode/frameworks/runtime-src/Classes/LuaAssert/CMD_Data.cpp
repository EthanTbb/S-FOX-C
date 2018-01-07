#include "CMD_Data.h"
#include "LuaAssert.h"

//构造函数
CCmd_Data::CCmd_Data(WORD nLenght):m_wMain(0),m_wSub(0),m_wCurIndex(0)
{
	if(nLenght>0)
	{
		m_bAutoLen = false;
		m_wMaxLenght = nLenght;
		m_pBuffer = new BYTE[nLenght];
		memset(m_pBuffer,0,nLenght);
	}
	else
	{
		m_bAutoLen = true; 
		m_wMaxLenght = AUTO_LEN;
		m_pBuffer = new BYTE[AUTO_LEN];
		memset(m_pBuffer,0,AUTO_LEN);
	}
}
//析构函数
CCmd_Data::~CCmd_Data()
{
	CC_SAFE_DELETE(m_pBuffer);
}
//创建对象
CCmd_Data* CCmd_Data::create(int nLenght)
{
	CCmd_Data* data = new CCmd_Data(nLenght);
	data->autorelease();
	return data;
}
//设置命令
VOID CCmd_Data::SetCmdInfo(WORD wMain,WORD wSub)
{
	m_wMain = wMain;
	m_wSub = wSub;
}
//填充数据
WORD CCmd_Data::PushByteData(BYTE* cbData,WORD wLenght)
{
	do
	{
		//非法过滤
		if(wLenght == 0&&cbData == NULL)
		{
			CCLOG("[_DEBUG]	pushByteData-error-null-input");
			break;
		}
		if(m_wCurIndex+wLenght > m_wMaxLenght)
		{
			if(!m_bAutoLen)
			{
				CCLOG("[_DEBUG]	pushByteData-error:[cur:%d][max:%d][add:%d]",m_wCurIndex,m_wMaxLenght,wLenght);
				break;
			}else{
				WORD wNewLen = (m_wMaxLenght + wLenght)*2;
				BYTE* pNewData =  new BYTE[wNewLen];
				memset(pNewData,0,wNewLen);
				memcpy(pNewData,m_pBuffer,m_wMaxLenght);
				m_wMaxLenght = wNewLen;
				CC_SAFE_DELETE(m_pBuffer);
				m_pBuffer = pNewData;
			}
		}
		//填充数据
		if(cbData != NULL)
			memcpy(m_pBuffer + m_wCurIndex,cbData,wLenght);
		//游标更新
		m_wCurIndex += wLenght;
	}while(false);
	return m_wCurIndex;
}
