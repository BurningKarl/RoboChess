import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';

// Reimplement ChessBoardController, because the original class cannot be subclassed
class InternalChessBoardController extends ValueNotifier<Chess>
    implements ChessBoardController {
  @override
  Chess game;

  InternalChessBoardController(this.game) : super(game);

  // New functions
  bool makeMoveFromObject(Move move) {
    bool isLegalMove = game.move(move);
    notifyListeners();
    return isLegalMove;
  }

  // Old functions to make `implements ChessBoardController` work
  /// Makes move on the board
  @override
  void makeMove({required String from, required String to}) {
    game.move({"from": from, "to": to});
    notifyListeners();
  }

  /// Makes move and promotes pawn to piece (from is a square like d4, to is also a square like e3, pieceToPromoteTo is a String like "Q".
  /// pieceToPromoteTo String will be changed to enum in a future update and this method will be deprecated in the future
  @override
  void makeMoveWithPromotion(
      {required String from,
        required String to,
        required String pieceToPromoteTo}) {
    game.move({"from": from, "to": to, "promotion": pieceToPromoteTo});
    notifyListeners();
  }

  /// Makes move on the board
  @override
  void makeMoveWithNormalNotation(String move) {
    game.move(move);
    notifyListeners();
  }

  @override
  void undoMove() {
    if (game.half_moves == 0) {
      return;
    }
    game.undo_move();
    notifyListeners();
  }

  @override
  void resetBoard() {
    game.reset();
    notifyListeners();
  }

  /// Clears board
  @override
  void clearBoard() {
    game.clear();
    notifyListeners();
  }

  /// Puts piece on a square
  @override
  void putPiece(BoardPieceType piece, String square, PlayerColor color) {
    game.put(_getPiece(piece, color), square);
    notifyListeners();
  }

  /// Loads a PGN
  @override
  void loadPGN(String pgn) {
    game.load_pgn(pgn);
    notifyListeners();
  }

  /// Loads a PGN
  @override
  void loadFen(String fen) {
    game.load(fen);
    notifyListeners();
  }

  @override
  bool isInCheck() {
    return game.in_check;
  }

  @override
  bool isCheckMate() {
    return game.in_checkmate;
  }

  @override
  bool isDraw() {
    return game.in_draw;
  }

  @override
  bool isStaleMate() {
    return game.in_stalemate;
  }

  @override
  bool isThreefoldRepetition() {
    return game.in_threefold_repetition;
  }

  @override
  bool isInsufficientMaterial() {
    return game.insufficient_material;
  }

  @override
  bool isGameOver() {
    return game.game_over;
  }

  @override
  String getAscii() {
    return game.ascii;
  }

  @override
  String getFen() {
    return game.fen;
  }

  @override
  List<String?> getSan() {
    return game.san_moves();
  }

  @override
  List<Piece?> getBoard() {
    return game.board;
  }

  @override
  List<Move> getPossibleMoves() {
    return game.moves({'asObjects': true}) as List<Move>;
  }

  @override
  int getMoveCount() {
    return game.move_number;
  }

  @override
  int getHalfMoveCount() {
    return game.half_moves;
  }

  /// Gets respective piece
  Piece _getPiece(BoardPieceType piece, PlayerColor color) {
    var convertedColor = color == PlayerColor.white ? Color.WHITE : Color.BLACK;

    switch (piece) {
      case BoardPieceType.Bishop:
        return Piece(PieceType.BISHOP, convertedColor);
      case BoardPieceType.Queen:
        return Piece(PieceType.QUEEN, convertedColor);
      case BoardPieceType.King:
        return Piece(PieceType.KING, convertedColor);
      case BoardPieceType.Knight:
        return Piece(PieceType.KNIGHT, convertedColor);
      case BoardPieceType.Pawn:
        return Piece(PieceType.PAWN, convertedColor);
      case BoardPieceType.Rook:
        return Piece(PieceType.ROOK, convertedColor);
    }
  }
}
