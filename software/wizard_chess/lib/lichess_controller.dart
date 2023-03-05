import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:wizard_chess/lichess_client.dart';

class LichessMove {
  String from;
  String to;
  String? promotion;

  LichessMove({required this.from, required this.to, required this.promotion});

  factory LichessMove.fromUci(String uciMove) {
    return LichessMove(
        from: uciMove.substring(0, 2),
        to: uciMove.substring(2, 4),
        promotion: uciMove.length > 4 ? uciMove.substring(4, 5) : null);
  }

  bool compatibleWith(Move move) {
    return from == move.fromAlgebraic &&
        to == move.toAlgebraic &&
        (promotion == null || promotion == move.promotion?.name);
  }
}

class LichessController extends ChangeNotifier {
  LichessClient client;
  String gameId;
  List<LichessMove> moves = [];

  LichessController({required this.client, required this.gameId}) {
    client.streamBoardGameState(gameId: gameId).then((stream) {
      stream.listen(onBoardGameStateChanged, cancelOnError: true);
      // TODO: Add an onError handler to catch network errors
      // We should inform the user and provide a popup with a reconnect button
    });
  }

  void onBoardGameStateChanged(dynamic event) {
    if (event['type'] == 'gameState') {
      moves = (event['moves'] as String)
          .split(' ')
          .map(LichessMove.fromUci)
          .toList();
      notifyListeners();
    }
  }

  void makeMove(Move move) {
    client.makeBoardMove(gameId: gameId, move: move);
  }
}
