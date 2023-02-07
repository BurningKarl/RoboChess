import 'dart:convert';

enum Direction {
  up,
  down,
}

class ChessBoardEvent {
  Direction direction;
  String square;

  ChessBoardEvent(this.direction, this.square);

  String toJson() {
    return jsonEncode({"direction": direction.name, "square": square});
  }

  // TODO: Add fromJson
}
