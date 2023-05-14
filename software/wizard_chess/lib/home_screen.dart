import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:chess_vectors_flutter/vector_image.dart';
import 'package:wizard_chess/bluetooth_connection_model.dart';
import 'package:wizard_chess/bluetooth_connection_widget.dart';
import 'package:wizard_chess/lichess_client.dart';
import 'package:wizard_chess/routes.dart';
import 'package:wizard_chess/settings.dart';


/// White pawn vector
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
  List<dynamic> ongoingGames = [];

  void initLichessClient() {
    String authorizationCode = settings.getString(Settings.lichessApiKey) ?? "";
    lichessClient = LichessClient(authorizationCode: authorizationCode);
  }

  Future<void> loadGames() async {
    try {
      List<dynamic> games = await lichessClient.getOngoingGames();
      setState(() {
        ongoingGames = games;
      });
    } on DioError catch (e) {
      setState(() {
        ongoingGames = [];
      });
      if (e.response?.statusCode == 401) {
        // TODO: Ask user to provide an authorization code
      } else {
        // TODO: Show generic internet issues popup
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
      // ... initialize the lichess client and ...
      initLichessClient();

      // ... reload the current games (calls onRefresh, i.e. loadGames).
      refreshIndicatorKey.currentState?.show();
    });
  }

  @override
  void dispose() {
    var model = ScopedModel.of<BluetoothConnectionModel>(context);
    model.dispose();

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
              Navigator.pushNamed(context, WizardChessRoutes.settings);
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
                  onRefresh: loadGames,
                  child: ListView.builder(
                      itemCount: ongoingGames.length,
                      itemBuilder: (context, index) {
                        dynamic game = ongoingGames[index];
                        // TODO: Add time created to shown info?
                        String remainingTime = game['secondsLeft'] == null
                            ? "forever"
                            : "${game['secondsLeft']} seconds";
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
                            subtitle: Text("Time remaining: $remainingTime"),
                            onTap: () {
                              if (context.mounted) {
                                Navigator.pushNamed(
                                    context, WizardChessRoutes.game,
                                    arguments: [lichessClient, game]);
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
