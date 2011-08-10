/** Author: Georg Kaindl **/

#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>

#if defined(WINDOWS)
#include <winsock.h>
typedef int socklen_t;
#else
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#endif

#include "UDPListener.h"

#define RECVBUF_LEN  (65535)

#if defined(WINDOWS)
typedef char SoFlag_t;
#else
typedef int SoFlag_t;
#endif

UDPListener* UDPListenerCreate()
{
   return UDPListenerCreateWithPort(0);
}

UDPListener* UDPListenerCreateWithPort(uint16_t port)
{
   UDPListener* udpListener = (UDPListener*)malloc(sizeof(UDPListener));
   
   if (NULL != udpListener) {
      SoFlag_t soFlag;
      socklen_t addrLen;
      struct sockaddr_in addr;
      
      memset(udpListener, 0, sizeof(UDPListener));
            
      udpListener->socket = socket(AF_INET, SOCK_DGRAM, 0);
      if (udpListener->socket < 0) {
         udpListener->lastError = UDPListenerErrorSocketCreationError;
         goto returnNow;
      }
      
      memset(&addr, 0, sizeof(addr));
      addr.sin_family = AF_INET;
      addr.sin_port = htons(port);
      addr.sin_addr.s_addr = INADDR_ANY;
      
      if (bind(udpListener->socket,
               (struct sockaddr*)&addr,
               sizeof(struct sockaddr)) < 0) {
         udpListener->lastError = UDPListenerErrorSocketBindError;
         goto returnNow;
      }
      
      // determine the port we're bound to, in case we wanted it assigned by the OS
      addrLen = (socklen_t)sizeof(struct sockaddr);
      if (0 > getsockname(udpListener->socket, (struct sockaddr*)&addr, &addrLen)) {
         udpListener->lastError = UDPListenerErrorSocknameError;
         udpListener->port = 0;
         goto returnNow;
      }
      
      udpListener->port = ntohs(addr.sin_port);
      
      // try setting the socket up to reuse the address immediately
      soFlag = 1;
      (void)setsockopt(udpListener->socket,
                       SOL_SOCKET,
                       SO_REUSEADDR,
                       &soFlag,
   						  (socklen_t)sizeof(SoFlag_t));
      
      udpListener->lastError = UDPListenerSuccess;
   }

returnNow:

   return udpListener;
}

void UDPListenerRelease(UDPListener* udpListener)
{
   if (NULL != udpListener) {
      (void)close(udpListener->port);
      
      if (NULL != udpListener->recvBuf)
         free(udpListener->recvBuf);
      
      free(udpListener);
   }
}

int UDPListenerIsValid(UDPListener* udpListener)
{
   return (NULL != udpListener && UDPListenerSuccess == udpListener->lastError);
}

int UDPListenerIsWaiting(UDPListener* udpListener)
{
   return (NULL != udpListener && udpListener->isWaiting);
}

void UDPListenerSetPacketReceiptCallback(UDPListener* udpListener,
                                         UDPListenerPacketCallback packetCallback)
{
   if (NULL != udpListener)
      udpListener->packetCallback = packetCallback;
}

void UDPListenerWaitForPacket(UDPListener* udpListener)
{
   if (NULL != udpListener) {
      if (NULL == udpListener->recvBuf)
         udpListener->recvBuf = (uint8_t*)malloc(RECVBUF_LEN);
      
      if (NULL != udpListener->recvBuf) {
         struct sockaddr_in clientAddr;
         socklen_t addrLen;
         socklen_t bytesReceived;
         
         addrLen = (socklen_t)sizeof(struct sockaddr);
         
         bytesReceived = recvfrom(udpListener->socket,
#if defined(WINDOWS)
                                  (char*)udpListener->recvBuf,
#else
                                  udpListener->recvBuf,
#endif
                                  RECVBUF_LEN,
                                  0,
                                  (struct sockaddr*)&clientAddr,
                                  &addrLen);
         
         if (bytesReceived > 0 && NULL != udpListener->packetCallback) {
            udpListener->packetCallback(
               udpListener->recvBuf,
               bytesReceived,
               inet_ntoa(clientAddr.sin_addr),
               ntohs(clientAddr.sin_port)
            );
         }
      }
   }
}

const char* UDPListenerStringForError(UDPListenerError_t error)
{
   char* str = NULL;
   
   switch (error) {
      case UDPListenerSuccess:
         str = "No error.";
         break;
      case UDPListenerErrorSocketCreationError:
         str = "Socket creation failed.";
         break;
      case UDPListenerErrorSocketBindError:
         str = "Socket binding failed.";
         break;
      case UDPListenerErrorSocknameError:
         str = "getsockname() failed.";
         break;
      default:
         str = "Unknown error.";
         break;
   }
   
   return str;
}