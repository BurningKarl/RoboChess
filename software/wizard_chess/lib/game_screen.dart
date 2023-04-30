import 'dart:async';

import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:wizard_chess/bluetooth_connection_model.dart';
import 'package:wizard_chess/bluetooth_connection_widget.dart';
import 'package:wizard_chess/internal_chess_board_controller.dart';
import 'package:wizard_chess/robo_chess_board_event.dart';
import 'package:wizard_chess/robo_chess_board_controller.dart';
import 'package:wizard_chess/lichess_client.dart';
import 'package:wizard_chess/lichess_controller.dart';
import 'package:wizard_chess/chess_logic.dart';

class GameScreen extends StatefulWidget {
  final LichessClient lichessClient;
  final String gameId;
  const GameScreen(
      {Key? key, required this.lichessClient, required this.gameId})
      : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  String screenContent = "Hello World";
  Color playerColor = Color.WHITE;
  bool receiveEvents = false;
  List<RoboChessBoardEvent> eventHistory = [];
  InternalChessBoardController internalController =
      InternalChessBoardController(Chess());
  late RoboChessBoardController roboController;
  late LichessController lichessController;

  Future<void> onLichessMoveMade() async {
    final lichessHistory = lichessController.moves;
    final internalHistory = internalController.game.history;

    if (lichessHistory.length == internalHistory.length) {
      assert(Iterable.generate(lichessHistory.length,
              (i) => lichessHistory[i].compatibleWith(internalHistory[i].move))
          .every((e) => e));
    } else if (lichessHistory.length == internalHistory.length + 1 &&
        internalController.game.turn != playerColor) {
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
      // TODO: Popup
      throw Exception("Lichess move during player turn");
    }
  }

  Future<void> onInternalMoveMade() async {
    print("onInternalMoveMade: turn=${internalController.game.turn}");
    // TODO: Handle end of game

    if (internalController.game.turn == playerColor) {
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
    setState(() {
      screenContent = "Done with move: ${eventHistory.map((e) => e.toJson())}";
    });

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
      // TODO: Make a popup that tells the user
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

    // TODO: Initialize internal controller with Lichess controller
    internalController.addListener(onInternalMoveMade);
    onInternalMoveMade();

    lichessController = LichessController(
        client: widget.lichessClient,
        gameId: widget.gameId);
    lichessController.addListener(onLichessMoveMade);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Screen'),
      ),
      body: Column(
        children: [
          ChessBoard(
            controller: internalController,
            boardOrientation: PlayerColor.white,
            // TODO: Disable user moves, currently useful for debugging
            // enableUserMoves: false,
          ),
          Expanded(
            child: Text(screenContent),
          ),
          const BluetoothConnectionWidget(),
        ],
      ),
    );
  }
}
