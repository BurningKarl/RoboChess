import 'dart:typed_data';

import 'package:dio/dio.dart';
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
    return response.data.json;
  }

  Future<Stream<dynamic>> streamBoardGameState(String gameId) async {
    var response = await _dio.get('/board/game/stream/$gameId',
        options: Options(responseType: ResponseType.stream));

    return (response.data.stream as Stream<Uint8List>).toJsonStream();
  }
}
