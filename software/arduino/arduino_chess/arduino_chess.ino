#include <SoftwareSerial.h>
#include <ArduinoJson.h>
#include <LoopbackStream.h>

SoftwareSerial bluetoothSerial(10, 9);  // RX, TX

const int CONNECTION_PIN = 12;

bool isConnected() {
  return digitalRead(CONNECTION_PIN) == HIGH;
}

// A dynamically allocated write buffer for the Bluetooth
// connection to collect messages when the connection is lost
LoopbackStream bluetoothBuffer(1000);


void handleRequest(StaticJsonDocument<300>& request, StaticJsonDocument<300>& response) {
  response["version"] = request["version"];
  response["type"] = "response";
  response["id"] = request["id"];
  
  auto type = request["type"].as<const char*>();
  if (strcmp(type, "move") == 0) {
    response["moveSuccessful"] = true;
  } else if (strcmp(type, "occupied") == 0) {
    JsonArray occupiedSquares = response.createNestedArray("occupied");
    occupiedSquares.add(0x00);
    occupiedSquares.add(0x01);
    occupiedSquares.add(0x02);
    occupiedSquares.add(0x03);
    occupiedSquares.add(0x04);
    occupiedSquares.add(0x05);
    occupiedSquares.add(0x06);
    occupiedSquares.add(0x07);
    occupiedSquares.add(0x10);
    occupiedSquares.add(0x11);
    occupiedSquares.add(0x12);
    occupiedSquares.add(0x13);
    occupiedSquares.add(0x14);
    occupiedSquares.add(0x15);
    occupiedSquares.add(0x16);
    occupiedSquares.add(0x17);

    occupiedSquares.add(0x60);
    occupiedSquares.add(0x61);
    occupiedSquares.add(0x62);
    occupiedSquares.add(0x63);
    occupiedSquares.add(0x64);
    occupiedSquares.add(0x65);
    occupiedSquares.add(0x66);
    occupiedSquares.add(0x67);
    occupiedSquares.add(0x70);
    occupiedSquares.add(0x71);
    occupiedSquares.add(0x72);
    occupiedSquares.add(0x73);
    occupiedSquares.add(0x74);
    occupiedSquares.add(0x75);
    occupiedSquares.add(0x76);
    occupiedSquares.add(0x77);
  } else {
    // Should send error response
  }
  return response;
}


void setup() {
  bluetoothSerial.begin(9600);
  Serial.begin(9600);
  pinMode(CONNECTION_PIN, INPUT);
}

void loop() {  
  if (bluetoothSerial.available()) {
    StaticJsonDocument<300> request;
    deserializeJson(request, bluetoothSerial);
    while (bluetoothSerial.read() != '\n') {
      // wait for end of line
    }
    Serial.print("App:   ");
    serializeJson(request, Serial);
    Serial.print("  overflowed: ");
    Serial.print(request.overflowed());
    Serial.println("");
    if (request["version"] == 1) {
      StaticJsonDocument<300> response;
      handleRequest(request, response);
      serializeJson(response, bluetoothSerial);
      bluetoothSerial.println();
      Serial.print("Board: ");
      serializeJson(response, Serial);
      Serial.print("  overflowed: ");
      Serial.print(response.overflowed());
      Serial.println();
    }
  }
  while (Serial.available()) {
    bluetoothSerial.write(Serial.read());
  }
}
