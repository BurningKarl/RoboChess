import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart' hide Color;
import 'package:flutter_chess_board/flutter_chess_board.dart' as flutter_chess;

class MovesTable extends StatefulWidget {
  final ChessBoardController controller;
  final Color rowNormalColor;
  final Color rowAccentColor;
  final TextStyle? headerStyle;
  final flutter_chess.Color playerColor;
  final String playerName;
  final String opponentName;

  const MovesTable(
      {Key? key,
      required this.controller,
      required this.rowNormalColor,
      required this.rowAccentColor,
      this.headerStyle,
      required this.playerColor,
      this.playerName = "You",
      required this.opponentName})
      : super(key: key);

  @override
  State<MovesTable> createState() => _MovesTableState();
}

class _MovesTableState extends State<MovesTable> {
  TableRow makeRow(List<String?> gameHistory, int rowIndex) {
    Color backgroundColor =
        rowIndex % 2 == 0 ? widget.rowAccentColor : widget.rowNormalColor;
    TextStyle? textStyle = rowIndex < 0 ? widget.headerStyle : null;

    List<String> content = [];
    if (rowIndex < 0) {
      // Header
      if (widget.playerColor == flutter_chess.Color.WHITE) {
        content = ["", widget.playerName, widget.opponentName];
      } else {
        content = ["", widget.opponentName, widget.playerName];
      }
    } else {
      String sanMoves = gameHistory.asMap()[rowIndex] ?? "${rowIndex + 1}.  ";
      content = ("$sanMoves ").split(" ").sublist(0, 3);
    }

    return TableRow(
        children: content
            .asMap()
            .map((columnIndex, cell) => MapEntry(
                columnIndex,
                Container(
                    color: backgroundColor,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4.0,
                        vertical: 2.0,
                      ),
                      child: Text(
                        cell,
                        textAlign: columnIndex == 0 ? TextAlign.center : null,
                        style: textStyle,
                      ),
                    ))))
            .values
            .toList());
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: widget.controller,
        builder: (context, game, _) {
          List<String?> gameHistory = game.san_moves();
          return Table(
            columnWidths: const <int, TableColumnWidth>{
              0: FixedColumnWidth(40.0),
              1: FlexColumnWidth(),
              2: FlexColumnWidth(),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: Iterable.generate(
              gameHistory.length + 1,
              (index) => makeRow(gameHistory, index - 1),
            ).toList(),
          );
        });
  }
}
