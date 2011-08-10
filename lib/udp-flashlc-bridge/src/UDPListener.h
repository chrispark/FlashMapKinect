/** Author: Georg Kaindl **/

#include <stdint.h>


typedef void (*UDPListenerPacketCallback)(const uint8_t*, uint32_t, const char*, uint16_t);

typedef enum UDPListenerError_t {
   UDPListenerSuccess,
   UDPListenerErrorSocketCreationError,
   UDPListenerErrorSocketBindError,
   UDPListenerErrorSocknameError
} UDPListenerError_t;

typedef struct UDPListener {
   int                socket;
   uint16_t           port;
   UDPListenerError_t lastError;
   
   int                isWaiting;
   uint8_t*           recvBuf;
   
   UDPListenerPacketCallback  packetCallback;
} UDPListener;

UDPListener* UDPListenerCreate();
UDPListener* UDPListenerCreateWithPort(uint16_t port);
void UDPListenerRelease(UDPListener* udpListener);

int UDPListenerIsValid(UDPListener* udpListener);
int UDPListenerIsWaiting(UDPListener* udpListener);

void UDPListenerSetPacketReceiptCallback(UDPListener* udpListener,
                                         UDPListenerPacketCallback packetCallback);

void UDPListenerWaitForPacket(UDPListener* udpListener);

const char* UDPListenerStringForError(UDPListenerError_t error);
