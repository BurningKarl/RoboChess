import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:wizard_chess/robo_chess_board_event.dart';

Move? extractMove(final Chess gameState, final List<RoboChessBoardEvent> events) {
  // TODO: Implement Sam's logic
  var legalMoves = gameState.generate_moves();
  legalMoves.shuffle();
  return legalMoves.first; // or return null;
}
