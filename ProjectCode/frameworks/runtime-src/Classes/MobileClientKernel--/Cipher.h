#pragma once

#include "packet.h"

class CCipher
{
public:
	CCipher();
	~CCipher();
public:
	static int mapsendbyte(BYTE data);
	static int maprecvbyte(BYTE data);
	static BYTE encryptBuffer(void *pDataBuffer, WORD wDataBufferSize);
	static BYTE decryptBuffer(void* pDataBuffer_, WORD wDataBufferSize);
};

