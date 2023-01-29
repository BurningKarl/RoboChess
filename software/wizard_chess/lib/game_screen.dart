import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:wizard_chess/bluetooth_connection_model.dart';
import 'package:wizard_chess/bluetooth_connection_widget.dart';
import 'package:wizard_chess/chessboard_event.dart';
import "package:chess/chess.dart" show Chess;

class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  List<ChessboardEvent> eventQueue = [];
  String screenContent = "Hello World";
  Chess chess = Chess();

  @override
  void initState() {
    super.initState();

    var model = ScopedModel.of<BluetoothConnectionModel>(context);
    // TODO: Make the converted JSON its own stream
    if (model.connectionState() == BluetoothConnectionState.connected) {
      model.connection?.input!.listen((event) {
        String rawData = String.fromCharCodes(event);
        var jsonData = jsonDecode(rawData);

        // TODO: Make this event handling its own function
        if (jsonData['type'] == "event") {
          if (jsonData['square'] == 'button') {
            if (jsonData['direction'] == 'up') {
              // The user is done with their move
              setState(() {
                screenContent = "Done with move: ${eventQueue.map((e) => e.toJson())}";
              });
            }
          } else {
            eventQueue.add(ChessboardEvent(
                jsonData['direction'] == 'down' ? Direction.down : Direction.up,
                jsonData['square']));
          }
        }
      });
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
          BluetoothConnectionWidget(),
        ],
      ),
    );
  }
}
