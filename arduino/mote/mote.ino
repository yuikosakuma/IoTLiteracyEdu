/**
   based on skecth_160416RLRNCFFPPSSTRSRSFSPTIABuggy
  Catch Packet
  LED On DEFIND Second
  Send Packet

  I hope that this program can visualize the route of packet of XBee
*/

String motename = "yournamehere";
int moteid = 2; //should be from 1 ~ 20

#include <XBee.h>

union fourbyte {
  uint32_t dword;
  uint16_t word[2];
  uint8_t byte[4];
};

//Receive LED
unsigned long receiveLedPreviousMillis = millis();
#define RECEIVE_LED_PIN 3
#define receiveLedOnInterval 1000

//Click LED
unsigned long clickLedPreviousMillis = millis();
#define CLICK_LED_PIN 4
#define clickLedOnInterval 1000

//XBee
XBee xbee = XBee();
//receive
XBeeResponse response = XBeeResponse();
ZBRxResponse rx = ZBRxResponse(); // create reusable response objects for responses we expect to handle
//send
union fourbyte txAddrHSB;
union fourbyte txAddrLSB;
XBeeAddress64 txAddr64;
ZBTxRequest txRequest;

//packet
#define ID_PACKET_OFFSET '0'
#define UPLINK_HEADER 'U'
#define DOWNLINK_HEADER 'D'

//button
#define BUTTON_PIN 2
int oldButtonState = 0;

//switch
int SWITCH_ARRAY_PIN[5] = {5, 6, 7, 8, 9};
int switch_values[5] = {0, 0, 0, 0, 0};

void sendXBeeData(union fourbyte addrHSB, union fourbyte addrLSB, uint8_t payload[], int sizeOfPayload) {
  Serial.println(F("Send ZbTx"));
  txAddr64 = XBeeAddress64(addrHSB.dword, addrLSB.dword);
  txRequest = ZBTxRequest(txAddr64, payload, sizeOfPayload);
  xbee.send(txRequest);
}

void receiveXBeeData() {
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
        Serial.println("This packet is from Coordinator");
        if (0 < moteid && moteid < rx.getDataLength()) {
          //here shake servo motor
        }
      }
      else { //the packet is not hopping packet
        Serial.println("got normal packet");
      }
    }
  }
}

//click detection
int clickDetection() {
  int buttonClicked = 0;
  int newButtonState = digitalRead(BUTTON_PIN);
  if (oldButtonState == HIGH && newButtonState == LOW) { //button pressed. CAUTION pull up
    buttonClicked = 1;

    //put on click LED
    digitalWrite(CLICK_LED_PIN, HIGH);
    clickLedPreviousMillis = millis();
  }
  oldButtonState = newButtonState;
  if (buttonClicked) return 1;
  else return 0;
}

//get value from switches
int getValueFromSwitches() {
  Serial.println("switch_values: ");
  int value_from_switches = 0;
  for (int i = 0; i < 5; i++) {
    switch_values[i] = digitalRead(SWITCH_ARRAY_PIN[i]);
    if (switch_values[i] == LOW) value_from_switches += (1 << i); //switched
    Serial.print(switch_values[i]);
    Serial.print(",");
  }
  Serial.print("value_from_swtches: ");
  Serial.print(value_from_switches);
  Serial.println("");
  return value_from_switches;
}

void setup() {
  Serial.begin(9600);
  xbee.setSerial(Serial); //for UNO

  pinMode(RECEIVE_LED_PIN, OUTPUT);
  digitalWrite(RECEIVE_LED_PIN, HIGH);

  pinMode(CLICK_LED_PIN, OUTPUT);
  digitalWrite(CLICK_LED_PIN, HIGH);

  txAddrHSB.dword = 0x0013A200;
  txAddrLSB.dword = 0x40B0A672; //the address of coordinator

  pinMode(BUTTON_PIN, INPUT_PULLUP);
  for (int i = 0; i < 5; i++) {
    pinMode(SWITCH_ARRAY_PIN[i], INPUT_PULLUP);
  }
}

unsigned long pastSendMillis = millis();

// continuously reads packets, looking for ZB Receive or Modem Status
void loop() {
  unsigned long currentMillis = millis();

  receiveXBeeData();

  //put off receive LED
  if (millis() - receiveLedPreviousMillis >= receiveLedOnInterval) {
    digitalWrite(RECEIVE_LED_PIN, LOW);
  }

  //put off click LED
  if (millis() - clickLedPreviousMillis >= clickLedOnInterval) {
    digitalWrite(CLICK_LED_PIN, LOW);
  }

  //sending data
  if (clickDetection() == 1) {
    Serial.println("Button clicked");
    //array switch
    int value = getValueFromSwitches();
    String tempValue = "0257";

    String payload = "";
    payload += UPLINK_HEADER;
    payload += char(moteid + int(ID_PACKET_OFFSET));
    payload += tempValue;
    payload += char(value + int(ID_PACKET_OFFSET));
    payload += motename;
    payload += "\n";
    uint8_t temppayload[payload.length()];
    for (int i = 0; i < payload.length(); i++) {
      temppayload[i] = payload.charAt(i);
    }
    sendXBeeData(txAddrHSB, txAddrLSB, temppayload, sizeof(temppayload));
  }


  //transmission
  if (millis() - pastSendMillis > 1000) {
    pastSendMillis += 1000;
    Serial.print("");
    Serial.print(F(" loop : "));
    Serial.print(millis() - currentMillis);
    Serial.println("ms");
  }
}

