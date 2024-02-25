#include <SoftwareSerial.h>
#include <ArduinoJson.h>
#include <LoopbackStream.h>

SoftwareSerial bluetoothSerial(10, 9);  // RX, TX

const int CONNECTION_PIN = 12;

bool isConnected() {
  return digitalRead(CONNECTION_PIN) == HIGH;
}

void setup() {
  bluetoothSerial.begin(9600);
  Serial.begin(9600);
  pinMode(CONNECTION_PIN, INPUT);
}

void loop() {  
  while (bluetoothSerial.available()) {
    Serial.write(bluetoothSerial.read());
  }
  while (Serial.available()) {
    bluetoothSerial.write(Serial.read());
  }
}
