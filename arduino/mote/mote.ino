/*
   based on skecth_160416RLRNCFFPPSSTRSRSFSPTIABuggy
*/

String MOTENAME = "yournamehere"; //recommended to be between 1 ~ 10
int MOTEID = 20; //should be from 1 ~ 20
uint32_t DEST_ADDR_LSB = 0x40B0A672; // LSB of COODINATOR

#include <XBee.h>

union fourbyte {
  uint32_t dword;
  uint16_t word[2];
  uint8_t byte[4];
};

//loop serial print
unsigned long serialPreviousMillis = millis();

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

//temperature sensor
#define TEMP_SENSOR_PIN A0
#define SERIESRESISTOR 10000
#define servoOnInterval 5000

//Servo
#include <Servo.h>
#define SERVO_PIN 10
Servo myservo;
unsigned long servoPreviousMillis = millis();
#define servoOnInterval 5000

String getFormattedUplinkPacket(int moteid, double temperature, int voteDstId, String motename) {
  String payload = "";
  payload += UPLINK_HEADER;
  payload += char(moteid + int(ID_PACKET_OFFSET));
  char tempStr[4];
  sprintf(tempStr, "%04d", int(temperature * 10)); //    Serial.println(tempStr); // example    String tempStr = "0257";
  payload += tempStr;
  payload += char(voteDstId + int(ID_PACKET_OFFSET));
  payload += MOTENAME;
  payload += "\n";
  return payload;
}

void sendXBeeData(union fourbyte addrHSB, union fourbyte addrLSB, String payload) {
  uint8_t temppayload[payload.length()];
  for (int i = 0; i < payload.length(); i++) {
    temppayload[i] = payload.charAt(i);
  }
  Serial.println(F("Send ZbTx"));
  txAddr64 = XBeeAddress64(addrHSB.dword, addrLSB.dword);
  txRequest = ZBTxRequest(txAddr64, temppayload, sizeof(temppayload));
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
        if (0 < MOTEID && MOTEID < rx.getDataLength()) {
          //here shake servo motor
          int tempMyVotedCounter = int(receivePayload[MOTEID] - ID_PACKET_OFFSET);//          Serial.println(tempMyVotedCounter);
          int temp_angle = 30;
          if (tempMyVotedCounter >= 5) temp_angle = 150;
          else if (tempMyVotedCounter >= 2) temp_angle = 90;
          else if (tempMyVotedCounter >= 1) temp_angle = 60;
          else if (tempMyVotedCounter >= 0) temp_angle = 30;
          servoPreviousMillis = millis();
          myservo.write(temp_angle); //          Serial.println(temp_angle);
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
    Serial.println("Button clicked");
    //put on click LED
    digitalWrite(CLICK_LED_PIN, HIGH);
    clickLedPreviousMillis = millis();
  }
  oldButtonState = newButtonState;
  return buttonClicked;
}

//get value from switches
int getValueFromSwitches() {
  Serial.print("switch_values: ");
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

//Measure temperature, origined from Bob-san's program
double getTemperature(int pin) {
  int v = 1023 - analogRead(pin);
  double res = (1023.0 / v) - 1;
  res = SERIESRESISTOR / res;
  double temp = (1 / (0.00096564 + (0.00021068 * log(res) ) + (0.000000085826 * ( pow( log(res) , 3))))) - 273.15;
  return temp;
}

void setup() {
  Serial.begin(9600);
  xbee.setSerial(Serial); //for UNO

  pinMode(RECEIVE_LED_PIN, OUTPUT);
  digitalWrite(RECEIVE_LED_PIN, HIGH);

  pinMode(CLICK_LED_PIN, OUTPUT);
  digitalWrite(CLICK_LED_PIN, HIGH);

  txAddrHSB.dword = 0x0013A200;
  txAddrLSB.dword = DEST_ADDR_LSB; //the address of coordinator

  pinMode(BUTTON_PIN, INPUT_PULLUP);
  for (int i = 0; i < 5; i++) {
    pinMode(SWITCH_ARRAY_PIN[i], INPUT_PULLUP);
  }

  myservo.attach(SERVO_PIN, 550, 2000); //attach(pin number(must be PWM pin), MIN pulse width, MAX pulse width)
  myservo.write(0);
}

// continuously reads packets, looking for ZB Receive or Modem Status
void loop() {
  unsigned long currentMillis = millis();

  //check receiving data
  receiveXBeeData();

  //put off receive LED
  if (millis() - receiveLedPreviousMillis >= receiveLedOnInterval) digitalWrite(RECEIVE_LED_PIN, LOW);

  //put off click LED
  if (millis() - clickLedPreviousMillis >= clickLedOnInterval) digitalWrite(CLICK_LED_PIN, LOW);

  //make servo default
  if (millis() - servoPreviousMillis >= servoOnInterval) myservo.write(0);

  //sending data
  if (clickDetection() == 1) {
    int valueFromSwitches = getValueFromSwitches();
    double tempTemperature = getTemperature(TEMP_SENSOR_PIN); //    Serial.println(tempTemperature);
    String payload = getFormattedUplinkPacket(MOTEID, tempTemperature, valueFromSwitches, MOTENAME);
    sendXBeeData(txAddrHSB, txAddrLSB, payload);
  }

  //koop seconds
  if (millis() - serialPreviousMillis > 1000) {
    serialPreviousMillis += 1000;
    Serial.print("");
    Serial.print(F("loop : "));
    Serial.print(millis() - currentMillis);
    Serial.println("ms");
  }
}

