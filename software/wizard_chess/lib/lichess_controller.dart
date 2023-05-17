import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:wizard_chess/lichess_client.dart';

class LichessMove {
  String from;
  String to;
  String? promotion;

  LichessMove({required this.from, required this.to, required this.promotion});

  factory LichessMove.fromUci(String uciMove) {
    print("uciMove: $uciMove of length ${uciMove.length}");
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
  late LichessClient client;
  String gameId;
  List<LichessMove> moves = [];
  void Function() onInitialized;
  void Function(Object) onError;

  LichessController(
      {required String authorizationCode,
      required this.gameId,
      required this.onInitialized,
      required this.onError}) {
    client = LichessClient(authorizationCode: authorizationCode);
    client.streamBoardGameState(gameId: gameId).then((stream) {
      stream.listen(onBoardGameStateChanged, cancelOnError: true);
    }).catchError((error) async {
      onError(error);
    });
  }

  void onBoardGameStateChanged(dynamic event) {
    if (event['type'] == 'gameState') {
      moves = (event['moves'] as String)
          .split(' ')
          .map(LichessMove.fromUci)
          .toList();
      notifyListeners();
    } else if (event['type'] == 'gameFull') {
      String movesString = (event['state']['moves'] as String).trim();
      if (movesString.isEmpty) {
        moves = [];
      } else {
        moves = movesString.split(' ').map(LichessMove.fromUci).toList();
      }
      onInitialized();
    }
  }

  void makeMove(Move move) {
    try {
      client.makeBoardMove(gameId: gameId, move: move);
    } catch (error) {
      onError(error);
    }
  }

  @override
  void dispose() {
    client.close();

    super.dispose();
  }
}
