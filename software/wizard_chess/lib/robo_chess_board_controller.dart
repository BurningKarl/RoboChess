import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:wizard_chess/bluetooth_connection_model.dart';
import 'package:uuid/uuid.dart';

class RoboMoveUnsuccessfulException implements Exception {}

class RoboChessBoardController {
  BluetoothConnectionModel bluetooth;
  final Uuid _uuid = const Uuid();

  RoboChessBoardController({required this.bluetooth});

  Future<void> makeMove(Move move) async {
    print("RoboChessBoardController.makeMove");

    var uniqueId = _uuid.v4();
    // TODO: Extend to a list of moves and handle capturing, castling, etc.
    String message = jsonEncode({
      'version': 1,
      'type': 'move',
      'id': uniqueId,
      'move': {
        'from': move.from,
        'to': move.to,
        'flags': move.flags,
      }
    });

    bluetooth.connection!.output
        .add(Uint8List.fromList(utf8.encode('$message\n')));
    var response = await bluetooth.messageQueue.stream
        .firstWhere((element) =>
            element['type'] == 'response' && element['id'] == uniqueId)
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () => {'moveSuccessful': false},
        );

    if (response['moveSuccessful']) {
      return;
    } else {
      throw RoboMoveUnsuccessfulException();
    }
  }
}
