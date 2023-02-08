import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:wizard_chess/bluetooth_connection_model.dart';
import 'package:wizard_chess/bluetooth_connection_widget.dart';
import 'package:wizard_chess/chess_board_event.dart';
import 'package:wizard_chess/chess_logic.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  List<ChessBoardEvent> eventQueue = [];
  String screenContent = "Hello World";
  RoboChessBoardController controller = RoboChessBoardController(Chess());
  ChessOpponent opponent = RandomChessOpponent();

  void handleEvent(dynamic eventData) async {
    if (eventData['type'] == "event") {
      var event = ChessBoardEvent.fromJson(eventData);

      if (event.square == 'button') {
        if (event.direction == Direction.up) {
          // The user is done with their move
          setState(() {
            screenContent =
                "Done with move: ${eventQueue.map((e) => e.toJson())}";
          });

          // TODO: Fix timing issues
          // If this is called while the other player is thinking about or
          // performing their move, we run into problems
          var playerMove = interpretMove(controller.game, eventQueue);
          controller.makeMoveFromObject(playerMove);
          var opponentMove = await opponent.move(controller.game);
          controller.makeMoveFromObject(opponentMove);
        }
      } else {
        eventQueue.add(event);
      }
    }
  }

  @override
  void initState() {
    super.initState();

    var model = ScopedModel.of<BluetoothConnectionModel>(context);
    if (model.connectionState() == BluetoothConnectionState.connected) {
      model.messageQueue.stream.listen(handleEvent);
    }
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
            controller: controller,
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
