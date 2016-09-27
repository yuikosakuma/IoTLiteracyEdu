#include "source.h"

Mine::Mine() {
  myxbee = XBee();
  //receive
  myresponse = XBeeResponse();
  myrx = ZBRxResponse(); // create reusable response objects for responses we expect to handle
}

void Mine::init() {
  //XBee
  myxbee.setSerial(Serial); //for UNO
  //send
  mytxAddrHSB = 0x0013A200;
  mytxAddrLSB = DEST_ADDR_LSB; //the address of coordinator
}

void Mine::sendXBeeData(String payload) {
  uint8_t temppayload[payload.length()];
  for (int i = 0; i < (int)payload.length(); i++) {
    temppayload[i] = payload.charAt(i);
  }
  Serial.println(F("Send ZbTx"));
  mytxAddr64 = XBeeAddress64(mytxAddrHSB, mytxAddrLSB);
  mytxRequest = ZBTxRequest(mytxAddr64, temppayload, sizeof(temppayload));
  myxbee.send(mytxRequest);
}

void Mine::receiveXBeeData(Servo servo) {
  myxbee.readPacket();

  if (myxbee.getResponse().isAvailable()) {    // got something
    if (myxbee.getResponse().getApiId() == ZB_RX_RESPONSE) {      // got a zb rx packet
      //      Serial.print("got zb rx packet >>> ");

      //put on receive LED
      digitalWrite(RECEIVE_LED_PIN, HIGH);
      receiveLedPreviousMillis = millis();

      // now fill our zb rx class
      myxbee.getResponse().getZBRxResponse(myrx);

      //parsing data(payload) should be explored more
      uint8_t receivePayload [myrx.getDataLength()];
      for (int i = 0; i < myrx.getDataLength(); i++) receivePayload[i] = myrx.getData(i);

      //printing packet info
      //remote source address
      Serial.print(myrx.getRemoteAddress64().getMsb(), HEX);//data type of return value is uint32_t
      Serial.print(",");
      Serial.print(myrx.getRemoteAddress64().getLsb(), HEX);//data type of return value is uint32_t
      Serial.print(",");
      //data(payload) length
      Serial.print(myrx.getDataLength());
      Serial.print(",");
      Serial.println("");
      for (int i = 0; i < myrx.getDataLength(); i++) Serial.print((char)receivePayload[i]);
      Serial.println("");

      uint8_t payloadType = receivePayload[0]; //judge whether the packet is hopping packet or not
      if (payloadType == DOWNLINK_HEADER) {
        Serial.println(F("This packet is from Coordinator"));
        if (0 < MOTEID && MOTEID < myrx.getDataLength()) {
          //here shake servo motor
          int tempMyVotedCounter = int(receivePayload[MOTEID] - ID_PACKET_OFFSET);//          Serial.println(tempMyVotedCounter);
          int temp_angle = 30;
          if (tempMyVotedCounter >= 5) temp_angle = 150;
          else if (tempMyVotedCounter >= 2) temp_angle = 90;
          else if (tempMyVotedCounter >= 1) temp_angle = 60;
          else if (tempMyVotedCounter >= 0) temp_angle = 30;
          servoPreviousMillis = millis();
          servo.write(temp_angle); //          Serial.println(temp_angle);
        }
      }
      else { //the packet is not hopping packet
        Serial.println(F("got normal packet"));
      }
    }
  }
}


//for test

void MyClass::myPrint() {
  Serial.println(F("test"));
}

