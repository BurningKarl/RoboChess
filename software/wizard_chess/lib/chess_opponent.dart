import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wizard_chess/chess_logic.dart';
import 'package:wizard_chess/lichess.dart';
import 'package:wizard_chess/settings_screen.dart';

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

class LichessOpponent implements ChessOpponent {
  LichessClient client;
  String gameId;
  Stream<dynamic>? gameStateStream;

  LichessOpponent({required this.client, required this.gameId}) {
    client.streamBoardGameState(gameId: gameId).then((stream) {
      gameStateStream = stream;
    });
  }

  static Future<LichessOpponent> connect() async {
    var preferences = await SharedPreferences.getInstance();
    LichessClient client = LichessClient(
        authorizationCode:
            preferences.getString(SettingsKeys.lichessApiKey) ?? "");
    String gameId = (await client.challengeAi())['id'];
    return LichessOpponent(client: client, gameId: gameId);
  }

  @override
  Future<Move> calculateMove(final Chess gameState) async {
    // That's kinda hacky at the moment, refactor!
    Move lastMove = gameState.undo_move()!;
    print(lastMove.toJson());
    gameState.make_move(lastMove);
    client.makeBoardMove(gameId: gameId, move: lastMove);

    dynamic stateAfterMove = await gameStateStream!.firstWhere((event) =>
        event['type'] == 'gameState' &&
        event['moves'].split(' ').length % 2 == 0);
    String uciMove = (stateAfterMove['moves'] as String).split(' ').last;
    print("uciMove: $uciMove");
    return gameState.generate_moves().firstWhere((move) =>
        move.fromAlgebraic == uciMove.substring(0, 2) &&
        move.toAlgebraic == uciMove.substring(2, 4) &&
        (uciMove.length == 4 ||
            (move.promotion?.name ?? "") == uciMove.substring(4, 5)));
  }
}
