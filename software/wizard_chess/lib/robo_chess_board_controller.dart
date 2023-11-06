import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:wizard_chess/bluetooth_connection_model.dart';

class RoboMoveUnsuccessfulException implements Exception {}

class NoBluetoothConnection implements Exception {}

class GridPosition {
  final int x;
  final int y;

  const GridPosition({this.x = 0, this.y = 0});

  factory GridPosition.fromSquare(int square) {
    var file = Chess.file(square);
    var rank = Chess.rank(square);
    return GridPosition(x: file * 2 + 1, y: 15 - 2 * rank);
  }

  GridPosition operator +(GridPosition other) {
    return GridPosition(x: x + other.x, y: y + other.y);
  }

  GridPosition operator -(GridPosition other) {
    return GridPosition(x: x - other.x, y: y - other.y);
  }

  GridPosition operator *(int scale) {
    return GridPosition(x: scale * x, y: scale * y);
  }

  GridPosition where({int? x, int? y}) {
    if (x != null && y != null) {
      return GridPosition(x: x, y: y);
    } else if (x != null) {
      return GridPosition(x: x, y: this.y);
    } else if (y != null) {
      return GridPosition(x: this.x, y: y);
    } else {
      return this;
    }
  }
}

enum BoardCommandType {
  magnetOn,
  magnetOff,
  goto,
}

class BoardCommand {
  final BoardCommandType type;
  final GridPosition position;

  BoardCommand._({required this.type, this.position = const GridPosition()});

  factory BoardCommand.magnetOn() {
    return BoardCommand._(type: BoardCommandType.magnetOn);
  }

  factory BoardCommand.magnetOff() {
    return BoardCommand._(type: BoardCommandType.magnetOff);
  }

  factory BoardCommand.goto(GridPosition position) {
    return BoardCommand._(type: BoardCommandType.goto, position: position);
  }

  dynamic asJson() {
    switch (type) {
      case BoardCommandType.magnetOn:
        return "on";
      case BoardCommandType.magnetOff:
        return "off";
      case BoardCommandType.goto:
        return [position.x, position.y];
    }
  }
}

class RoboChessBoardController {
  BluetoothConnectionModel bluetooth;

  RoboChessBoardController({required this.bluetooth});

  List<BoardCommand> regularMoveCommands(
      int fromSquare, int toSquare, PieceType piece) {
    final GridPosition fromPosition = GridPosition.fromSquare(fromSquare);
    final GridPosition toPosition = GridPosition.fromSquare(toSquare);
    if (piece == PieceType.KNIGHT) {
      // Move in between the other pieces, since the knight can jump
      GridPosition offset = toPosition - fromPosition;
      GridPosition halfStep;
      if (offset.x.abs() > offset.y.abs()) {
        halfStep = GridPosition(x: 0, y: 1 * offset.y.sign);
      } else {
        halfStep = GridPosition(x: 1 * offset.x.sign, y: 0);
      }
      return [
        BoardCommand.magnetOff(),
        BoardCommand.goto(fromPosition),
        BoardCommand.magnetOn(),
        BoardCommand.goto(fromPosition + halfStep),
        BoardCommand.goto(toPosition - halfStep),
        BoardCommand.goto(toPosition),
        BoardCommand.magnetOff(),
      ];
    } else {
      // Move the piece in a straight line, there cannot be any obstacle
      return [
        BoardCommand.magnetOff(),
        BoardCommand.goto(fromPosition),
        BoardCommand.magnetOn(),
        BoardCommand.goto(toPosition),
        BoardCommand.magnetOff(),
      ];
    }
  }

  GridPosition pieceStoragePosition(Chess game, PieceType pieceType) {
    // Captured pieces of the enemy always go to the right edge
    int x = game.turn == Color.WHITE ? 19 : -3;

    // The pieces are ordered by importance. The first 8 spaces are reserved for
    // pawns, the next two for knights, and so on. Each captured piece is moved
    // to first empty spot in the assigned region.
    int y = {
      PieceType.PAWN: 1,
      PieceType.KNIGHT: 9,
      PieceType.BISHOP: 11,
      PieceType.ROOK: 13,
      PieceType.QUEEN: 15,
    }[pieceType]!;
    y += game.history.where((state) => state.move.captured == pieceType).length;

    return GridPosition(x: x, y: y);
  }

  List<BoardCommand> capturedPieceCommands(
      Chess game, int square, PieceType pieceType) {
    // Move the piece in between the other pieces to the edge and then move it
    // to its appropriate location in the importance ranking explained above.
    final GridPosition fromPosition = GridPosition.fromSquare(square);
    final GridPosition toPosition = pieceStoragePosition(game, pieceType);
    GridPosition offset = toPosition - fromPosition;
    GridPosition halfStep = offset.y >= 0
        ? const GridPosition(x: 0, y: 1)
        : const GridPosition(x: 0, y: -1);
    int bufferX = offset.x < 0 ? toPosition.x + 1 : toPosition.x - 1;

    return [
      BoardCommand.magnetOff(),
      BoardCommand.goto(fromPosition),
      BoardCommand.magnetOn(),
      BoardCommand.goto(fromPosition + halfStep),
      BoardCommand.goto((fromPosition + halfStep).where(x: bufferX)),
      BoardCommand.goto(toPosition.where(x: bufferX)),
      BoardCommand.goto(toPosition),
      // BoardCommand.magnetOff(),
    ];
  }

  List<BoardCommand> castlingCommands(int fromSquare, int toSquare) {
    final GridPosition fromPosition = GridPosition.fromSquare(fromSquare);
    final GridPosition toPosition = GridPosition.fromSquare(toSquare);

    GridPosition offset = toPosition - fromPosition;
    GridPosition oneSquareRight = const GridPosition(x: 2, y: 0);
    GridPosition halfStep = GridPosition(x: 0, y: toPosition.y > 4 ? 1 : -1);
    GridPosition rookFromPosition, rookToPosition;
    if (offset.x > 0) {
      // Kingside castling
      rookFromPosition = toPosition + oneSquareRight;
      rookToPosition = toPosition - oneSquareRight;
    } else {
      rookFromPosition = toPosition - oneSquareRight * 2;
      rookToPosition = toPosition + oneSquareRight;
    }

    return [
      BoardCommand.magnetOff(),
      BoardCommand.goto(fromPosition),
      BoardCommand.magnetOn(),
      BoardCommand.goto(toPosition),
      BoardCommand.magnetOff(),
      BoardCommand.goto(rookFromPosition),
      BoardCommand.magnetOn(),
      BoardCommand.goto(rookFromPosition + halfStep),
      BoardCommand.goto(rookToPosition + halfStep),
      BoardCommand.goto(rookToPosition),
      BoardCommand.magnetOff(),
    ];
  }

  List<BoardCommand> moveCommands(Chess game, Move move) {
    if (move.flags & (Chess.BITS_KSIDE_CASTLE | Chess.BITS_QSIDE_CASTLE) != 0) {
      return castlingCommands(move.from, move.to);
    } else if (move.flags & Chess.BITS_PROMOTION != 0) {
      throw RoboMoveUnsuccessfulException();
      // TODO: Properly handle this case
    } else {
      List<BoardCommand> commands = [];
      if (move.flags & Chess.BITS_CAPTURE != 0) {
        commands += capturedPieceCommands(game, move.to, move.captured!);
      }
      commands += regularMoveCommands(move.from, move.to, move.piece);
      return commands;
    }
  }

  Future<dynamic> bluetoothRequest(Map<String, dynamic> data) async {
    // 36^5 = 60466176, so we generate 5 random characters 0-9a-z
    var uniqueId = Random().nextInt(60466176).toRadixString(36);

    var request = {
      'version': 1,
      'id': uniqueId,
      ...data,
    };
    String message = jsonEncode(request);

    if (bluetooth.connection == null) {
      throw NoBluetoothConnection();
    } else {
      bluetooth.connection!.output
          .add(Uint8List.fromList(utf8.encode('$message\n')));
      var response = await bluetooth.messageQueue.stream
          .firstWhere((element) =>
              element['type'] == 'response' && element['id'] == uniqueId)
          .timeout(const Duration(seconds: 2));
      return response;
    }
  }

  Future<void> makeMove(Chess game, Move move) async {
    print("RoboChessBoardController.makeMove");

    var commands = moveCommands(game, move);
    var response = await bluetoothRequest({
      'type': 'move',
      'commands': commands.map((c) => c.asJson()).toList(),
    });

    if (response['moveSuccessful']) {
      return;
    } else {
      throw RoboMoveUnsuccessfulException();
    }
  }

  Future<List<int>> requestOccupiedSquares() async {
    print("RoboChessBoardController.requestOccupiedSquares");

    var response = await bluetoothRequest({'type': 'occupied'});

    return (response['occupied'] as List<dynamic>)
        .map((square) => square as int)
        .toList();
  }
}
