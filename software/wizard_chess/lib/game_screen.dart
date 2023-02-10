import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:wizard_chess/bluetooth_connection_model.dart';
import 'package:wizard_chess/bluetooth_connection_widget.dart';
import 'package:wizard_chess/internal_chess_board_controller.dart';
import 'package:wizard_chess/robo_chess_board_event.dart';
import 'package:wizard_chess/robo_chess_board_controller.dart';
import 'package:wizard_chess/chess_logic.dart';
import 'package:wizard_chess/chess_opponent.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

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
  ChessOpponent opponent = RandomChessOpponent();

  Future<void> onInternalMoveMade() async {
    print("onInternalMoveMade: turn=${internalController.game.turn}");
    // TODO: Handle end of game

    if (internalController.game.turn == playerColor) {
      // Start listening to board events, one of which will indicate that the
      // players move is done
      receiveEvents = true;
    } else {
      late Move opponentMove; // Makes name available outside of try scope
      try {
        opponentMove = await opponent.calculateMove(internalController.game);
      } on Exception catch (e) {
        // TODO: Make a popup that tells the user
        // Options: Save game now and quit or retry
        // SystemNavigator.pop();
        print(e);
        return;
      }

      print("opponentMove=${opponentMove.toJson()}");

      try {
        // Execute opponent move on physical chess board
        roboController.makeMove(opponentMove);
      } on RoboMoveUnsuccessfulException {
        // TODO: Make a popup that asks user to perform the move themselves
      }

      internalController.makeMoveFromObject(opponentMove);
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
    var playerMove = extractMove(internalController.game, eventHistory);
    eventHistory.clear(); // These events are outdated now

    print("playerMove=${playerMove?.toJson()}");

    // Execute player move and check for legality
    bool playerMoveIsLegal =
        playerMove != null && internalController.makeMoveFromObject(playerMove);
    if (!playerMoveIsLegal) {
      // TODO: Make a popup that tells the user
      // When the popup is closed and the user has reset the board to the
      // previous position, clear event history and start listening  to board
      // events again
      receiveEvents = true;
      return;
    }
  }

  void handleEvent(dynamic eventData) async {
    print("handleEvent: $eventData");
    if (eventData['type'] == "event" && receiveEvents) {
      var event = RoboChessBoardEvent.fromJson(eventData);

      if (event.square == 'button') {
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

    internalController.addListener(onInternalMoveMade);
    onInternalMoveMade();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
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
