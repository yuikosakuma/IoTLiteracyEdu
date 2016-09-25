/**
 * based on skecth_160416RLRNCFFPPSSTRSRSFSPTIABuggy
  Catch Packet
  LED On DEFIND Second
  Send Packet

  I hope that this program can visualize the route of packet of XBee
*/

#include <XBee.h>

#define NUM_SENSOR 25

#define xbeeReceiveLedPin A5
#define xbeePowerLedPin A4
#define powerSupplyPin A3
#define ledOnInterval 1000

//for UNO, use mySerial(2,3) as like Serial1 in Fio v3
#include <SoftwareSerial.h>
SoftwareSerial mySerial(2, 3);

union fourbyte {
  uint32_t dword;
  uint16_t word[2];
  uint8_t byte[4];
};

unsigned long serialPreviousMillis = 0;
unsigned long ledPreviousMillis = 0;

//for sleep
unsigned long xbeeOnInterval = 10000;
unsigned long xbeePastMillis = 0;
int powerSupplyFlag = 1;
int powerSupplyIntervalFlag = 0;

//for periodic transmission
unsigned long periodicTxPastMillis = millis();
unsigned long periodicTxInterval = 10L * 1000L;
int periodicTxNumber = 5; //number of transmission. After this, back to waiting mode
int periodicTxCounter = 0; //counter of transmission
int periodicTxFlag = 0;
int periodicTxAllHopInt = 0;
XBeeAddress64 periodicTxAddr64;
ZBTxRequest periodicTxZbTx;
uint8_t periodicTxSendPayload[128];
union fourbyte periodicTxSendPacketLSB;

XBee xbee = XBee();
XBeeResponse response = XBeeResponse();
ZBRxResponse rx = ZBRxResponse(); // create reusable response objects for responses we expect to handle

//time synchro
#include <TimeMatz.h> //This header can is based on Time library modified by Matz to get detailed resolution of time. 
//#include <Time.h>
#define TRIGGER_SET_HEADER  'T'   // Header for setting trigger appointed time
#define REQUEST_SYNCHRO_HEADER 'S' // Header for request
#define RESPONCE_SYNCHRO_HEADER 'R' // Header for responcing
#define TRIGGER_SYNCHRO_HEADER 'Q' //Header for triggering synchro process at end node
unsigned long synchroSendMillis; //variable to store the data of synchro send millis
boolean wakeUpTogetherFlag[NUM_SENSOR] = {false};
unsigned long appointedTime[NUM_SENSOR] = { -1}; //In order to set it maximum value
boolean sleepTimeFlag = false;
unsigned long sleepTime = -1;

void setup() {
  Serial.begin(9600);
  Serial1.begin(9600); //for fio
  xbee.begin(Serial1); //for fio
  //  mySerial.begin(9600); //for UNO
  //  xbee.setSerial(mySerial); //for UNO


  serialPreviousMillis = millis();

  pinMode(xbeeReceiveLedPin, OUTPUT);
  digitalWrite(xbeeReceiveLedPin, HIGH);
  pinMode(xbeePowerLedPin, OUTPUT);
  digitalWrite(xbeePowerLedPin, HIGH);
  pinMode(powerSupplyPin, OUTPUT);
  digitalWrite(powerSupplyPin, HIGH);

  Serial.println("---------------------------------------------");
  Serial.println("--------- I am RELAY SERVER, RESET ----------");
  Serial.println("---------------------------------------------");
}

// continuously reads packets, looking for ZB Receive or Modem Status
void loop() {
  //  Serial.println("--- loop start --- ");

  unsigned long currentMillis = millis();

  //serial console display
  if (millis() - serialPreviousMillis > 100) {
    serialPreviousMillis = millis();
    //    if (powerSupplyIntervalFlag) { //interval ON
    //      if (powerSupplyFlag) { //on
    //        Serial.println("XBee ON");
    //      }
    //      else { //off
    //        Serial.println("XBee OFF");
    //      }
    //    }

    //display clock
    Serial.print("Relay Server: ");
    if (decisecond() == 0) Serial.print("--- ");
    Serial.println(digitalClockDisplay(now()));
    //Serial.println(now());
  }

  //led on DEFINED milli seconds
  if (millis() - ledPreviousMillis >= ledOnInterval) {
    //    Serial.println(currentMillis - ledPreviousMillis);
    //    ledPreviousMillis = currentMillis;
    digitalWrite(xbeeReceiveLedPin, LOW);
  }

  //XBee power supply on off
  //  if (powerSupplyIntervalFlag) { //interval ON
  //    if (millis() - xbeePastMillis > xbeeOnInterval) {
  //      xbeePastMillis = millis();
  //      powerSupplyFlag = 1 - powerSupplyFlag;
  //      if (powerSupplyFlag) { //on
  //        digitalWrite(powerSupplyPin, HIGH);
  //        digitalWrite(xbeePowerLedPin, HIGH);
  //      }
  //      else { //off
  //        digitalWrite(powerSupplyPin, LOW);
  //        digitalWrite(xbeePowerLedPin, LOW);
  //      }
  //    }
  //  }
  //  else { //interval OFF, always XBee on
  //    digitalWrite(powerSupplyPin, HIGH);
  //    digitalWrite(xbeePowerLedPin, HIGH);
  //  }

  //periodic transmission
  if (periodicTxFlag) {
    if (millis() - periodicTxPastMillis > periodicTxInterval) {
      periodicTxPastMillis = millis();
      periodicTxCounter++;
      Serial.println(F("Send periodic transmission ZbTx"));

      uint8_t tempSendPacket[3 + periodicTxAllHopInt * 4 + 1 + 4];
      for (int i = 0; i < 3 + periodicTxAllHopInt * 4 + 1 + 4; i++) {
        tempSendPacket[i] = periodicTxSendPayload[i];
      }
      //      int ar = analogRead(A11);
      int ar = 0;
      char arChar[4];
      sprintf(arChar, "%04d", ar);
      for (int i = 0; i < 4; i++) {
        periodicTxSendPayload[2 + periodicTxAllHopInt * 4 + 1 + 1 + i] = arChar[i];
      }

      periodicTxAddr64 = XBeeAddress64(0x0013a200, periodicTxSendPacketLSB.dword);
      periodicTxZbTx = ZBTxRequest(periodicTxAddr64, tempSendPacket, sizeof(tempSendPacket));
      xbee.send(periodicTxZbTx);

      //put on receive LED
      digitalWrite(xbeeReceiveLedPin, HIGH);
      ledPreviousMillis = millis();

      if (periodicTxCounter > periodicTxNumber) {
        Serial.println(F("Periodic transmission END"));
        periodicTxFlag = 0;
      }
    }
  }

  //xbee power supply
  //wake up together at appointed time
  if (sleepTimeFlag && (now() > sleepTime)) {
    sleepTimeFlag = false;
    sleepTime = -1;
    boolean tempFlag = false;
    for (int i = NUM_SENSOR; i >= 0; i++) {
      if (wakeUpTogetherFlag[i]) {
        tempFlag = true;
        break;
      }
    }
    if (tempFlag) {
      Serial.println(F("__________________________________________"));
      Serial.println(F("-----------XBeePowerSupplyOFF!!-----------"));
      Serial.println(F("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"));
      //xbee power supply
      digitalWrite(powerSupplyPin, LOW);
      digitalWrite(xbeePowerLedPin, LOW);
    } else Serial.println(F("wake up time not set"));
  }

  //wake up together at appointed time
  for (int i = 0; i < NUM_SENSOR; i++) {
    if (wakeUpTogetherFlag[i] && (now() > appointedTime[i])) {
      wakeUpTogetherFlag[i] = false;
      appointedTime[i] = 0;
      sleepTimeFlag = false;
      Serial.println(F("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="));
      Serial.println(F("-=-=-=-=-=-=-WakeUpTogether!!=-=-=-=-=-=-="));
      Serial.println(F("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="));

      //xbee power supply
      digitalWrite(powerSupplyPin, HIGH);
      digitalWrite(xbeePowerLedPin, HIGH);
      break;
    }
  }

  //========= XBEE Receiving =======
  xbee.readPacket();

  if (xbee.getResponse().isAvailable()) {
    // got something

    if (xbee.getResponse().getApiId() == ZB_RX_RESPONSE) {
      // got a zb rx packet
      Serial.print("got zb rx packet >>> ");

      //put on receive LED
      digitalWrite(xbeeReceiveLedPin, HIGH);
      ledPreviousMillis = millis();

      // now fill our zb rx class
      xbee.getResponse().getZBRxResponse(rx);

      //remote source address
      Serial.print(rx.getRemoteAddress64().getMsb(), HEX);//data type of return value is uint32_t
      Serial.print(",");
      Serial.print(rx.getRemoteAddress64().getLsb(), HEX);//data type of return value is uint32_t
      Serial.print(",");

      //data(payload) length
      Serial.print(rx.getDataLength());
      Serial.print(",");
      //      Serial.println("");

      //data(payload)
      uint8_t receivePayload [rx.getDataLength()];
      for (int i = 0; i < rx.getDataLength(); i++) receivePayload[i] = rx.getData(i);
      for (int i = 0; i < rx.getDataLength(); i++) Serial.print((char)receivePayload[i]);
      Serial.println("");

      uint8_t payloadType = receivePayload[0];

      //judge whether the packet is hopping packet or not
      if (payloadType == 0xF0) { //hopping packet!!
        uint8_t remainHop = receivePayload[1];
        Serial.print(" remainHop: ");
        Serial.print(remainHop);
        if (0 <= remainHop && remainHop <= 48) { //no more hop needed
          Serial.println(" >>> no more hop needed");
        }
        else { //packet should be hopped 1 or more times
          Serial.print(" >>> hop packet !!!");

          uint8_t allHop = receivePayload[2];
          union fourbyte sendPacketLSB;

          //calc next destination address by receivePayload
          sendPacketLSB.byte[0] = receivePayload[6 + (allHop - remainHop) * 4];
          sendPacketLSB.byte[1] = receivePayload[5 + (allHop - remainHop) * 4];
          sendPacketLSB.byte[2] = receivePayload[4 + (allHop - remainHop) * 4];
          sendPacketLSB.byte[3] = receivePayload[3 + (allHop - remainHop) * 4];

          Serial.print(sendPacketLSB.dword, HEX);
          //make send payload
          receivePayload[1] = remainHop - 1; //decrease counter
          Serial.print(" [1]:");
          Serial.print((int)receivePayload[1]);
          Serial.print(" ");

          XBeeAddress64 addr64 = XBeeAddress64(0x0013a200, sendPacketLSB.dword);
          ZBTxRequest zbTx = ZBTxRequest(addr64, receivePayload, sizeof(receivePayload));
          xbee.send(zbTx);
        }
      }
      else if (payloadType == 0xF1) { //sleep packet
        uint8_t remainHop = receivePayload[1];
        if (0 <= remainHop && remainHop <= 48) { //no more hop needed
          Serial.print(" >>> no more sleep needed");
        }
        else { //packet should be hopped 1 or more times
          Serial.print(" >>> sleep packet !!!");

          uint8_t allHop = receivePayload[2];
          union fourbyte sendPacketLSB;

          //calc next destination address by receivePayload
          sendPacketLSB.byte[0] = receivePayload[6 + (allHop - remainHop) * 4];
          sendPacketLSB.byte[1] = receivePayload[5 + (allHop - remainHop) * 4];
          sendPacketLSB.byte[2] = receivePayload[4 + (allHop - remainHop) * 4];
          sendPacketLSB.byte[3] = receivePayload[3 + (allHop - remainHop) * 4];

          Serial.print(sendPacketLSB.dword, HEX);
          //make send payload
          receivePayload[1] = remainHop - 1; //decrease counter
          Serial.print(" [1]:");
          Serial.print((int)receivePayload[1]);
          Serial.print(" ");

          XBeeAddress64 addr64 = XBeeAddress64(0x0013a200, sendPacketLSB.dword);
          ZBTxRequest zbTx = ZBTxRequest(addr64, receivePayload, sizeof(receivePayload));
          xbee.send(zbTx);
        }

        //xbee power supply
        boolean powerOffFlag = false;
        for (int i = 0; i < NUM_SENSOR; i++) {
          if (wakeUpTogetherFlag[i]) {
            powerOffFlag = true;
            break;
          }
        }
        if (powerOffFlag) {
          delay(100);
          Serial.print(F(" xbeePowerSupply OFF "));
          digitalWrite(powerSupplyPin, LOW);
          digitalWrite(xbeePowerLedPin, LOW);
        } else {
          Serial.print(F("No time set!!!"));
        }


        //        //XBee power supply interval on off
        //        powerSupplyIntervalFlag = 1 - powerSupplyIntervalFlag;
        //        if (powerSupplyIntervalFlag) { //supply interval on
        //          //          Serial.print("\n(int)remainHop: ");
        //          //          Serial.println((int)remainHop);
        //          delay((remainHop - 48 + 1) * 200); //adjust sleeping timing
        //        }
      }
      else if (payloadType == 0xF2) { //wake up fladding packet
        uint8_t remainHop = receivePayload[1];
        Serial.print(" remainHop: ");
        Serial.print(remainHop);
        if (0 <= remainHop && remainHop <= 48) { //no more hop needed
          Serial.print(" >>> no more wakeup needed");
        }
        else { //packet should be hopped 1 or more times
          Serial.print(" >>> wakeup packet !!!");

          //make send payload
          receivePayload[1] = remainHop - 1; //decrease counter
          Serial.print(" [1]:");
          Serial.print((int)receivePayload[1]);
          Serial.print(" ");

          XBeeAddress64 addr64 = XBeeAddress64(0x00000000, 0x0000FFFF); //braodcasting??? fladding
          ZBTxRequest zbTx = ZBTxRequest(addr64, receivePayload, sizeof(receivePayload));
          xbee.send(zbTx);
        }

        //XBee power supply interval off
        powerSupplyIntervalFlag = 0;
      }
      else if (payloadType == 0xF3) { //periodic transmission count (like Route Notification Packet)
        uint8_t remainHop = receivePayload[1];
        Serial.print(" remainHop: ");
        Serial.print(remainHop);
        if (0 <= remainHop && remainHop <= 48) { //no more hop needed. this means this node is end of the packet
          Serial.println(F(" >>> no more hop needed "));

          uint8_t allHop = receivePayload[2];
          periodicTxAllHopInt = allHop - 48;
          Serial.print(F("periodicTxAllHopInt: "));
          Serial.println(periodicTxAllHopInt);

          periodicTxSendPayload[3 + periodicTxAllHopInt * 4 + 1 + 4]; //0xF3 + allHop + hopcount + routeInfo + "," + vbat(4 note)

          periodicTxFlag = 1; //start periodic transmission
          periodicTxCounter = 0; //initialize priodic transmission counter

          periodicTxNumber = 5;
          periodicTxInterval = 5L * 1000L;
          periodicTxNumber = receivePayload[2 + periodicTxAllHopInt * 4 + 1];
          Serial.print(F("periodicTxNumber: "));
          Serial.println(periodicTxNumber);
          periodicTxInterval = receivePayload[2 + periodicTxAllHopInt * 4 + 2] * 256;
          periodicTxInterval += receivePayload[2 + periodicTxAllHopInt * 4 + 3];
          periodicTxInterval *= 1000L;
          Serial.print(F("periodicTxInterval: "));
          Serial.println(periodicTxInterval);

          periodicTxSendPayload[0] = 0xf0;
          periodicTxSendPayload[1] = periodicTxAllHopInt + 48 - 1;
          periodicTxSendPayload[2] = periodicTxAllHopInt + 48;

          for (int j = 0; j < periodicTxAllHopInt; j++) { // receivePayload: addrA, addrB, addrC ===> sendPayload: addrC, addrB, addrA
            for (int i = 0; i < 4; i++) {
              periodicTxSendPayload[3 + i + j * 4] = receivePayload[3 + i + (periodicTxAllHopInt - 1 - j) * 4];
            }
          }

          periodicTxSendPayload[2 + periodicTxAllHopInt * 4 + 1 + 0] = ',';
          periodicTxSendPayload[2 + periodicTxAllHopInt * 4 + 1 + 1] = 'T';
          periodicTxSendPayload[2 + periodicTxAllHopInt * 4 + 1 + 2] = 'E';
          periodicTxSendPayload[2 + periodicTxAllHopInt * 4 + 1 + 3] = 'S';
          periodicTxSendPayload[2 + periodicTxAllHopInt * 4 + 1 + 4] = 'T';

          //calc next destination address by receivePayload
          periodicTxSendPacketLSB.byte[0] = periodicTxSendPayload[2 + 4 + 4];
          periodicTxSendPacketLSB.byte[1] = periodicTxSendPayload[2 + 4 + 3];
          periodicTxSendPacketLSB.byte[2] = periodicTxSendPayload[2 + 4 + 2];
          periodicTxSendPacketLSB.byte[3] = periodicTxSendPayload[2 + 4 + 1];

          Serial.print(F("periodicTxSendPacketLSB.dword,HEX: "));
          Serial.println(periodicTxSendPacketLSB.dword, HEX);
          Serial.print(F("periodicTxSendPayload,HEX: "));
          for (int i = 0; i < 3 + periodicTxAllHopInt * 4 + 1 + 4; i++) {
            Serial.print(periodicTxSendPayload[i], HEX);
            Serial.print(F(" "));
          }
          Serial.println("");
          Serial.print(F("periodicTxSendPayload char: "));
          for (int i = 0; i < 3 + periodicTxAllHopInt * 4 + 1 + 4; i++) {
            Serial.print((char)periodicTxSendPayload[i]);
            Serial.print(F(" "));
          }
          Serial.println("");

          for (int i = 0; i < 3 + periodicTxAllHopInt * 4 + 1 + 4; i++) {
            Serial.print(periodicTxSendPayload[i], HEX);
          }

          //          periodicTxAddr64 = XBeeAddress64(0x0013a200, sendPacketLSB.dword);
          //          periodicTxZbTx = ZBTxRequest(periodicTxAddr64, sendPayload, sizeof(sendPayload));
          //          xbee.send(periodicTxZbTx);
        }
        else { //packet should be hopped 1 or more times
          Serial.print(" >>> hop packet !!!");

          uint8_t allHop = receivePayload[2];
          union fourbyte sendPacketLSB;

          //calc next destination address by receivePayload
          sendPacketLSB.byte[0] = receivePayload[6 + (allHop - remainHop) * 4];
          sendPacketLSB.byte[1] = receivePayload[5 + (allHop - remainHop) * 4];
          sendPacketLSB.byte[2] = receivePayload[4 + (allHop - remainHop) * 4];
          sendPacketLSB.byte[3] = receivePayload[3 + (allHop - remainHop) * 4];

          Serial.print(sendPacketLSB.dword, HEX);
          //make send payload
          receivePayload[1] = remainHop - 1; //decrease counter
          Serial.print(" [1] : ");
          Serial.print((int)receivePayload[1]);
          Serial.print(" ");

          XBeeAddress64 addr64 = XBeeAddress64(0x0013a200, sendPacketLSB.dword);
          ZBTxRequest zbTx = ZBTxRequest(addr64, receivePayload, sizeof(receivePayload));
          xbee.send(zbTx);
        }
      }
      else if (payloadType == 0xF4) { //time synchroniztion packet
        //responce synchro
        unsigned long synchroReceiveMillis;
        if (receivePayload[2 + (receivePayload[2] - 48) * 4 + 1] ==  RESPONCE_SYNCHRO_HEADER) synchroReceiveMillis = now();

        uint8_t remainHop = receivePayload[1];
        Serial.print(" remainHop: ");
        Serial.print((char)remainHop);
        if (0 <= remainHop && remainHop <= 48) { //no more hop needed
          Serial.println(F(" >>> no more hop needed"));
          if (receivePayload[2 + (receivePayload[2] - 48) * 4 + 1] ==  TRIGGER_SYNCHRO_HEADER) { //trigger synchro process on end node
            Serial.println(F("synchro process triggered!!"));

            //make return 'S' packet
            uint8_t allHop = receivePayload[2];
            uint8_t sendPayload[3 + (allHop - 48) * 4 + 1 + 1 + 4]; //0xF4 + hopcount + allHop + routeInfo + header + ',' + batteryLevel(4digit)

            sendPayload[0] = 0xf4; //time synchro packet
            sendPayload[1] = allHop - 2;
            sendPayload[2] = allHop;

            for (int j = 0; j < allHop - 48; j++) { // receivePayload: addrA, addrB, addrC ===> sendPayload: addrC, addrB, addrA
              for (int i = 0; i < 4; i++) {
                sendPayload[3 + i + j * 4] = receivePayload[3 + i + (allHop - 48 - 1 - j) * 4];
              }
            }

            //calc next destination address by receivePayload
            union fourbyte sendPacketLSB;
            sendPacketLSB.byte[0] = sendPayload[2 + 4 + 4];
            sendPacketLSB.byte[1] = sendPayload[2 + 4 + 3];
            sendPacketLSB.byte[2] = sendPayload[2 + 4 + 2];
            sendPacketLSB.byte[3] = sendPayload[2 + 4 + 1];

            sendPayload[2 + (allHop - 48) * 4 + 1] = REQUEST_SYNCHRO_HEADER;

            sendPayload[2 + (allHop - 48) * 4 + 1 + 1] = ',';

            //battery information is in 'S' packet
            int ar = analogRead(A11); //for fio analogRead(A11) corresponds to battely level / 2
            char arChar[4];
            sprintf(arChar, "%04d", ar);
            for (int i = 0; i < 4; i++) {
              sendPayload[2 + (allHop - 48) * 4 + 1 + 1 + (i + 1)] = arChar[i];
            }

            synchroSendMillis = now(); //this is used to adjust time

            XBeeAddress64 addr64 = XBeeAddress64(0x0013A200, sendPacketLSB.dword);
            ZBTxRequest zbTx = ZBTxRequest(addr64, sendPayload, sizeof(sendPayload));
            xbee.send(zbTx);

            Serial.print("synchro request!!: ");
            for (int i = 0; i < 2 + (allHop - 48) * 4 + 1 + 10; i ++) {
              Serial.print((char)sendPayload[i]);
            }
            Serial.print("\n");
          }
          else if (receivePayload[2 + (receivePayload[2] - 48) * 4 + 1] ==  REQUEST_SYNCHRO_HEADER) {// this time this node become server of time
            unsigned long serverReceiveMillis = now(); //max of 32bit = 4294967295

            //make return packet
            uint8_t allHop = receivePayload[2];

            uint8_t sendPayload[3 + (allHop - 48) * 4 + 1 + 10]; //0xF3 + hopcount + allHop + routeInfo + header + averageTime(10 digits)

            sendPayload[0] = 0xf4; //time synchro packet
            sendPayload[1] = allHop - 2;
            sendPayload[2] = allHop;

            for (int j = 0; j < allHop - 48; j++) { // receivePayload: addrA, addrB, addrC ===> sendPayload: addrC, addrB, addrA
              for (int i = 0; i < 4; i++) {
                sendPayload[3 + i + j * 4] = receivePayload[3 + i + (allHop - 48 - 1 - j) * 4];
              }
            }

            //calc next destination address by receivePayload
            union fourbyte sendPacketLSB;
            sendPacketLSB.byte[0] = sendPayload[2 + 4 + 4];
            sendPacketLSB.byte[1] = sendPayload[2 + 4 + 3];
            sendPacketLSB.byte[2] = sendPayload[2 + 4 + 2];
            sendPacketLSB.byte[3] = sendPayload[2 + 4 + 1];

            unsigned long serverSendMillis = now();
            unsigned long serverAverageMillis = (serverReceiveMillis + serverSendMillis) / 2;
            //          Serial.println(serverAverageMillis);

            sendPayload[2 + (allHop - 48) * 4 + 1] = RESPONCE_SYNCHRO_HEADER;
            char serverAveChar[10];
            sprintf(serverAveChar, "%010d", serverAverageMillis);
            //          Serial.println(serverAveChar);
            for (int i = 0; i < 10; i++) sendPayload[2 + (allHop - 48) * 4 + 1 + (i + 1)] = serverAveChar[i];

            XBeeAddress64 addr64 = XBeeAddress64(0x0013A200, sendPacketLSB.dword);
            ZBTxRequest zbTx = ZBTxRequest(addr64, sendPayload, sizeof(sendPayload));
            xbee.send(zbTx);

            Serial.print("synchro return Time!!: ");
            for (int i = 0; i < 2 + (allHop - 48) * 4 + 1 + 10; i ++) {
              Serial.print((char)sendPayload[i]);
            }
            Serial.print("\n");
          }
        }
        else { //packet should be hopped 1 or more times
          Serial.print(" >>> hop packet !!! to ");

          uint8_t allHop = receivePayload[2];
          union fourbyte sendPacketLSB;

          //calc next destination address by receivePayload
          sendPacketLSB.byte[0] = receivePayload[6 + (allHop - remainHop) * 4];
          sendPacketLSB.byte[1] = receivePayload[5 + (allHop - remainHop) * 4];
          sendPacketLSB.byte[2] = receivePayload[4 + (allHop - remainHop) * 4];
          sendPacketLSB.byte[3] = receivePayload[3 + (allHop - remainHop) * 4];

          Serial.print(sendPacketLSB.dword, HEX);
          //make send payload
          receivePayload[1] = remainHop - 1; //decrease counter
          Serial.print(" [1]:");
          Serial.print((char)receivePayload[1]);
          Serial.println(" ");

          //request synchro
          if (receivePayload[2 + (receivePayload[2] - 48) * 4 + 1] ==  REQUEST_SYNCHRO_HEADER) {
            synchroSendMillis = now();
            Serial.println(F(" synchroSendMillis recoded"));
          }

          XBeeAddress64 addr64 = XBeeAddress64(0x0013a200, sendPacketLSB.dword);
          ZBTxRequest zbTx = ZBTxRequest(addr64, receivePayload, sizeof(receivePayload));
          xbee.send(zbTx);
        }

        if (receivePayload[2 + (receivePayload[2] - 48) * 4 + 1] ==  RESPONCE_SYNCHRO_HEADER) { //if get responce synchro //process time request
          String receiveTimeData = "";

          //extract time to adjust time data from packet
          for (int i = 2 + (receivePayload[2] - 48) * 4 + 1 + 1; i < 2 + (receivePayload[2] - 48) * 4 + 1 + 1 + 10 ; i++) receiveTimeData += (char)rx.getData(i);
          unsigned long synchroAverageMillis = (unsigned long)(receiveTimeData.toInt());

          unsigned long selfAverageMillis = (synchroReceiveMillis + synchroSendMillis) / 2;
          unsigned long theta;
          if (synchroAverageMillis > selfAverageMillis) {
            theta = synchroAverageMillis - selfAverageMillis;
            setTime(synchroReceiveMillis + theta); // Sync Arduino clock to the time received on the serial port
          }
          else {
            theta = selfAverageMillis - synchroAverageMillis;
            setTime(synchroReceiveMillis - theta); // Sync Arduino clock to the time received on the serial port
          }

          Serial.print(F(" Turn Around Time: "));
          Serial.println(synchroReceiveMillis - synchroSendMillis);
          Serial.print(F(" synchroAverageMillis: "));
          Serial.println(synchroAverageMillis);
          Serial.print(F(" selfAverageMillis: "));
          Serial.println(selfAverageMillis);
          Serial.print(F(" theta: "));
          Serial.print(theta);

          //extract wakeUpTogther Time from packet
          int tempRouteId = receivePayload[2 + (receivePayload[2] - 48) * 4 + 1 + 10 + 1];
          receiveTimeData = "";
          for (int i = 2 + (receivePayload[2] - 48) * 4 + 1 + 10 + 1 + 1; i <  2 + (receivePayload[2] - 48) * 4 + 1 + 10 + 1 + 1 + 10; i++) receiveTimeData += (char)rx.getData(i);
          wakeUpTogetherFlag[tempRouteId] = true;
          appointedTime[tempRouteId] = (unsigned long)(receiveTimeData.toInt());

          Serial.println("");
          Serial.print(F(" RouteId: "));
          Serial.print(tempRouteId);
          Serial.print(F(" appoiTime recorded: "));
          Serial.print(digitalClockDisplay(appointedTime[tempRouteId]));

          //extract wakeUpTogther Time from packet
          tempRouteId = receivePayload[2 + (receivePayload[2] - 48) * 4 + 1 + 10 + 1 + 10 + 1]; //header + remainHop + allHop + header + adjustTime(10 digits) + routeId + wakeUpTime(10 digits) + routeId + sleepTime(10 digits)
          receiveTimeData = "";
          for (int i = 2 + (receivePayload[2] - 48) * 4 + 1 + 10 + 1 + 10 + 1 + 1; i <  2 + (receivePayload[2] - 48) * 4 + 1 + 10 + 1 + 10 + 1 + 1 + 10; i++) receiveTimeData += (char)rx.getData(i);
          sleepTimeFlag = true;
          sleepTime = (unsigned long)(receiveTimeData.toInt());

          Serial.println("");
          Serial.print(F(" RouteId: "));
          Serial.print(tempRouteId);
          Serial.print(F(" sleepTime recorded: "));
          Serial.print(digitalClockDisplay(sleepTime));
        }
        //wakeUpTogther Time notification
        else if (receivePayload[2 + (receivePayload[2] - 48) * 4 + 1] ==  TRIGGER_SET_HEADER) {
          int tempRouteId = receivePayload[2 + (receivePayload[2] - 48) * 4 + 1 + 1];
          String receiveTimeData = "";
          for (int i = 2 + (receivePayload[2] - 48) * 4 + 2  + 1; i < rx.getDataLength(); i++) receiveTimeData += (char)rx.getData(i);
          wakeUpTogetherFlag[tempRouteId] = true;
          appointedTime[tempRouteId] = (unsigned long)(receiveTimeData.toInt());

          Serial.println("");
          Serial.print(F(" RouteId: "));
          Serial.print(tempRouteId);
          Serial.print(F(" appointedTime recorded: "));
          Serial.print(digitalClockDisplay(appointedTime[tempRouteId]));


          //          //xbee power supply
          //         delay(100);
          //          Serial.print(F(" xbeePowerSupply OFF "));
          //          digitalWrite(powerSupplyPin, LOW);
          //          digitalWrite(xbeePowerLedPin, LOW);
        }

      }
      else { //the packet is not hopping packet
        Serial.print(" >>> got normal packet");
      }

      Serial.println("");
      Serial.print(F(" loop : "));
      Serial.print(millis() - currentMillis);
      Serial.println("ms");

    }
  }
}

//clock display functions
String digitalClockDisplay(time_t t) {
  // digital clock display of the time
  String temp = "";
  temp += String(hour(t));
  temp += printDigits(minute(t));
  temp += printDigits(second(t));
  temp += String(" ");
  temp += String(decisecond(t));
  temp += String(" ");
  temp += String(day(t));
  temp += String(" ");
  temp += String(month(t));
  temp += String(" ");
  temp += String(year(t));
  //  temp += "\n";
  return temp;
}

String printDigits(int digits) {
  // utility function for digital clock display: prints preceding colon and leading 0
  String temp = "";
  temp += ":";
  if (digits < 10)
    temp += "0";
  temp += String(digits);
  return temp;
}

