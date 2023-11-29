#include <BasicLinearAlgebra.h>

const int MOTOR_ONE_DIR_PIN = 8;
const int MOTOR_ONE_STEP_PIN = 9;
const int MOTOR_TWO_DIR_PIN = 6;
const int MOTOR_TWO_STEP_PIN = 7;

const int FULL_ROTATION = 1600 * 4;

void setup() 
{
  Serial.begin(9600);
  //set pin modes
  pinMode(MOTOR_ONE_DIR_PIN, OUTPUT); // set the DIR_PIN as an output
  digitalWrite(MOTOR_ONE_DIR_PIN, LOW); // set the direction pin to low
  pinMode(MOTOR_ONE_STEP_PIN, OUTPUT); // set the STEP_PIN as an output
  digitalWrite(MOTOR_ONE_STEP_PIN, LOW); // set the step pin to low
}

// This function rotates a motor for the given amount of steps.
// motor: determines which motor to move, either 1 or 2
// steps: sets the amount of steps as well as the direction
//        (positive -> anticlockwise, negative -> clockwise)
// delay_: amount of microseconds between steps, min 100
void rotateMotor(int motor, int steps, int delay_) {
  int dir_pin, step_pin;
  if (motor == 1) {
    dir_pin = MOTOR_ONE_DIR_PIN;
    step_pin = MOTOR_ONE_STEP_PIN;
  } else {
    dir_pin = MOTOR_TWO_DIR_PIN;
    step_pin = MOTOR_TWO_STEP_PIN;
  }

  // if steps is positive, we move anticlockwise
  digitalWrite(dir_pin, steps > 0 ? LOW : HIGH);

  for (int i = 0; i < abs(steps); i++) {
    digitalWrite(step_pin, HIGH);
    delayMicroseconds(delay_);
    digitalWrite(step_pin, LOW);
    delayMicroseconds(delay_);
  }
  
}

BLA::Matrix<2> theta2pos(BLA::Matrix<2> theta) {
  double x = cos(theta(0) / (double) FULL_ROTATION) + cos((theta(0) + theta(1)) / (double) FULL_ROTATION);
  double y = sin(theta(0) / (double) FULL_ROTATION) + sin((theta(0) + theta(1)) / (double) FULL_ROTATION);
  return {x, y};
}

double dist(BLA::Matrix<2> pos1, BLA::Matrix<2> pos2) {
  BLA::Matrix<2> diff = pos1 - pos2;
  BLA::Matrix<1> result = (~diff) * diff;
  return result(0);
}

void moveTo(BLA::Matrix<2> current_theta, BLA::Matrix<2> goal_pos) {
  BLA::Matrix<2> current_pos = theta2pos(current_theta);
  BLA::Matrix<2> directions[] = {{1, 0}, {0, 1}, {-1, 0}, {0, -1}};
  double smallest_distance;
  BLA::Matrix<2> best_direction;
  
  while (dist(current_pos, goal_pos) > 1e-5) {
    auto distance_to_goal = [&](const BLA::Matrix<2> delta) {
      return dist(theta2pos(current_theta + delta), goal_pos);
    };

    smallest_distance = INFINITY;
    for (int i=0; i < 4; i++) {
      if (distance_to_goal(directions[i]) < smallest_distance) {
        best_direction = directions[i];
        smallest_distance = distance_to_goal(directions[i]);
      }
    }

    rotateMotor(1, best_direction(0), 500);
    rotateMotor(2, best_direction(0), 500);
    current_theta = current_theta + best_direction;
  }
}

void loop()
{
  //make steps
  Serial.println("Start rotation");
  rotateMotor(1, FULL_ROTATION, 500);
  delay(1000);
  rotateMotor(1, -FULL_ROTATION, 500);
  delay(1000);
  rotateMotor(2, FULL_ROTATION, 500);
  delay(1000);
  rotateMotor(2, -FULL_ROTATION, 500);
  delay(1000);
}
