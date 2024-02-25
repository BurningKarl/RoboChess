const int OPTICAL_A_PIN = 7;
const int OPTICAL_B_PIN = 8;

const int MOTOR_A_ENABLE_PIN = 9;
const int MOTOR_A_INPUT1_PIN = 10;
const int MOTOR_A_INPUT2_PIN = 11;

bool currentOpticalRead = false;
bool lastOpticalRead = false;
int motorRotation = 0;

int FULL_ROTATION = 16;

// Set the speed of the motors
// The speed is given between 0 and 255 with positive values
// corresponding to one direction and negative to the other
void rotateMotor(int speedMotorA) {
  if (speedMotorA == 0) {
    digitalWrite(MOTOR_A_INPUT1_PIN, LOW);
    digitalWrite(MOTOR_A_INPUT2_PIN, LOW);
  } else if (speedMotorA > 0) {
    digitalWrite(MOTOR_A_INPUT1_PIN, HIGH);
    digitalWrite(MOTOR_A_INPUT2_PIN, LOW);
    analogWrite(MOTOR_A_ENABLE_PIN, speedMotorA);
  } else {
    digitalWrite(MOTOR_A_INPUT1_PIN, LOW);
    digitalWrite(MOTOR_A_INPUT2_PIN, HIGH);
    analogWrite(MOTOR_A_ENABLE_PIN, -speedMotorA);
  }
}

void setup() {
  Serial.begin(9600);
  
  pinMode(OPTICAL_A_PIN, INPUT);
  pinMode(OPTICAL_B_PIN, INPUT);

  pinMode(MOTOR_A_ENABLE_PIN, OUTPUT);
  pinMode(MOTOR_A_INPUT1_PIN, OUTPUT);
  pinMode(MOTOR_A_INPUT2_PIN, OUTPUT);

  digitalWrite(MOTOR_A_INPUT1_PIN, LOW);
  digitalWrite(MOTOR_A_INPUT2_PIN, LOW);

  lastOpticalRead = digitalRead(OPTICAL_A_PIN);
}

void loop() {
  motorRotation = 0;
  rotateMotor(255);
  while (abs(motorRotation) <= 300 * FULL_ROTATION) {
    currentOpticalRead = digitalRead(OPTICAL_A_PIN);
    if (currentOpticalRead != lastOpticalRead) {
      if (digitalRead(OPTICAL_B_PIN) == currentOpticalRead) {
        motorRotation++;
      } else {
        motorRotation--;
      }
      lastOpticalRead = currentOpticalRead;
    }

//    Serial.print("Rotation:");
//    Serial.print(motorRotation);
//    Serial.println();
  }

  rotateMotor(0);
  
  Serial.print("Rotation:");
  Serial.print(motorRotation);
  Serial.println();

  delay(2000);

//  Serial.print("Optical_A:");
//  Serial.print(digitalRead(OPTICAL_A_PIN));
//  Serial.print(",");
//  Serial.print("Optical_B:");
//  Serial.print(digitalRead(OPTICAL_B_PIN));
//  Serial.println();
}
