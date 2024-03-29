import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:chess_vectors_flutter/vector_image.dart';

import 'bluetooth_connection_model.dart';
import 'bluetooth_connection_widget.dart';
import 'lichess_client.dart';
import 'routes.dart';
import 'settings.dart';

/// White pawn vector (stolen from chess_vectors_flutter.dart)
class Pawn extends VectorBase {
  final Color fillColor;
  final Color strokeColor;
  final bool showNotificationDot;

  /// size (double) : default to 45.0
  Pawn({
    double size = 45.0,
    this.fillColor = Colors.white,
    this.strokeColor = Colors.black,
    this.showNotificationDot = false,
  }) : super(
          baseImageSize: 45.0,
          requestSize: size,
          painter: VectorImagePainter(
            vectorDefinition: <VectorDrawableElement>[
                  VectorImagePathDefinition(
                    path:
                        "M 22,9 C 19.79,9 18,10.79 18,13 C 18,13.89 18.29,14.71 18.78,15.38"
                        " C 16.83,16.5 15.5,18.59 15.5,21 C 15.5,23.03 16.44,24.84 17.91,26.03"
                        " C 14.91,27.09 10.5,31.58 10.5,39.5 L 33.5,39.5 C 33.5,31.58 29.09,"
                        "27.09 26.09,26.03 C 27.56,24.84 28.5,23.03 28.5,21 C 28.5,18.59"
                        " 27.17,16.5 25.22,15.38 C 25.71,14.71 26,13.89 26,13 C 26,10.79"
                        " 24.21,9 22,9 z ",
                    drawingParameters: DrawingParameters(
                      fillColor: fillColor,
                      strokeColor: strokeColor,
                      strokeWidth: 1.5,
                      strokeLineCap: StrokeCap.round,
                      strokeLineJoin: StrokeJoin.miter,
                      strokeLineMiterLimit: 4.0,
                    ),
                  ),
                ] +
                (showNotificationDot
                    ? [
                        VectorImagePathDefinition(
                            path: "M 33,8 A 4,4 0 0 1 41,8 A 4,4 0 0 1 33,8 z",
                            drawingParameters: DrawingParameters(
                              fillColor: Colors.red,
                              strokeColor: Colors.red,
                              strokeWidth: 1.5,
                            ))
                      ]
                    : []),
          ),
        );
}

enum LichessConnectionFailure {
  missingAuthorizationCode,
  invalidAuthorizationCode,
  otherError,
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<RefreshIndicatorState> refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  Settings settings = Settings.getInstance();
  late LichessClient lichessClient;
  bool lichessClientInitialized = false;
  List<dynamic> ongoingGames = [];

  Future<void> showFailurePopup(
      BuildContext context, LichessConnectionFailure failure) {
    String message;
    switch (failure) {
      case LichessConnectionFailure.missingAuthorizationCode:
        message = "A Lichess account is required to use this app. "
            "To connect to your Lichess account, please open the settings menu and enter your access token.";
        break;
      case LichessConnectionFailure.invalidAuthorizationCode:
        message =
            "The Lichess access token you provided is invalid, please open the settings menu and enter a new access token.";
        break;
      case LichessConnectionFailure.otherError:
        message =
            "An error occurred while connecting to the Lichess server, please make sure you are connected to the internet and try again.";
        break;
    }

    TextButton acceptButton;
    switch (failure) {
      case LichessConnectionFailure.missingAuthorizationCode:
      case LichessConnectionFailure.invalidAuthorizationCode:
        acceptButton = TextButton(
          child: const Text('SETTINGS'),
          onPressed: () {
            Navigator.of(context).pop(); // Close pop-up
            Navigator.pushNamed(context, RoboChessRoutes.settings);
          },
        );
        break;

      case LichessConnectionFailure.otherError:
        acceptButton = TextButton(
          child: const Text('OK'),
          onPressed: () {
            Navigator.of(context).pop(); // Close pop-up
          },
        );
        break;
    }

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Connection Failed'),
          content: SingleChildScrollView(
            child: Text(message),
          ),
          actions: [acceptButton],
        );
      },
    );
  }

  Future<void> loadGames(BuildContext context) async {
    try {
      var games = await lichessClient.getOngoingGames();

      // Add some additional info to the game data, "createdAt" and "lastMoveAt"
      // are particularly interesting
      var gameIds = games.map((e) => e["gameId"] as String).toList();
      var additionalGameInfo = await lichessClient.getGamesByIds(gameIds);
      for (int i = 0; i < games.length; i++) {
        games[i] = {
          ...games[i],
          ...additionalGameInfo[gameIds[i]]!,
        };
      }
      games.sort((gameA, gameB) {
        if (gameA["secondsLeft"] == gameB["secondsLeft"]) {
          return -(gameA["lastMoveAt"] as int)
              .compareTo(gameB["lastMoveAt"] as int);
        } else {
          return (gameA["secondsLeft"] as int? ?? double.infinity)
              .compareTo(gameB["secondsLeft"] as int? ?? double.infinity);
        }
      });

      setState(() {
        ongoingGames = games;
      });
    } on DioException catch (e) {
      setState(() {
        ongoingGames = [];
      });
      if (e.response?.statusCode == 401) {
        if (lichessClient.authorizationCode == "") {
          showFailurePopup(
              context, LichessConnectionFailure.missingAuthorizationCode);
        } else {
          showFailurePopup(
              context, LichessConnectionFailure.invalidAuthorizationCode);
        }
      } else {
        showFailurePopup(context, LichessConnectionFailure.otherError);
      }
    }
  }

  Future<void> startGame() async {
    // TODO: Add new game selection popup
    // Challenge friend or AI (which difficulty?)
    // Which side do you want to play?
    await lichessClient.challengeAi();
  }

  @override
  void initState() {
    print("initState");
    super.initState();

    // If the API key changes (and at startup) ...
    settings.addListener(() {
      // ... close the previous connection, ...
      if (lichessClientInitialized) {
        lichessClient.close();
      }

      // ... initialize the lichess client and ...
      String authorizationCode =
          settings.getString(Settings.lichessApiKey) ?? "";
      lichessClient = LichessClient(authorizationCode: authorizationCode);
      lichessClientInitialized = true;

      // ... reload the current games (calls onRefresh, i.e. loadGames).
      refreshIndicatorKey.currentState?.show();
    });
  }

  @override
  void dispose() {
    var model = ScopedModel.of<BluetoothConnectionModel>(context);
    model.dispose();

    lichessClient.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Games'),
        actions: [
          IconButton(
              onPressed: () async {
                await startGame();
                refreshIndicatorKey.currentState?.show();
              },
              icon: const Icon(Icons.add)),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, RoboChessRoutes.settings);
            },
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
              child: RefreshIndicator(
                  key: refreshIndicatorKey,
                  onRefresh: () => loadGames(context),
                  child: ListView.builder(
                      itemCount: ongoingGames.length,
                      itemBuilder: (context, index) {
                        dynamic game = ongoingGames[index];

                        DateFormat dateFormat =
                            DateFormat.yMd('en_GB').add_jm();
                        String remainingTime = "";
                        if (game["secondsLeft"] == null) {
                          remainingTime = "forever";
                        } else {
                          var duration = Duration(seconds: game["secondsLeft"]);
                          if (duration > const Duration(days: 1)) {
                            remainingTime = "${duration.inDays} days";
                          } else if (duration > const Duration(hours: 1)) {
                            remainingTime = "${duration.inHours} hours";
                          } else if (duration > const Duration(minutes: 1)) {
                            remainingTime = "${duration.inMinutes} minutes";
                          } else {
                            remainingTime = "${duration.inSeconds} seconds";
                          }
                        }
                        String lastMoveAt = dateFormat.format(
                            DateTime.fromMillisecondsSinceEpoch(
                                    game["lastMoveAt"],
                                    isUtc: true)
                                .toLocal());
                        return Card(
                          key: Key(game["gameId"] as String),
                          child: ListTile(
                            leading: Pawn(
                              fillColor: game["color"] == "white"
                                  ? Colors.white
                                  : Colors.black,
                              showNotificationDot: game["isMyTurn"],
                            ),
                            title: Text(
                              game["opponent"]["username"],
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            subtitle: Text(
                                "Time remaining: $remainingTime\nLast move: $lastMoveAt"),
                            isThreeLine: true,
                            onTap: () {
                              if (context.mounted) {
                                Navigator.pushNamed(
                                    context, RoboChessRoutes.game,
                                    arguments: [
                                      lichessClient.authorizationCode,
                                      game
                                    ]);
                              }
                            },
                          ),
                        );
                      }))),
          const BluetoothConnectionWidget(),
        ],
      ),
    );
  }
}
