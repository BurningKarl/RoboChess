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

  static ChessBoardEvent fromJson(Map<String, String> data) {
    return ChessBoardEvent(
      Direction.values.byName(data['direction']!),
      data['square']!,
    );
  }
}
