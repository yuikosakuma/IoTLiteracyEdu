#ifndef SOURCE_H
#define SOURCE_H

#include "main.h"
#include "Arduino.h"
#include "XBee.h"
#include <Servo.h>

//variables
extern String MOTENAME; //recommended to be between 1 ~ 10
extern int MOTEID; //should be from 1 ~ 20
extern uint32_t DEST_ADDR_LSB; // LSB of COODINATOR

//variables
extern int oldButtonState;
extern int SWITCH_ARRAY_PIN[5];    //switch
extern int switch_values[5];
extern unsigned long serialPreviousMillis;    //loop serial print
extern unsigned long receiveLedPreviousMillis;    //Receive LED
extern unsigned long clickLedPreviousMillis;
extern unsigned long servoPreviousMillis;

//==========class
class Mine {
  public:
    //=== members ===
    //XBee
    XBee myxbee;
    //receive
    XBeeResponse myresponse;
    ZBRxResponse myrx; // create reusable response objects for responses we expect to handle
    //for send
    uint32_t mytxAddrHSB;
    uint32_t mytxAddrLSB;
    XBeeAddress64 mytxAddr64;
    ZBTxRequest mytxRequest;

    //=== methods ===
    Mine();
    void init();
    //xbee
    void sendXBeeData(String payload);
    void receiveXBeeData(Servo servo);
};

//for test
class MyClass {
  public:
    void myPrint();
};

#endif //ifndef SOURCE_H
