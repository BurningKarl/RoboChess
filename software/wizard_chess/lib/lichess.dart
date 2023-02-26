import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:wizard_chess/ndjson.dart';

class LichessClient {
  final Dio _dio = Dio();

  LichessClient({required String authorizationCode}) {
    _dio.options.headers.addAll({'Authorization': 'Bearer $authorizationCode'});
    _dio.options.baseUrl = "https://lichess.org/api";
  }

  Future<dynamic> challengeAi() async {
    var response =
        await _dio.post('/challenge/ai', data: {'level': 1, 'color': 'white'});
    return response.data;
  }

  Future<Stream<dynamic>> streamBoardGameState({required String gameId}) async {
    var response = await _dio.get('/board/game/stream/$gameId',
        options: Options(responseType: ResponseType.stream));

    return (response.data.stream as Stream<Uint8List>).toJsonStream().asBroadcastStream();
  }

  Future<void> makeBoardMove(
      {required String gameId, required Move move}) async {
    String uciMove =
        move.fromAlgebraic + move.toAlgebraic + (move.promotion?.name ?? "");
    print("uciMove: $uciMove");
    var response = await _dio.post('/board/game/$gameId/move/$uciMove');
    assert (response.data['ok']);
  }
}
