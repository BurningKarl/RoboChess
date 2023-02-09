import 'dart:convert';

enum Direction {
  up,
  down,
}

class RoboChessBoardEvent {
  Direction direction;
  String square;

  RoboChessBoardEvent({required this.direction, required this.square});

  String toJson() {
    return jsonEncode({"direction": direction.name, "square": square});
  }

  static RoboChessBoardEvent fromJson(Map<String, dynamic> data) {
    return RoboChessBoardEvent(
      direction: Direction.values.byName(data['direction']!),
      square: data['square']!,
    );
  }
}