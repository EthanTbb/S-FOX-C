#pragma once

#include "Define.h"

#ifndef ZeroMemory
#define ZeroMemory(Destination,Length) memset((Destination),0,(Length))
#endif

#ifndef _WIN32
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <fcntl.h>

#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <string.h>
#include <stdio.h>
#include "errno.h"
#include <net/if.h>
typedef int				SOCKET;


//#pragma region define win32 const variable in linux
#define INVALID_SOCKET	-1
#define SOCKET_ERROR	-1
//#pragma endregion
#else
#include <winsock2.h>
#include <ws2tcpip.h>
#endif

class CTCPSocket
{
	bool m_bDetach;
	SOCKET m_sock;
	fd_set fdR;
	addrinfo *server_addr;
	addrinfo addrCriteria;
public:
	CTCPSocket(SOCKET sock = INVALID_SOCKET);
	virtual ~CTCPSocket();
public:
	bool OnEventSocketCreate(int af = AF_INET, int type = SOCK_STREAM, int protocol=0);
	bool OnEventSocketConnet(const char *ip, WORD port);
	bool OnEventSocketConnetByIP(const char *ip, WORD port);
	bool OnEventSocketConnetByDomain(const char *domain, WORD port);
	bool DetachTest();
	int OnEventSocketSelect();
	bool OnEventSocketSend(const char *buf, int len, int flags);
	int OnEventSocketRecv(char *buf, int len, int flags);
	int OnEventSocketClose();
};

