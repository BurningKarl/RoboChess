import 'dart:async';

import 'package:chess_vectors_flutter/chess_vectors_flutter.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart' hide Color;
import 'package:flutter_chess_board/flutter_chess_board.dart' as flutter_chess;

import 'bluetooth_connection_model.dart';
import 'bluetooth_connection_widget.dart';
import 'internal_chess_board_controller.dart';
import 'moves_table.dart';
import 'robo_chess_board_event.dart';
import 'robo_chess_board_controller.dart';
import 'lichess_controller.dart';
import 'chess_logic.dart';
import 'error_card.dart';

class GameScreen extends StatefulWidget {
  final String authorizationCode;
  final String gameId;
  final flutter_chess.Color playerColor;
  final String opponentName;
  const GameScreen(
      {Key? key,
      required this.authorizationCode,
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
  bool lichessControllerInitialized = false;
  bool boardSetupCorrect = false;
  late StreamSubscription bluetoothEventSubscription;
  List<BoardArrow> boardArrows = [];

  List<ErrorCard> errorCards = [];

  Future<void> showErrorMessage(String message, String buttonText) {
    Completer<void> completer = Completer();
    var errorCard = ErrorCard(
      message: message,
      buttonText: buttonText,
      completer: completer,
    );

    setState(() {
      errorCards.add(errorCard);
    });
    return completer.future.then((value) {
      if (context.mounted) {
        setState(() {
          errorCards.remove(errorCard);
        });
      }
    });
  }

  // Copied from chess_board.dart
  Future<PieceType> promotionDialog(BuildContext context) async {
    return showDialog<PieceType>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose promotion'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              InkWell(
                child: WhiteQueen(),
                onTap: () {
                  Navigator.of(context).pop(PieceType.QUEEN);
                },
              ),
              InkWell(
                child: WhiteRook(),
                onTap: () {
                  Navigator.of(context).pop(PieceType.ROOK);
                },
              ),
              InkWell(
                child: WhiteBishop(),
                onTap: () {
                  Navigator.of(context).pop(PieceType.BISHOP);
                },
              ),
              InkWell(
                child: WhiteKnight(),
                onTap: () {
                  Navigator.of(context).pop(PieceType.KNIGHT);
                },
              ),
            ],
          ),
        );
      },
    ).then((value) => value!);
  }

  Future<void> onLichessMoveMade() async {
    print("onLichessMoveMade");
    final lichessHistory = lichessController.moves;
    final internalHistory = internalController.game.history;

    if (lichessHistory.length == internalHistory.length) {
      assert(Iterable.generate(lichessHistory.length).every(
          (i) => lichessHistory[i].compatibleWith(internalHistory[i].move)));
    } else if (lichessHistory.length == internalHistory.length + 1 &&
        internalController.game.turn != widget.playerColor) {
      LichessMove lichessMove = lichessController.moves.last;
      Move opponentMove = internalController.game
          .generate_moves()
          .singleWhere(lichessMove.compatibleWith);

      try {
        // Execute opponent move on physical chess board
        await roboController.makeMove(internalController.game, opponentMove);
        internalController.makeMoveFromObject(opponentMove);
      } on RoboMoveUnsuccessfulException {
        internalController.makeMoveFromObject(opponentMove);
        receiveEvents = false;
        eventHistory.clear();

        await showErrorMessage(
            "The opponent move could not be executed on the board. "
                "Please set up the board as shown below to continue.",
            "DONE");
        if (context.mounted) {
          receiveEvents = true;
        }
      }
    } else {
      await showErrorMessage(
          "You made a move on Lichess instead of on the physical board. "
              "Please go back and select the game from the game selection screen again.",
          "EXIT");
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      // throw Exception("Lichess move during player turn");
    }
  }

  Future<void> onInternalMoveMade() async {
    final Chess game = internalController.game;
    final history = game.history;
    print("onInternalMoveMade: turn=${game.turn}");

    setState(() {
      if (history.isNotEmpty) {
        boardArrows = [
          BoardArrow(
              from: history.last.move.fromAlgebraic,
              to: history.last.move.toAlgebraic)
        ];
      } else {
        boardArrows = [];
      }
    });

    if (game.game_over) {
      String message = "Unknown reason";

      if (game.in_stalemate) {
        message = "The game ended in a stalemate.";
      } else if (game.in_draw) {
        message = "The game ended with a draw.";
      } else if (game.in_checkmate) {
        message =
            "The game ended with a checkmate. ${game.turn == widget.playerColor ? "You lost!" : "You won!"}";
      }

      await showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Game Over'),
            content: SingleChildScrollView(
              child: Text(message),
            ),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop(); // Close pop-up
                },
              )
            ],
          );
        },
      );
    } else if (game.turn == widget.playerColor) {
      // Start listening to board events, one of which will indicate that the
      // players move is done
      receiveEvents = true;
    } else {
      if (history.isNotEmpty) {
        lichessController.makeMove(history.last.move);
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
      PieceType chosenPieceType = await promotionDialog(context);
      internalController.makeMoveFromObject(compatibleMoves
          .singleWhere((move) => move.promotion == chosenPieceType));
    } else if (compatibleMoves.isEmpty || compatibleMoves.length > 1) {
      var message = compatibleMoves.isEmpty
          ? "The move you made is not legal."
          : "The move you made is ambiguous.";
      await showErrorMessage(
          "$message Please undo your last move on the board by restoring the board state shown below.",
          "DONE");

      // When the popup is closed and the user has reset the board to the
      // previous position, clear event history and start listening  to board
      // events again
      receiveEvents = true;
      return;
    } else {
      assert(internalController.makeMoveFromObject(compatibleMoves.single));
    }
  }

  void handleEvent(dynamic eventData) async {
    print("handleEvent: $eventData");
    if (eventData['type'] == "event" && receiveEvents && boardSetupCorrect) {
      var event = RoboChessBoardEvent.fromJson(eventData);

      if (event.square == 0x100) {
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

  void onNetworkError(Object error) {
    print("onNetworkError $error");

    if (!context.mounted) {
      return;
    }

    showErrorMessage(
            "The connection to the Lichess server has been lost. "
                "Please go back and select the game from the game selection screen again.",
            "EXIT")
        .then((value) {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void initState() {
    super.initState();

    var model = ScopedModel.of<BluetoothConnectionModel>(context);
    bluetoothEventSubscription = model.messageQueue.stream.listen(handleEvent);

    roboController = RoboChessBoardController(bluetooth: model);

    lichessController = LichessController(
        authorizationCode: widget.authorizationCode,
        gameId: widget.gameId,
        onInitialized: onLichessControllerInitialized,
        onError: onNetworkError);
    lichessController.addListener(onLichessMoveMade);
  }

  void onLichessControllerInitialized() {
    for (var lichessMove in lichessController.moves) {
      internalController.makeMoveFromObject(internalController.game
          .generate_moves()
          .singleWhere(lichessMove.compatibleWith));
    }

    lichessControllerInitialized = true;
    internalController.addListener(onInternalMoveMade);
    onInternalMoveMade();

    checkRoboChessBoardSetup();
  }

  Future<void> checkRoboChessBoardSetup() async {
    List<int> occupiedSquares = [];
    try {
      occupiedSquares = await roboController.requestOccupiedSquares();
    } on NoBluetoothConnection {
      showErrorMessage(
              "Please establish a Bluetooth connection to the chess board. ",
              "RETRY")
          .then((_) => checkRoboChessBoardSetup());
      return;
    } on TimeoutException {
      showErrorMessage(
              "Could not get a response from the board. "
                  "Please check the Bluetooth connection.",
              "RETRY")
          .then((_) => checkRoboChessBoardSetup());
      return;
    }

    var mismatchExists = internalController.game.board.asMap().entries.any(
        (entry) =>
            (entry.value != null) != (occupiedSquares.contains(entry.key)));
    if (mismatchExists) {
      await showErrorMessage(
              "The chess board is not set up properly. "
                  "Please make sure each chess piece is in the position shown below.",
              "DONE")
          .then((_) => checkRoboChessBoardSetup());
      return;
    } else {
      boardSetupCorrect = true;
    }
  }

  @override
  void dispose() {
    bluetoothEventSubscription.cancel();

    internalController.dispose();
    lichessController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    TextStyle? tableHeaderStyle = Theme.of(context).textTheme.titleMedium;

    Widget chessBoardOrLoading = lichessControllerInitialized
        ? ChessBoard(
            controller: internalController,
            boardOrientation: widget.playerColor == flutter_chess.Color.WHITE
                ? PlayerColor.white
                : PlayerColor.black,
            arrows: boardArrows,
            // TODO: Disable user moves, currently useful for debugging
            // enableUserMoves: false,
          )
        : const AspectRatio(
            aspectRatio: 1.0,
            child: Center(child: CircularProgressIndicator()),
          );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Screen'),
      ),
      body: Column(
        children: [
          Expanded(
              child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(children: [
              ...errorCards,
              chessBoardOrLoading,
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
