/*
   source.cpp
   Author: Tada Matz
   Comment: Methods of MyXBee class
*/

#include "source.h"

MyXBee::MyXBee() {
  xbee = XBee();
  //receive
  response = XBeeResponse();
  rx = ZBRxResponse(); // create reusable response objects for responses we expect to handle
}

void MyXBee::init() {
  //XBee
  xbee.setSerial(Serial); //for UNO
  //send
  txAddrHSB = 0x0013A200;
  txAddrLSB = DEST_ADDR_LSB; //the address of coordinator
}

void MyXBee::sendXBeeData(String payload) {
  uint8_t temppayload[payload.length()];
  for (int i = 0; i < (int)payload.length(); i++) {
    temppayload[i] = payload.charAt(i);
  }
  Serial.println(F("Send ZbTx"));
  txAddr64 = XBeeAddress64(txAddrHSB, txAddrLSB);
  txRequest = ZBTxRequest(txAddr64, temppayload, sizeof(temppayload));
  xbee.send(txRequest);
}

void MyXBee::receiveXBeeData(Servo servo) {
  xbee.readPacket();

  if (xbee.getResponse().isAvailable()) {    // got something
    if (xbee.getResponse().getApiId() == ZB_RX_RESPONSE) {      // got a zb rx packet
      //      Serial.print("got zb rx packet >>> ");

      //put on receive LED
      digitalWrite(RECEIVE_LED_PIN, HIGH);
      receiveLedPreviousMillis = millis();

      // now fill our zb rx class
      xbee.getResponse().getZBRxResponse(rx);

      //parsing data(payload) should be explored more
      uint8_t receivePayload [rx.getDataLength()];
      for (int i = 0; i < rx.getDataLength(); i++) receivePayload[i] = rx.getData(i);

      //printing packet info
      //remote source address
      Serial.print(rx.getRemoteAddress64().getMsb(), HEX);//data type of return value is uint32_t
      Serial.print(",");
      Serial.print(rx.getRemoteAddress64().getLsb(), HEX);//data type of return value is uint32_t
      Serial.print(",");
      //data(payload) length
      Serial.print(rx.getDataLength());
      Serial.print(",");
      Serial.println("");
      for (int i = 0; i < rx.getDataLength(); i++) Serial.print((char)receivePayload[i]);
      Serial.println("");

      uint8_t payloadType = receivePayload[0]; //judge whether the packet is hopping packet or not
      if (payloadType == DOWNLINK_HEADER) {
        Serial.println(F("This packet is from Coordinator"));
        //here shake servo motor
        int temp_angle = 0;
        temp_angle = ((int)receivePayload[1] - '0') * 100 + ((int)receivePayload[2] - '0') * 10 + ((int)receivePayload[3] - '0') * 1;
        Serial.print("temp_angle: ");
        Serial.println(temp_angle);
        servoPreviousMillis = millis();
        servo.write(temp_angle); //          Serial.println(temp_angle);
      }
      else { //the packet is normal packet
        Serial.println(F("got normal packet"));
      }
    }
  }
}
