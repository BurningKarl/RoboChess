// Red = 5V
// Brown = GND
// Orange = Data

const int SERVO_PIN = 3;

void setup() {
  Serial.begin(9600);
  pinMode(SERVO_PIN, OUTPUT);
}

void loop() {
  analogWrite(SERVO_PIN, 120);
  delay(1000);
  analogWrite(SERVO_PIN, 160);
  delay(1000);
  // analogWrite(SERVO_PIN, 255);
}
