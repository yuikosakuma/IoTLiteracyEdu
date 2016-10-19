// mote.ino
// Program for Arduino version2
// Keio University Westlab 2016.10
// Author: Tada Matz

//<==== Please change according to an instruction
String MOTENAME = "yourname"; //recommended to be between 1 ~ 10
int MOTEID = 0; //should be from 1 ~ 20
uint32_t DEST_ADDR_LSB = 0x40B0A672; // LSB of XBee Coordinator Address
//====>Please change according to an instruction

#include "XBee.h"
#include "source.h"

Servo myservo;
MyXBee myxbee;
int oldButtonState = 0;
boolean receiveServoDataFlag = false;
int receiveLedState = 0;
unsigned long serialPreviousMillis;    //loop serial print
unsigned long clickLedPreviousMillis;
unsigned long servoPreviousMillis;

#define WITH_PERIODIC
#ifdef WITH_PERIODIC
unsigned long sendPastMillis = millis();
#define SEND_INTERVAL 1000
#endif

int currentAngle = 0;
#define WITH_SERVO_FOLLOWING
#ifdef WITH_SERVO_FOLLOWING
int lastVolumeValue = 0;
#endif

void setup() {
  Serial.begin(9600);

  serialPreviousMillis = millis();
  clickLedPreviousMillis = millis();
  servoPreviousMillis = millis();

  pinMode(RECEIVE_LED_PIN, OUTPUT);
  digitalWrite(RECEIVE_LED_PIN, HIGH);
  pinMode(CLICK_LED_PIN, OUTPUT);
  digitalWrite(CLICK_LED_PIN, HIGH);
  pinMode(BUTTON_PIN, INPUT_PULLUP);

  myservo.attach(SERVO_PIN); //attach(pin number(must be PWM pin), MIN pulse width, MAX pulse width)
  myservo.write(0);

  myxbee.init();
}

void loop() { //loop
  digitalWrite(RECEIVE_LED_PIN, receiveLedState);

  if (millis() - clickLedPreviousMillis >= CLICK_LED_ON_INTERVAL) digitalWrite(CLICK_LED_PIN, LOW);  //put off click LED
  if (receiveServoDataFlag && millis() - servoPreviousMillis >= SERVO_ON_INTERVAL) {
    receiveServoDataFlag = false;
    digitalWrite(CLICK_LED_PIN, LOW);  //put off click LED
  }

  //check receiving data
  myxbee.receiveXBeeData(myservo);

  //sending data
  if (clickDetection() == 1) {
    Serial.println(F("Button clicked"));
    digitalWrite(CLICK_LED_PIN, HIGH);
    clickLedPreviousMillis = millis();
    float tempTemperature = getTemperature(TEMP_SENSOR_PIN);
    int tempVolume = getVolume(VOLUME_PIN);
    char tempStr[1 + 1 + 4 + 4];
    sprintf(tempStr, "%c%c%04d%04d",
            UPLINK_HEADER,
            MOTEID + int(ID_PACKET_OFFSET),
            int(tempTemperature * 10),
            tempVolume);
    String temppayload = "";
    temppayload += tempStr + MOTENAME + "\n";
    myxbee.sendXBeeData(temppayload);
    Serial.print("temppayload: ");
    Serial.print(temppayload);
  }

#ifdef WITH_PERIODIC
  if (millis() - sendPastMillis > SEND_INTERVAL) {
    sendPastMillis += SEND_INTERVAL;
    float tempTemperature = getTemperature(TEMP_SENSOR_PIN);
    int tempVolume = getVolume(VOLUME_PIN);
    char tempStr[1 + 1 + 4 + 4];
    sprintf(tempStr, "%c%c%04d%04d",
            UPLINK_HEADER,
            MOTEID + int(ID_PACKET_OFFSET),
            int(tempTemperature * 10),
            tempVolume);
    String temppayload = "";
    temppayload += tempStr + MOTENAME + "\n";
    myxbee.sendXBeeData(temppayload);
    Serial.print("temppayload: ");
    Serial.print(temppayload);
  }
#endif

#ifdef WITH_SERVO_FOLLOWING
  if (!receiveServoDataFlag) {
    int tempVolume = getVolume(VOLUME_PIN);
    if (tempVolume != lastVolumeValue) {
      lastVolumeValue = tempVolume;
      currentAngle = (int)map(tempVolume, 0, 1023, 0, 165);
      myservo.write(currentAngle);
      delay(15);
    }
  }
#endif

  if (millis() - serialPreviousMillis > 1000) {  //loop seconds
    serialPreviousMillis += 1000;
    Serial.println(F("in a loop"));
  }
}

int clickDetection() { //click detection
  int buttonClicked = 0;
  int newButtonState = digitalRead(BUTTON_PIN);
  if (oldButtonState == HIGH && newButtonState == LOW) buttonClicked = 1; //button pressed. CAUTION pull up
  oldButtonState = newButtonState;
  return buttonClicked;
}

float getTemperature(int pin) { //Measure temperature, origined from Bob-san's program
  int v = 1023 - analogRead(pin);
  float res = (1023.0 / v) - 1;
  res = SERIESRESISTOR / res;
  float temp = (1 / (0.00096564 + (0.00021068 * log(res) ) + (0.000000085826 * ( pow( log(res) , 3))))) - 273.15;
  return temp;
}

int getVolume(int pin) { //measure volume value through analog pin
  return analogRead(pin);
}


