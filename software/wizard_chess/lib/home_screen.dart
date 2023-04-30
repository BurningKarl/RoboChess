import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:wizard_chess/bluetooth_connection_model.dart';
import 'package:wizard_chess/bluetooth_connection_widget.dart';
import 'package:wizard_chess/lichess_client.dart';
import 'package:wizard_chess/routes.dart';
import 'package:wizard_chess/settings.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<RefreshIndicatorState> refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  Settings settings = Settings();
  late LichessClient lichessClient;
  List<dynamic> ongoingGames = [];

  void startAiGame() async {
    String gameId = (await lichessClient.challengeAi())['id'];
    if (context.mounted) {
      Navigator.pushNamed(context, WizardChessRoutes.game,
          arguments: [lichessClient, gameId]);
    }
  }

  // TODO: Call whenever the API key is updated
  void initLichessClient() {
    String authorizationCode = settings.getString(Settings.lichessApiKey) ?? "";
    lichessClient = LichessClient(authorizationCode: authorizationCode);
  }

  Future<void> loadGames() async {
    List<dynamic> games = await lichessClient.getOngoingGames();
    setState(() {
      ongoingGames = games;
    });
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
        title: const Text('Home Page'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, WizardChessRoutes.settings);
            },
            icon: const Icon(Icons.settings),
          ),
          // TODO: Add button to create new game
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
                        // TODO: Improve the UI for these cards
                        // https://lichess.org/api#tag/Games/operation/apiAccountPlaying
                        return Card(
                          child: ListTile(
                            title: Text(game["opponent"]["username"]),
                            onTap: () {
                              if (context.mounted) {
                                Navigator.pushNamed(
                                    context, WizardChessRoutes.game,
                                    arguments: [lichessClient, game["gameId"]]);
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
