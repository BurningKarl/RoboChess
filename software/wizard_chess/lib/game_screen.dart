import 'dart:async';

import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart' hide Color;
import 'package:flutter_chess_board/flutter_chess_board.dart' as flutter_chess;
import 'package:wizard_chess/bluetooth_connection_model.dart';
import 'package:wizard_chess/bluetooth_connection_widget.dart';
import 'package:wizard_chess/internal_chess_board_controller.dart';
import 'package:wizard_chess/moves_table.dart';
import 'package:wizard_chess/robo_chess_board_event.dart';
import 'package:wizard_chess/robo_chess_board_controller.dart';
import 'package:wizard_chess/lichess_client.dart';
import 'package:wizard_chess/lichess_controller.dart';
import 'package:wizard_chess/chess_logic.dart';

class GameScreen extends StatefulWidget {
  final LichessClient lichessClient;
  final String gameId;
  final flutter_chess.Color playerColor;
  final String opponentName;
  const GameScreen(
      {Key? key,
      required this.lichessClient,
      required this.gameId,
      required this.playerColor,
      required this.opponentName})
      : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool receiveEvents = false;
  List<RoboChessBoardEvent> eventHistory = [];
  InternalChessBoardController internalController =
      InternalChessBoardController(Chess());
  late RoboChessBoardController roboController;
  late LichessController lichessController;

  String errorMessage = "";
  String errorButtonText = "DONE";
  Completer<void>? errorCompleter;

  Future<void> showErrorMessage(String message, String buttonText) {
    Completer<void> completer = Completer();
    setState(() {
      errorMessage = message;
      errorButtonText = buttonText;
      errorCompleter = completer;
    });
    return completer.future;
  }

  Future<void> onLichessMoveMade() async {
    print("onLichessMoveMade");
    final lichessHistory = lichessController.moves;
    final internalHistory = internalController.game.history;

    if (lichessHistory.length == internalHistory.length) {
      assert(Iterable.generate(lichessHistory.length,
              (i) => lichessHistory[i].compatibleWith(internalHistory[i].move))
          .every((e) => e));
    } else if (lichessHistory.length == internalHistory.length + 1 &&
        internalController.game.turn != widget.playerColor) {
      LichessMove lichessMove = lichessController.moves.last;
      Move opponentMove = internalController.game
          .generate_moves()
          .singleWhere(lichessMove.compatibleWith);

      try {
        // Execute opponent move on physical chess board
        await roboController.makeMove(opponentMove);
      } on RoboMoveUnsuccessfulException catch (e) {
        // TODO: Make a popup that asks user to perform the move themselves
        print(e);
      }

      internalController.makeMoveFromObject(opponentMove);
    } else {
      await showErrorMessage(
          "You made a move on Lichess instead of on the physical board. "
              "Please go back and select the game from the game selection screen again",
          "EXIT");
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      // throw Exception("Lichess move during player turn");
    }
  }

  Future<void> onInternalMoveMade() async {
    print("onInternalMoveMade: turn=${internalController.game.turn}");
    // TODO: Handle end of game

    if (internalController.game.turn == widget.playerColor) {
      // Start listening to board events, one of which will indicate that the
      // players move is done
      receiveEvents = true;
    } else {
      if (internalController.game.history.isNotEmpty) {
        lichessController.makeMove(internalController.game.history.last.move);
      }
    }
  }

  Future<void> onPlayerMoveFinished() async {
    // Stop listening to board events, since all the board events should
    // come from the board making its move and we know what it is going
    // to do
    receiveEvents = false;

    print("onPlayerMoveFinished");

    // Extract move from event history
    List<Move> compatibleMoves =
        extractCompatibleMoves(internalController.game, eventHistory);
    print("compatibleMoves=${compatibleMoves.map((move) => move.toJson())}");
    eventHistory.clear(); // These events are outdated now

    if (compatibleMoves.length > 1 &&
        (compatibleMoves.first.flags & Chess.BITS_PROMOTION) != 0) {
      // TODO: Ask the player for the promotion piece
      internalController.makeMoveFromObject(compatibleMoves.first);
    } else if (compatibleMoves.isEmpty) {
      await showErrorMessage(
          "The move you made is not legal. "
              "Please undo your last move on the board by restoring the board state shown below.",
          "DONE");

      // When the popup is closed and the user has reset the board to the
      // previous position, clear event history and start listening  to board
      // events again
      receiveEvents = true;
      return;
    } else {
      // Throws an error if there is more than one compatible move or if the
      // only compatible move is illegal
      assert(internalController.makeMoveFromObject(compatibleMoves.single));
    }
  }

  void handleEvent(dynamic eventData) async {
    print("handleEvent: $eventData");
    if (eventData['type'] == "event" && receiveEvents) {
      var event = RoboChessBoardEvent.fromJson(eventData);

      if (event.square == 1 << 8) {
        // Button (square number 2^9 = 256) pressed
        if (event.direction == Direction.up) {
          // The user is done with their move
          await onPlayerMoveFinished();
        }
      } else {
        eventHistory.add(event);
      }
    }
  }

  @override
  void initState() {
    super.initState();

    var model = ScopedModel.of<BluetoothConnectionModel>(context);
    model.messageQueue.stream.listen(handleEvent);

    roboController = RoboChessBoardController(bluetooth: model);

    lichessController = LichessController(
        client: widget.lichessClient,
        gameId: widget.gameId,
        onInitialized: onLichessControllerInitialized);
    lichessController.addListener(onLichessMoveMade);
  }

  void onLichessControllerInitialized() {
    for (var lichessMove in lichessController.moves) {
      internalController.makeMoveFromObject(internalController.game
          .generate_moves()
          .singleWhere(lichessMove.compatibleWith));
    }

    internalController.addListener(onInternalMoveMade);
    onInternalMoveMade();
  }

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    TextStyle onErrorStyle = TextStyle(color: colorScheme.onErrorContainer);
    TextStyle? tableHeaderStyle = Theme.of(context).textTheme.titleMedium;

    List<Widget> errorCards = [];
    if (errorMessage != "") {
      errorCards += [
        Card(
            color: colorScheme.errorContainer,
            child: ListTile(
              title: Text(errorMessage, style: onErrorStyle),
              trailing: TextButton(
                onPressed: errorCompleter?.complete,
                child: Text(errorButtonText, style: onErrorStyle),
              ),
            )),
        const SizedBox(height: 8)
      ];
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Screen'),
      ),
      body: Column(
        children: [
          Expanded(
              child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
                children: errorCards +
                    [
                      ChessBoard(
                        controller: internalController,
                        boardOrientation:
                            widget.playerColor == flutter_chess.Color.WHITE
                                ? PlayerColor.white
                                : PlayerColor.black,
                        // TODO: Disable user moves, currently useful for debugging
                        // enableUserMoves: false,
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                          child: Container(
                        decoration: BoxDecoration(border: Border.all(width: 2)),
                        child: ListView(
                          children: <Widget>[
                            MovesTable(
                              controller: internalController,
                              rowNormalColor: colorScheme.background,
                              rowAccentColor: colorScheme.surface,
                              headerStyle: tableHeaderStyle,
                              playerColor: widget.playerColor,
                              opponentName: widget.opponentName,
                            ),
                          ],
                        ),
                      )),
                    ]),
          )),
          const BluetoothConnectionWidget()
        ],
      ),
    );
  }
}
