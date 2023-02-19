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

Move? extractMove(
  final Chess gameState,
  final List<RoboChessBoardEvent> events,
) {
  List<int> squareOccupiedBeforeMove = List.filled(128, 0);
  for (var square in gameState.board.asMap().entries) {
    squareOccupiedBeforeMove[square.key] = square.value == null ? 0 : 1;
  }

  List<int> squareOccupiedAfterMove = List.of(squareOccupiedBeforeMove);
  for (var event in events) {
    switch (event.direction) {
      case Direction.up:
        squareOccupiedAfterMove[event.square] = 0;
        break;
      case Direction.down:
        squareOccupiedAfterMove[event.square] = 1;
        break;
    }
  }

  List<int> squareOccupiedDifference = [
    for (int i = 0; i < squareOccupiedBeforeMove.length; i++)
      squareOccupiedAfterMove[i] - squareOccupiedBeforeMove[i]
  ];
  print("squareOccupiedDifference: $squareOccupiedDifference");

  int differenceTotal = squareOccupiedDifference.reduce((a, b) => a + b);
  int changesCount = squareOccupiedDifference.reduce((a, b) => a + b.abs());
  print("differenceTotal: $differenceTotal");
  print("changesCount: $changesCount");

  var legalMoves = gameState.generate_moves();
  if (differenceTotal == 0) {
    // Regular move
    if (changesCount == 4) {
      // Castling
      int flag = -1;
      for (var rookPosition in Chess.ROOKS[gameState.turn]!) {
        if (squareOccupiedDifference[rookPosition['square']] == -1) {
          flag = rookPosition['flag'];
        }
      }
      Move castlingMove;
      try {
        castlingMove =
            legalMoves.firstWhere((move) => (move.flags & flag) != 0);
      } on StateError {
        return null;
      }
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
      if (squareOccupiedDifference[castlingMove.from] == -1 &&
          squareOccupiedDifference[castlingMove.to] == 1 &&
          squareOccupiedDifference[rookFrom] == -1 &&
          squareOccupiedDifference[rookTo] == 1) {
        return castlingMove;
      } else {
        return null;
      }
    } else if (changesCount == 2) {
      var from =
          squareOccupiedDifference.indexWhere((element) => element == -1);
      var to = squareOccupiedDifference.indexWhere((element) => element == 1);

      print("from: $from, to: $to");
      try {
        return legalMoves
            .firstWhere((move) => move.from == from && move.to == to);
      } on StateError {
        return null;
      }
    } else {
      return null;
    }
  } else if (differenceTotal == -1) {
    // Capturing move
    if (changesCount == 3) {
      // En passant
      for (var enPassantMove in legalMoves
          .where((move) => (move.flags & Chess.BITS_EP_CAPTURE) != 0)) {
        var opponentSquare = 127;
        if (gameState.turn == Chess.BLACK) {
          opponentSquare = enPassantMove.to - 16;
        } else {
          opponentSquare = enPassantMove.to + 16;
        }
        if (squareOccupiedDifference[enPassantMove.from] == -1 &&
            squareOccupiedDifference[enPassantMove.to] == 1 &&
            squareOccupiedDifference[opponentSquare] == -1) {
          return enPassantMove;
        }
      }
      return null;
    } else if (changesCount == 1) {
      // Regular capturing move
      var from =
          squareOccupiedDifference.indexWhere((element) => element == -1);

      try {
        // TODO: Promotion while taking
        return legalMoves.firstWhere(
            (move) => move.from == from && move.to == events.last.square);
      } on StateError {
        return null;
      }
    }
  } else {
    return null;
  }
}
