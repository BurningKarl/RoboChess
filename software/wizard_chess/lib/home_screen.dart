import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wizard_chess/bluetooth_connection_model.dart';
import 'package:wizard_chess/bluetooth_connection_widget.dart';
import 'package:wizard_chess/lichess_client.dart';
import 'package:wizard_chess/routes.dart';
import 'package:wizard_chess/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> ongoingGames = [];
  late LichessClient lichessClient;

  void startAiGame() async {
    String gameId = (await lichessClient.challengeAi())['id'];
    if (context.mounted) {
      Navigator.pushNamed(context, WizardChessRoutes.game,
          arguments: [lichessClient, gameId]);
    }
  }

  // TODO: Call whenever the API key is updated
  Future<void> initLichessClient() async {
    var preferences = await SharedPreferences.getInstance();
    String authorizationCode =
        preferences.getString(SettingsKeys.lichessApiKey) ?? "";
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

    initLichessClient().whenComplete(loadGames);
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
                  onRefresh: loadGames,
                  child: ListView.builder(
                      itemCount: ongoingGames.length,
                      itemBuilder: (context, index) {
                        dynamic game = ongoingGames[index];
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
