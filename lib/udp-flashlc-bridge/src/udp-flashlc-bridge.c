/** Author: Georg Kaindl **/

#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdint.h>
#include <string.h>

#include "UDPListener.h"
#include "TFFlashLCSHMEM.h"

#define  DEFAULT_UDP_PORT        (3333)
#define  DEFAULT_LC_CONN_NAME    ((char*)"_OscDataStream")
#define  DEFAULT_LC_METH_NAME    ((char*)"receiveOscData")

typedef enum logLevel_t {
   LogLevelNone      = 0,
   LogLevelErrors    = 1,
   LogLevelInfo      = 2,
   LogLevelVerbose   = 3
} logLevel_t;

static logLevel_t logLevel = LogLevelInfo;
static TFLCSLocalConnection_t* lcConnection;

void HandleUDPPacketReceived(const uint8_t* packet,
                             uint32_t packetLength,
                             const char* sourceAddress,
                             uint16_t sourcePort);

char* myStrdup(const char* src)
{
   char* rv = (char*)malloc(strlen(src)+1);
   strncpy(rv, src, strlen(src)+1);
   return rv;
}

void usageAndDie(const char* pName)
{
   fprintf(stderr,
      "Usage: %s [-p <udp listening port>] [-l <loglevel>] [-c LC name] [-m LC method name]\n", pName
   );
   
   exit(-1);
}

int main(int argc, char** argv)
{
   int c;
   uint16_t udpPort = DEFAULT_UDP_PORT;
   char* lcConnName = myStrdup(DEFAULT_LC_CONN_NAME);
   char* lcMethName = myStrdup(DEFAULT_LC_METH_NAME);
   
   UDPListener* udpListener;
   
   opterr = 0;
   
   while (-1 != (c = getopt(argc, argv, "p:l:c:m:h"))) {
      switch (c) {
         case 'p': {
               int p = atoi(optarg);
               if (p < 0 || p > 65535)
                  usageAndDie(argv[0]);
               udpPort = p;
               break;
            }
         case 'l':
            logLevel = atoi(optarg);
            break;
         case 'c':
            lcConnName = myStrdup(optarg);
            break;
         case 'm':
            lcMethName = myStrdup(optarg);
            break;
         case 'h':
         default:
            usageAndDie(argv[0]);
            break;
      }
   }
   
   if (optind < argc)
      usageAndDie(argv[0]);
   
   if (logLevel >= LogLevelVerbose) {
      printf(
         "UDP listening port: %d\n"
         "Log Level: %d\n",
         udpPort, logLevel
      );
   }
   
#if defined(WINDOWS)
   WSADATA wsaData;
   WSAStartup(MAKEWORD(2, 0), &wsaData);
#endif
   
   // set up the UDP listener
   udpListener = UDPListenerCreateWithPort(udpPort);
   
   if (NULL == udpListener) {
      if (logLevel >= LogLevelErrors)
         fprintf(stderr, "UDPListener creation: out of memory.\n");
      exit(-1);
   }
   
   if (!UDPListenerIsValid(udpListener)) {
      if (logLevel >= LogLevelErrors)
         fprintf(stderr, "UDPListener: %s\n",
            UDPListenerStringForError(udpListener->lastError));
      exit(-1);
   }
   
   if (logLevel >= LogLevelInfo) {
      printf("Listening for UDP at port %d...\n", udpListener->port);
   }
   
   UDPListenerSetPacketReceiptCallback(udpListener, &HandleUDPPacketReceived);
   
   // set up the flash localconnection sender
   lcConnection = TFLCSConnect(lcConnName,
                               lcMethName,
                               NULL,
                               NULL);
   
   if (logLevel >= LogLevelInfo) {
      printf("Serving to Flash via LocalConnection at %s:%s\n", lcConnName, lcMethName);
   }
   
   free(lcConnName);
   free(lcMethName);
   
   while(1)
      UDPListenerWaitForPacket(udpListener);
   
   return 1;
}

void HandleUDPPacketReceived(const uint8_t* packet,
                             uint32_t packetLength,
                             const char* sourceAddress,
                             uint16_t sourcePort)
{
   if (logLevel >= LogLevelVerbose) {
      printf("Received %d bytes from %s:%d...\n", packetLength, sourceAddress, sourcePort);
   }
   
   // Flash 10 seems not to be able to keep up with very fast rates sometimes?
   // at my trivial Flash test-app sometimes throws an exception (but does not choke on it)
   // when an app like MSARemote sends 120+ packets per second.
   // below 100 packets/second seem to work fine in any case, though.
   // maybe it's good enough to catch the exception in Flash and just drop it?
   /*static int t = 0;
   if (t++ % 3)
      return;*/
      
   if (TFLCSConnectionHasConnectedClient(lcConnection))
      TFLCSSendByteArray(lcConnection, (char*)packet, packetLength);
}