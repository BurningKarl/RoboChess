import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:wizard_chess/bluetooth_connection_model.dart';

class RoboMoveUnsuccessfulException implements Exception {}

class RoboChessBoardController {
  BluetoothConnectionModel bluetooth;

  RoboChessBoardController({required this.bluetooth});

  Future<void> makeMove(Move move) async {
    // TODO: Instruct board to execute the move
    // wait for response that the move has been executed successfully
    // raise an error if the move was not completed successfully
    // or after, say, a minute of no response from the board
  }
}
