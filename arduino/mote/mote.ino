/**
 * based on sketch_160212RLRNCFFPPSSTiming
Catch Packet
LED On DEFIND Second
Send Packet

I hope that this program can visualize the route of packet of XBee
*/

#include <XBee.h>

#define xbeeReceiveLedPin A5
#define xbeePowerLedPin A4
#define powerSupplyPin A3
#define ledOnInterval 2000

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
int powerSupplyFlag = 0;
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

void setup() {
  Serial.begin(9600);
  Serial1.begin(9600);
  xbee.begin(Serial1);

  serialPreviousMillis = millis();

  pinMode(xbeeReceiveLedPin, OUTPUT);
  digitalWrite(xbeeReceiveLedPin, HIGH);
  pinMode(xbeePowerLedPin, OUTPUT);
  digitalWrite(xbeePowerLedPin, HIGH);
  pinMode(powerSupplyPin, OUTPUT);
  digitalWrite(powerSupplyPin, HIGH);
}

// continuously reads packets, looking for ZB Receive or Modem Status
void loop() {
  //  Serial.println("--- loop start --- ");

  unsigned long currentMillis = millis();

  //serial console display
  if (millis() - serialPreviousMillis > 1000) {
    serialPreviousMillis = millis();
    if (powerSupplyIntervalFlag) { //interval ON
      if (powerSupplyFlag) { //on
        Serial.println("XBee ON");
      }
      else { //off
        Serial.println("XBee OFF");
      }
    }
  }

  //led on DEFINED milli seconds
  if (millis() - ledPreviousMillis >= ledOnInterval) {
    //    Serial.println(currentMillis - ledPreviousMillis);
    //    ledPreviousMillis = currentMillis;
    digitalWrite(xbeeReceiveLedPin, LOW);
  }

  //XBee power supply on off
  if (powerSupplyIntervalFlag) { //interval ON
    if (millis() - xbeePastMillis > xbeeOnInterval) {
      xbeePastMillis = millis();
      powerSupplyFlag = 1 - powerSupplyFlag;
      if (powerSupplyFlag) { //on
        digitalWrite(powerSupplyPin, HIGH);
        digitalWrite(xbeePowerLedPin, HIGH);
      }
      else { //off
        digitalWrite(powerSupplyPin, LOW);
        digitalWrite(xbeePowerLedPin, LOW);
      }
    }
  }
  else { //interval OFF, always XBee on
    digitalWrite(powerSupplyPin, HIGH);
    digitalWrite(xbeePowerLedPin, HIGH);
  }

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
      int ar = analogRead(A11);
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

  //xbee receiving
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
      Serial.println("");

      //data(payload)
      uint8_t receivePayload [rx.getDataLength()];
      for (int i = 0; i < rx.getDataLength(); i++) {
        receivePayload[i] = rx.getData(i);
      }
      for (int i = 0; i < rx.getDataLength(); i++) {
        Serial.print((char)receivePayload[i]);
      }

      uint8_t payloadType = receivePayload[0];

      //judge whether the packet is hopping packet or not
      if (payloadType == 0xF0) { //hopping packet!!
        uint8_t remainHop = receivePayload[1];
        Serial.print(" remainHop: ");
        Serial.print(remainHop);
        if (0 <= remainHop && remainHop <= 48) { //no more hop needed
          Serial.print(" >>> no more hop needed");
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

        //XBee power supply interval on off
        powerSupplyIntervalFlag = 1 - powerSupplyIntervalFlag;
        if (powerSupplyIntervalFlag) { //supply interval on
          //          Serial.print("\n(int)remainHop: ");
          //          Serial.println((int)remainHop);
          delay((remainHop - 48 + 1) * 200); //adjust sleeping timing
        }
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
      else { //the packet is not hopping packet
        Serial.print(" >>> got normal packet");
      }

      Serial.print(F(" loop : "));
      Serial.print(millis() - currentMillis);
      Serial.println("ms");

    }
  }
}
