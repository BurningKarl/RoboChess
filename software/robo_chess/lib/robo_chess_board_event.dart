import 'dart:convert';

enum Direction {
  up,
  down,
}

class RoboChessBoardEvent {
  Direction direction;
  int square;

  RoboChessBoardEvent({required this.direction, required this.square});

  String toJson() {
    return jsonEncode({"direction": direction.name, "square": square});
  }

  factory RoboChessBoardEvent.fromJson(Map<String, dynamic> data) {
    return RoboChessBoardEvent(
      direction: Direction.values.byName(data['direction']!),
      square: data['square']!,
    );
  }
}
