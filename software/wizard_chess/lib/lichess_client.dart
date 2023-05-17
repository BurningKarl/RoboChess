import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:wizard_chess/ndjson.dart';

class LichessClient {
  final Dio _dio = Dio();
  final String authorizationCode;
  final CancelToken streamCancelToken = CancelToken();

  LichessClient({required this.authorizationCode}) {
    _dio.options.headers.addAll({'Authorization': 'Bearer $authorizationCode'});
    _dio.options.baseUrl = "https://lichess.org/api";
    _dio.options.connectTimeout = const Duration(seconds: 20);
  }

  Future<List<dynamic>> getOngoingGames() async {
    var response = await _dio.get('/account/playing', data: {'nb': 50});
    return response.data['nowPlaying'];
  }

  Future<dynamic> challengeAi() async {
    var response =
        await _dio.post('/challenge/ai', data: {'level': 1, 'color': 'white'});
    return response.data;
  }

  Future<Stream<dynamic>> streamBoardGameState({required String gameId}) async {
    var response = await _dio.get('/board/game/stream/$gameId',
        options: Options(responseType: ResponseType.stream),
        cancelToken: streamCancelToken);

    return (response.data.stream as Stream<Uint8List>)
        .toJsonStream()
        .handleError(
      (error) {
        // The stream was canceled by the cancel token, ignore the error
      },
      test: (error) => error is HttpException,
    );
  }

  Future<void> makeBoardMove(
      {required String gameId, required Move move}) async {
    String uciMove =
        move.fromAlgebraic + move.toAlgebraic + (move.promotion?.name ?? "");
    print("uciMove: $uciMove");
    var response = await _dio.post('/board/game/$gameId/move/$uciMove');
    assert(response.data['ok']);
  }

  void close() {
    streamCancelToken.cancel();
    _dio.close();
  }
}
