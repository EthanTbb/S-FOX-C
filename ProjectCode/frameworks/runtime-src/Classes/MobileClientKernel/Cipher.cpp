#include "Cipher.h"


CCipher::CCipher()
{
}


CCipher::~CCipher()
{
}

int CCipher::mapsendbyte(BYTE data)
{
	return g_SendByteMap[data];
}

int CCipher::maprecvbyte(BYTE data)
{
	return g_RecvByteMap[data];
}

BYTE CCipher::encryptBuffer(void* pDataBuffer_, WORD wDataBufferSize)
{
	int nCheckCode;
	WORD wPacketSize;
	BYTE *pData;
	int nOneByte;

	struct TCP_Head *pDataBuffer = (struct TCP_Head *)pDataBuffer_;

	nCheckCode = 0;
	if (pDataBuffer && wDataBufferSize)
	{
		nCheckCode = 0;
		if (wDataBufferSize > sizeof(TCP_Info))
		{
			wPacketSize = wDataBufferSize - sizeof(TCP_Info);
			pData = (BYTE *)&pDataBuffer->CommandInfo;
			nCheckCode = 0;
			do
			{
				nOneByte = *pData;
				*pData = g_SendByteMap[nOneByte];
				nCheckCode = (nOneByte + nCheckCode) % 256;
				++pData;
				--wPacketSize;
			} while (wPacketSize);
		}
		pDataBuffer->TCPInfo.cbDataKind |= DK_MAPPED;
		pDataBuffer->TCPInfo.cbCheckCode = -(char)nCheckCode;
	}
	return (BYTE)nCheckCode;
}

BYTE CCipher::decryptBuffer(void* pDataBuffer_, WORD wDataBufferSize)
{
	BYTE cbCheckCode;
	WORD wPacketSize;
	BYTE *pData;
	BYTE nOneByte;

	struct TCP_Head *pDataBuffer = (struct TCP_Head *)pDataBuffer_;

	cbCheckCode = 0;
	if (wDataBufferSize > sizeof(TCP_Info) && pDataBuffer)
	{
		wPacketSize = wDataBufferSize - sizeof(TCP_Info);
		pData = (BYTE *)&pDataBuffer->CommandInfo;
		cbCheckCode = 0;
		do
		{
			nOneByte = g_RecvByteMap[*pData];
			*pData = nOneByte;
			cbCheckCode += nOneByte;
			++pData;
			--wPacketSize;
		} while (wPacketSize);
	}
	return cbCheckCode;
}