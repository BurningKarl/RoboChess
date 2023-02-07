import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:wizard_chess/bluetooth_connection_model.dart';
import 'package:wizard_chess/bluetooth_connection_widget.dart';
import 'package:wizard_chess/chess_board_event.dart';
import "package:chess/chess.dart" show Chess;

class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  List<ChessBoardEvent> eventQueue = [];
  String screenContent = "Hello World";
  Chess chess = Chess();

  void handleEvent(dynamic eventData) {
    if (eventData['type'] == "event") {
      var event = ChessBoardEvent(
          eventData['direction'] == 'down' ? Direction.down : Direction.up,
          eventData['square']);

      if (event.square == 'button') {
        if (event.direction == Direction.up) {
          // The user is done with their move
          setState(() {
            screenContent = "Done with move: ${eventQueue.map((e) => e.toJson())}";
          });
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
          Expanded(
            child: Text(screenContent),
          ),
          const BluetoothConnectionWidget(),
        ],
      ),
    );
  }
}
