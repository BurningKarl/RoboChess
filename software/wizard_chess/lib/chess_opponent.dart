import 'package:flutter_chess_board/flutter_chess_board.dart';

class IllegalMoveException implements Exception {}

abstract class ChessOpponent {
  Future<Move> calculateMove(final Chess gameState);
}

class RandomChessOpponent implements ChessOpponent {
  @override
  Future<Move> calculateMove(final Chess gameState) async {
    // Dummy implementation, ask computer or human opponent
    var legalMoves = gameState.generate_moves();
    legalMoves.shuffle();
    await Future.delayed(const Duration(seconds: 1));
    return legalMoves.first;
  }
}
