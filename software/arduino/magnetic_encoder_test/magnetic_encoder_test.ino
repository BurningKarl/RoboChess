#include <AS5600.h>

AS5600 as5600;

void setup() {
  // put your setup code here, to run once:
  as5600.begin();
  Serial.begin(9600);
  Wire.begin();
}

void loop() {
  // put your main code here, to run repeatedly:
  Serial.print("too weak: ");
  Serial.print(as5600.magnetTooWeak());
  Serial.print(", too strong: ");
  Serial.print(as5600.magnetTooStrong());
  Serial.print(", detected: ");
  Serial.print(as5600.detectMagnet());
  Serial.print(", angle: ");
  Serial.println(as5600.readAngle() * AS5600_RAW_TO_DEGREES);
}
