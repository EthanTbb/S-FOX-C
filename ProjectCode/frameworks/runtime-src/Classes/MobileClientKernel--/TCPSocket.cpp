#include "TCPSocket.h"

#ifdef _WIN32
#define EINPROGRESS WSAEINPROGRESS
#define SHUT_RDWR SD_BOTH
#endif

CTCPSocket::CTCPSocket(SOCKET sock)
{
	this->m_sock = sock;
	this->m_bDetach = true;
	this->server_addr = NULL;
}


CTCPSocket::~CTCPSocket()
{
}

bool CTCPSocket::OnEventSocketCreate(int af, int type, int protocol)
{
	SOCKET sock;
	int fhFlags;
	int nResult1;
	bool bResult;
	int nResult2;

	sock = socket(af, type, protocol);
	this->m_sock = sock;
	if (sock == INVALID_SOCKET)
_FAILED_:
	return false;
#ifndef _WIN32
	fhFlags = fcntl(sock, F_GETFL);
	nResult1 = fcntl(this->m_sock, F_SETFL, fhFlags | O_NONBLOCK);
#else
	fhFlags;
	unsigned long off;
	off = 0;
	nResult1 = ioctlsocket(this->m_sock, FIONBIO, &off);
#endif
	bResult = true;
	if (nResult1 == SOCKET_ERROR)
	{
		nResult2 = 0;
		if (this->m_sock != INVALID_SOCKET)
			nResult2 = shutdown(this->m_sock, SHUT_RDWR);
		printf("OnEventSocketClose:%d", nResult2);
		goto _FAILED_;
	}
	return bResult;
}

bool CTCPSocket::OnEventSocketConnet(const char *ip, WORD port)
{
	int nRet;
	CTCPSocket *pThis;
	bool bResult1;
	bool bResult2;
	int cbIpByte[4];
	memset(cbIpByte,0,sizeof(cbIpByte));
	nRet = sscanf(ip, "%d.%d.%d.%d", cbIpByte, &cbIpByte[1], &cbIpByte[2], &cbIpByte[3]);
	if ((cbIpByte[3] | cbIpByte[2] | (unsigned int)(cbIpByte[1] | cbIpByte[0])) > 0xFF || nRet != 4)
	{
		pThis = this;
		bResult1 = OnEventSocketConnetByDomain(ip, port);
	}
	else
	{
		pThis = this;
		bResult1 = OnEventSocketConnetByIP(ip, port);
	}
	if (pThis->server_addr)
	{
		bResult2 = bResult1;
		freeaddrinfo(pThis->server_addr);
		bResult1 = bResult2;
		pThis->server_addr = NULL;
	}
	return bResult1;
}

bool CTCPSocket::OnEventSocketConnetByIP(const char *ip, WORD port)
{
	int ai_family;
	WORD portNS;
	CTCPSocket *pThis;
	const char *pszErrorStr;
	WORD portNS1;
	int nRet;
	int nRet1;
	bool result;
	const char *szIp1;
	struct addrinfo *AddrInfo;
	sockaddr_in6 sin6;
	int cbIpByte[4];
	char szIpV6[240];
	sockaddr_in sin;
	char szPort[16];
	this->addrCriteria.ai_family = 0;
	this->addrCriteria.ai_flags = 0;
	this->addrCriteria.ai_protocol = 0;
	this->addrCriteria.ai_socktype = 0;
	this->addrCriteria.ai_canonname = 0;
	this->addrCriteria.ai_addrlen = 0;
	this->addrCriteria.ai_next = 0;
	this->addrCriteria.ai_addr = 0;
	this->addrCriteria.ai_socktype = SOCK_STREAM;
	this->addrCriteria.ai_protocol = IPPROTO_TCP;
	ZeroMemory(szPort, sizeof(szPort));
	sprintf(szPort, "%u", port);
	if (getaddrinfo("www.foxuc.com", 0, &this->addrCriteria, &AddrInfo))
	{
		printf("OnEventSocketConnetByIP getaddrinfo fail %s", "www.foxuc.com");
		return false;
	}
	if (!OnEventSocketCreate(AddrInfo->ai_family, SOCK_STREAM, 0))
	{
		pszErrorStr = "OnEventSocketConnetByIP OnEventSocketCreate fail";
		goto _FAILED_;
	}
	ai_family = AddrInfo->ai_family;
	if (ai_family != AF_INET6)
	{
		pThis = this;
		if (ai_family != AF_INET)
		{
			printf("getaddrinfo unknow ai_family with %d\n", AddrInfo->ai_family);
			return false;
		}
		ZeroMemory(&sin, sizeof(sin));
		sin.sin_family = AF_INET;
		portNS1 = htons(port);
		sin.sin_port = portNS1;
#ifndef _WIN32
		if (inet_aton(ip, &sin.sin_addr))
#else
		if (inet_pton(AF_INET, ip, &sin.sin_addr))
#endif
		{
			nRet = connect(this->m_sock, (const struct sockaddr *)&sin, sizeof(sin));
			goto _SUCCEEDED_;
		}
		szIp1 = ip;
		pszErrorStr = "inet_aton fail %s";
	_FAILED_:
		printf(pszErrorStr, szIp1);
		return false;
	}
	ZeroMemory(szIpV6, sizeof(szIpV6));
	ZeroMemory(cbIpByte, sizeof(cbIpByte));
	sscanf(ip, "%d.%d.%d.%d", cbIpByte, &cbIpByte[1], &cbIpByte[2], &cbIpByte[3]);
	sprintf(
		szIpV6,
		"0064:ff9b:0000:0000:0000:0000:%02x%02x:%02x%02x",
		cbIpByte[0],
		&cbIpByte[1],
		&cbIpByte[2],
		&cbIpByte[3]);
	ZeroMemory(&sin6, sizeof(sin6));
	sin6.sin6_family = AF_INET6;
	portNS = htons(port);
	sin6.sin6_port = portNS;
	if (inet_pton(AF_INET6, szIpV6, &sin6.sin6_addr) < 0)
	{
		printf("inet_pton fail %s", szIpV6);
		return false;
	}
	pThis = this;
	nRet = connect(this->m_sock, (const struct sockaddr *)&sin6, sizeof(sin6));
_SUCCEEDED_:
	nRet1 = nRet;
	result = true;
	if (nRet1 < 0)
	{
		if (pThis->m_bDetach)
			result = CTCPSocket::DetachTest();
	}
	return result;
}

bool CTCPSocket::OnEventSocketConnetByDomain(const char *domain, WORD port)
{
	int nRet;
	int nRet1;
	bool result;
	char szPort[16];
	this->addrCriteria.ai_family = 0;
	this->addrCriteria.ai_flags = 0;
	this->addrCriteria.ai_protocol = 0;
	this->addrCriteria.ai_socktype = 0;
	this->addrCriteria.ai_canonname = 0;
	this->addrCriteria.ai_addrlen = 0;
	this->addrCriteria.ai_next = 0;
	this->addrCriteria.ai_addr = 0;
	this->addrCriteria.ai_socktype = SOCK_STREAM;
	this->addrCriteria.ai_protocol = IPPROTO_TCP;
	ZeroMemory(szPort, sizeof(szPort));
	sprintf(szPort, "%u", port);
	nRet = getaddrinfo(domain, szPort, &this->addrCriteria, &this->server_addr);
	if (nRet)
	{
		printf("getaddrinfo failed with error: %d\n", nRet);
		return false;
	}
	if (!OnEventSocketCreate(this->server_addr->ai_family, SOCK_STREAM, 0))
	{
		printf("OnEventSocketCreate fail");
		return false;
	}
	nRet1 = connect(this->m_sock, this->server_addr->ai_addr, this->server_addr->ai_addrlen);
	result = true;
	if (nRet1 < 0)
	{
		if (this->m_bDetach)
			result = CTCPSocket::DetachTest();
	}
	return result;
}

bool CTCPSocket::DetachTest()
{
	struct timeval timeout;
	signed int SizeOfSocketError;
	signed int SocketError;
	fd_set WriteFd;

	if (errno != EINPROGRESS)
		goto _FAILED_;
	FD_ZERO(&WriteFd);
	FD_SET(this->m_sock,&WriteFd);
	SocketError = SOCKET_ERROR;
	SizeOfSocketError = sizeof(SocketError);
	timeout.tv_sec = 10;
	timeout.tv_usec = 0;
	if (select(this->m_sock+1, NULL, &WriteFd, NULL, &timeout) <= 0)
		goto _FAILED_;
	getsockopt(this->m_sock, SOL_SOCKET, SO_ERROR, (char*)&SocketError, &SizeOfSocketError);
	if (SocketError)
	{
		printf("OnEventSocketConnet getsockopt error:%d", SocketError);
	_FAILED_:
		printf("OnEventSocketConnet error:%d", errno);
		return false;
	}
	return true;
}

int CTCPSocket::OnEventSocketSelect()
{
	int nRet;
	int result;
	SOCKET sock;
	struct timeval timeout;

	FD_ZERO(&this->fdR);
	FD_SET(this->m_sock, &this->fdR);
	timeout.tv_sec = 0;
	//timeout.tv_usec = 0;
	timeout.tv_usec = 100;
	nRet = select(this->m_sock+1, &this->fdR, NULL, NULL, &timeout);
	result = SOCKET_ERROR;
	if (nRet != SOCKET_ERROR)
	{
		if (nRet)
		{
			sock = this->m_sock;
			if (sock != INVALID_SOCKET)
				result = -3 - ((FD_ISSET(sock, &this->fdR) < 1) - 1);//-3是返回值偏移基值
		}
		else
		{
			result = 0;
		}
	}
	return result;
}

bool CTCPSocket::OnEventSocketSend(const char *buf, int len, int flags)
{
	SOCKET sock;
	int nAllSentDataSize;
	int nNeedSentDataSize;
	int nAllSentDataSize_BeforeCurSend;
	int CurSentDataSize;

	bool bResult;

	bResult = false;
	
	sock = this->m_sock;
	nAllSentDataSize = 0;
	if (sock != INVALID_SOCKET)
	{
		nNeedSentDataSize = len;
		if (len > 0)
		{
			while (TRUE)
			{
				nAllSentDataSize_BeforeCurSend = nAllSentDataSize;
				CurSentDataSize = send(sock, &buf[nAllSentDataSize], nNeedSentDataSize - nAllSentDataSize, flags);
				if (CurSentDataSize < 1)
					break;
				nAllSentDataSize = CurSentDataSize + nAllSentDataSize_BeforeCurSend;
				nNeedSentDataSize = len;
				if (CurSentDataSize + nAllSentDataSize_BeforeCurSend >= len)
					goto _RESULT_;
				sock = this->m_sock;
			}
			bResult = false;
		}
		else
		{
		_RESULT_:
			bResult = nAllSentDataSize == nNeedSentDataSize;
		}
	}
	return bResult;
}

int CTCPSocket::OnEventSocketRecv(char *buf, int len, int flags)
{
	SOCKET sock;
	int result;

	sock = this->m_sock;
	if (sock == INVALID_SOCKET)
		result = SOCKET_ERROR;
	else
		result = recv(sock, buf, len, flags);
	return result;
}

int CTCPSocket::OnEventSocketClose()
{
	int nResult;

	nResult = 0;
	if (this->m_sock != INVALID_SOCKET)
		nResult = shutdown(this->m_sock, SHUT_RDWR);
	printf("OnEventSocketClose:%d", nResult);
	return nResult;
}