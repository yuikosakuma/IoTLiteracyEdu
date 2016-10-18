/*
 * source.h
 * Author: Tada Matz
 * Comment: MyXBee class. simple XBee handler
 */

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
extern boolean receiveServoDataFlag;
extern unsigned long serialPreviousMillis;    //loop serial print
extern unsigned long receiveLedPreviousMillis;    //Receive LED
extern unsigned long clickLedPreviousMillis;
extern unsigned long servoPreviousMillis;

//==========class
class MyXBee {
  public:
    //=== members ===
    //XBee
    XBee xbee;
    //receive
    XBeeResponse response;
    ZBRxResponse rx; // create reusable response objects for responses we expect to handle
    //for send
    uint32_t txAddrHSB;
    uint32_t txAddrLSB;
    XBeeAddress64 txAddr64;
    ZBTxRequest txRequest;

    //=== methods ===
    MyXBee();
    void init();
    //xbee
    void sendXBeeData(String payload);
    void receiveXBeeData(Servo servo);
};

#endif //ifndef SOURCE_H
