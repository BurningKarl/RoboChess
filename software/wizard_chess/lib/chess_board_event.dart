import 'dart:convert';

enum Direction {
  up,
  down,
}

class ChessBoardEvent {
  Direction direction;
  String square;

  ChessBoardEvent({required this.direction, required this.square});

  String toJson() {
    return jsonEncode({"direction": direction.name, "square": square});
  }

  static ChessBoardEvent fromJson(Map<String, dynamic> data) {
    return ChessBoardEvent(
      direction: Direction.values.byName(data['direction']!),
      square: data['square']!,
    );
  }
}
