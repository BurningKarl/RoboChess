import 'dart:convert';

import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:wizard_chess/robo_chess_board_event.dart';

extension MoveWithJson on Move {
  String toJson() {
    return jsonEncode({
      "color": color.toString(),
      "from": fromAlgebraic,
      "to": toAlgebraic,
      "flags": flags,
      "piece": piece.toString(),
      "captured": captured.toString(),
      "promotion": promotion.toString(),
    });
  }
}

List<Move> extractCompatibleMoves(
  final Chess gameState,
  final List<RoboChessBoardEvent> events,
) {
  List<int> previousBoard = List.filled(128, 0);
  for (var square in gameState.board.asMap().entries) {
    previousBoard[square.key] = square.value == null ? 0 : 1;
  }

  List<RoboChessBoardEvent> relevantEvents = List.empty(growable: true);
  List<int> currentBoard = List.of(previousBoard);
  for (var event in events) {
    switch (event.direction) {
      case Direction.up:
        currentBoard[event.square] = 0;
        break;
      case Direction.down:
        currentBoard[event.square] = 1;
        break;
    }
    relevantEvents.add(event);
    if (currentBoard == previousBoard) {
      relevantEvents.clear();
    }
  }

  List<int> boardDifference = [
    for (int i = 0; i < previousBoard.length; i++)
      currentBoard[i] - previousBoard[i]
  ];
  print("boardDifference: $boardDifference");

  int differenceTotal = boardDifference.reduce((a, b) => a + b);
  int changesCount = boardDifference.reduce((a, b) => a.abs() + b.abs());
  print("differenceTotal: $differenceTotal");
  print("changesCount: $changesCount");

  var legalMoves = gameState.generate_moves();
  if (differenceTotal == 0) {
    // Regular move
    if (changesCount == 4) {
      // Castling
      int flag = Chess.ROOKS[gameState.turn]!.singleWhere(
          (rook) => boardDifference[rook['square']] == -1,
          orElse: () => {'flag': -1})['flag'];

      return legalMoves
          .where((move) => (move.flags & flag) != 0)
          .where((castlingMove) {
        int rookFrom = 127, rookTo = 127;
        if (flag == Chess.BITS_KSIDE_CASTLE) {
          rookFrom = castlingMove.to + 1;
          rookTo = castlingMove.to - 1;
        } else if (flag == Chess.BITS_QSIDE_CASTLE) {
          rookFrom = castlingMove.to - 2;
          rookTo = castlingMove.to + 1;
        }

        // Limitation: If someone does a castling move but swaps the final squares
        // of rook and king, we are unable to detect this
        return boardDifference[castlingMove.from] == -1 &&
            boardDifference[castlingMove.to] == 1 &&
            boardDifference[rookFrom] == -1 &&
            boardDifference[rookTo] == 1;
      }).toList();
    } else if (changesCount == 2) {
      var from = boardDifference.indexWhere((element) => element == -1);
      var to = boardDifference.indexWhere((element) => element == 1);
      print("from: $from, to: $to");

      return legalMoves
          .where((move) => move.from == from && move.to == to)
          .toList();
    } else {
      return List.empty();
    }
  } else if (differenceTotal == -1) {
    // Capturing move
    if (changesCount == 3) {
      // En passant
      return legalMoves
          .where((move) => (move.flags & Chess.BITS_EP_CAPTURE) != 0)
          .where((enPassantMove) {
        var opponentSquare = 127;
        if (gameState.turn == Chess.BLACK) {
          opponentSquare = enPassantMove.to - 16;
        } else {
          opponentSquare = enPassantMove.to + 16;
        }

        return boardDifference[enPassantMove.from] == -1 &&
            boardDifference[enPassantMove.to] == 1 &&
            boardDifference[opponentSquare] == -1;
      }).toList();
    } else if (changesCount == 1) {
      // Regular capturing move
      var from = boardDifference.indexWhere((element) => element == -1);
      var putDownSquares = relevantEvents
          .where((event) => event.direction == Direction.down)
          .map((event) => event.square)
          .toList();

      return legalMoves
          .where((move) => move.from == from)
          .where((move) => putDownSquares.contains(move.to))
          .toList();
    } else {
      return List.empty();
    }
  } else {
    return List.empty();
  }
}
