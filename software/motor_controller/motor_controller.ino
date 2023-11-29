#include <BasicLinearAlgebra.h>

const int MOTOR_ONE_DIR_PIN = 5;
const int MOTOR_ONE_STEP_PIN = 6;
const int MOTOR_TWO_DIR_PIN = 7;
const int MOTOR_TWO_STEP_PIN = 8;

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

double norm(BLA::Matrix<2> vec) {
  BLA::Matrix<1> result = ~vec * vec;
  return result(0);
}

void moveTo(BLA::Matrix<2>& current_theta, BLA::Matrix<2>& goal_pos) {
  BLA::Matrix<2> initial_pos = theta2pos(current_theta);
  BLA::Matrix<2> current_pos = theta2pos(current_theta);
  BLA::Matrix<2> directions[] = {{1, 0}, {0, 1}, {-1, 0}, {0, -1}};
  double highest_alignment;
  BLA::Matrix<2> best_direction;

  auto alignment_with_goal = [&](const BLA::Matrix<2> delta) {
    BLA::Matrix<2> diff_current = goal_pos - current_pos;
    BLA::Matrix<2> diff_new = goal_pos - theta2pos(current_theta + delta);
    BLA::Matrix<1> inner_prod = ~diff_current * diff_new;
    return (inner_prod(0)) / norm(diff_current) / norm(diff_new);
  };

  auto distance_from_straight = [&](const BLA::Matrix<2> delta) {
    BLA::Matrix<2> new_pos = theta2pos(current_theta + delta);
    return (
      (goal_pos(0) - initial_pos(0)) * (goal_pos(1) - new_pos(1))
      - (goal_pos(1) - initial_pos(1)) * (goal_pos(0) - new_pos(0))
    );
  };

  while (norm(current_pos - goal_pos) > 1e-5) {
//    Serial.print("current_theta=");
//    Serial.print(current_theta(0));
//    Serial.print(",");
//    Serial.print(current_theta(1));
//    Serial.println();
//    delay(100);
    highest_alignment = -INFINITY;
    for (int i=0; i < 4; i++) {
      if (distance_from_straight(directions[i]) < 12 * sin(2*PI / (double) FULL_ROTATION)) {
        // does not stray too far from the line
        if (alignment_with_goal(directions[i]) > highest_alignment) {
          // and is aligned with the direction we want
          best_direction = directions[i];
          highest_alignment = alignment_with_goal(directions[i]);
        }
      }
    }

    rotateMotor(1, best_direction(0), 500);
    rotateMotor(2, best_direction(1), 500);
    current_theta = current_theta + best_direction;
    current_pos = theta2pos(current_theta);

  }
}

void loop()
{
  BLA::Matrix<2> current_theta = {0, FULL_ROTATION/4};
  BLA::Matrix<2> goal_pos = theta2pos({-500, FULL_ROTATION/4 + 500});
  moveTo(current_theta, goal_pos);
  delay(10000);
//  //make steps
//  Serial.println("Start rotation");
//  rotateMotor(1, FULL_ROTATION, 500);
//  delay(1000);
//  rotateMotor(1, -FULL_ROTATION, 500);
//  delay(1000);
//  rotateMotor(2, FULL_ROTATION, 500);
//  delay(1000);
//  rotateMotor(2, -FULL_ROTATION, 500);
//  delay(1000);
}
