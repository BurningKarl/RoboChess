import 'dart:convert';

enum Direction {
  up,
  down,
}

class ChessboardEvent {
  Direction direction;
  String square;

  ChessboardEvent(this.direction, this.square);

  String toJson() {
    return jsonEncode({"direction": direction.name, "square": square});
  }

  // TODO: Add fromJson
}
