#include <BasicLinearAlgebra.h>

// Motor 1 is the "shoulder" joint
// Motor 2 is the "elbow" joint
// Both operate at 24V
const int MOTOR_ONE_DIR_PIN = 5;
const int MOTOR_ONE_STEP_PIN = 6;
const int MOTOR_TWO_DIR_PIN = 7;
const int MOTOR_TWO_STEP_PIN = 8;

// number of steps in one rotation of the motor
const int FULL_ROTATION = 1600;

// One rotation of the arm is
// - 4 * FULL_ROTATION steps for motor 1
// - 3 * FULL_ROTATION steps for motor 2

void setup() {
  Serial.begin(9600);

  pinMode(MOTOR_ONE_DIR_PIN, OUTPUT);
  pinMode(MOTOR_ONE_STEP_PIN, OUTPUT);
  digitalWrite(MOTOR_ONE_DIR_PIN, LOW);
  digitalWrite(MOTOR_ONE_STEP_PIN, LOW);

  pinMode(MOTOR_TWO_DIR_PIN, OUTPUT);
  pinMode(MOTOR_TWO_STEP_PIN, OUTPUT);
  digitalWrite(MOTOR_TWO_DIR_PIN, LOW);
  digitalWrite(MOTOR_TWO_STEP_PIN, LOW);
}

// This function rotates both motors for the given amount of steps.
// steps_motor1: how many steps to rotate motor 1
// steps_motor2: how many steps to rotate motor 2
//   (positive -> anti-clockwise, negative -> clockwise)
// delay_: amount of microseconds between steps, min 100
void rotateMotor(int steps_motor1, int steps_motor2, int delay_) {
  digitalWrite(MOTOR_ONE_DIR_PIN, steps_motor1 > 0 ? LOW : HIGH);
  digitalWrite(MOTOR_TWO_DIR_PIN, steps_motor2 > 0 ? LOW : HIGH);

  int stepsTaken = 0;
  for (; stepsTaken < min(abs(steps_motor1), abs(steps_motor2)); stepsTaken++) {
    digitalWrite(MOTOR_ONE_STEP_PIN, HIGH);
    digitalWrite(MOTOR_TWO_STEP_PIN, HIGH);
    delayMicroseconds(delay_);
    digitalWrite(MOTOR_ONE_STEP_PIN, LOW);
    digitalWrite(MOTOR_TWO_STEP_PIN, LOW);
    delayMicroseconds(delay_);
  }

  if (abs(steps_motor1) > stepsTaken) {
    for (; stepsTaken < abs(steps_motor1); stepsTaken++) {
      digitalWrite(MOTOR_ONE_STEP_PIN, HIGH);
      delayMicroseconds(delay_);
      digitalWrite(MOTOR_ONE_STEP_PIN, LOW);
      delayMicroseconds(delay_);
    }
  }
  if (abs(steps_motor2) > stepsTaken) {
    for (; stepsTaken < abs(steps_motor2); stepsTaken++) {
      digitalWrite(MOTOR_TWO_STEP_PIN, HIGH);
      delayMicroseconds(delay_);
      digitalWrite(MOTOR_TWO_STEP_PIN, LOW);
      delayMicroseconds(delay_);
    }
  }
}

BLA::Matrix<2> theta2pos(BLA::Matrix<2, 1, int> theta) {
  double theta_shoulder = theta(0) / (double) (4 * FULL_ROTATION);
  double theta_elbow = theta(1) / (double) (3 * FULL_ROTATION);
  double x = cos(theta_shoulder) + cos(theta_shoulder + theta_elbow);
  double y = sin(theta_shoulder) + sin(theta_shoulder + theta_elbow);
  return {x, y};
}

double norm(BLA::Matrix<2> vec) {
  BLA::Matrix<1> result = ~vec * vec;
  return result(0);
}

BLA::Matrix<2, 1, int> moveTo(BLA::Matrix<2, 1, int>& current_theta, BLA::Matrix<2>& goal_pos) {
  BLA::Matrix<2> initial_pos = theta2pos(current_theta);
  BLA::Matrix<2> current_pos = theta2pos(current_theta);
  BLA::Matrix<2, 1, int> directions[] = {{1, 0}, {0, 1}, {-1, 0}, {0, -1}};
  double highest_alignment;
  BLA::Matrix<2, 1, int> best_direction;

  auto alignment_with_goal = [&](const BLA::Matrix<2, 1, int> delta) {
    BLA::Matrix<2> diff_current = goal_pos - current_pos;
    BLA::Matrix<2> diff_new = goal_pos - theta2pos(current_theta + delta);
    BLA::Matrix<1> inner_prod = ~diff_current * diff_new;
    return (inner_prod(0)) / norm(diff_current) / norm(diff_new);
  };

  auto distance_from_straight = [&](const BLA::Matrix<2, 1, int> delta) {
    BLA::Matrix<2> new_pos = theta2pos(current_theta + delta);
    return (
      (goal_pos(0) - initial_pos(0)) * (goal_pos(1) - new_pos(1))
      - (goal_pos(1) - initial_pos(1)) * (goal_pos(0) - new_pos(0))
    );
  };

  while (norm(current_pos - goal_pos) > 1e-5) {
    Serial.print("current_theta=");
    Serial.print(current_theta(0));
    Serial.print(",");
    Serial.print(current_theta(1));
    Serial.println();
    delay(100);
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

    rotateMotor(best_direction(0), best_direction(1), 500);
    current_theta = current_theta + best_direction;
    current_pos = theta2pos(current_theta);
  }

  return current_theta;
}

void loop()
{
  BLA::Matrix<2, 1, int> current_theta = {0, FULL_ROTATION/4};
  BLA::Matrix<2> goal_pos = theta2pos({-500, FULL_ROTATION/4 + 500});
  current_theta = moveTo(current_theta, goal_pos);
  delay(10000);
//  //make steps
//  Serial.println("Start rotation");
//  rotateMotor(FULL_ROTATION * 4, 0, 500);
//  delay(1000);
//  rotateMotor(-FULL_ROTATION * 4, 0, 500);
//  delay(1000);
//  rotateMotor(0, FULL_ROTATION * 3, 500);
//  delay(1000);
//  rotateMotor(0, -FULL_ROTATION * 3, 500);
//  delay(1000);
//
//  delay(2000);
}
