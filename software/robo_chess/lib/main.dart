import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart' as flutter_chess;

import 'game_screen.dart';
import 'routes.dart';
import 'bluetooth_connection_model.dart';
import 'home_screen.dart';
import 'settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  initializeDateFormatting('en_GB', null).then((_) {
    runApp(const RoboChessApp());
  });
}

class RoboChessApp extends StatelessWidget {
  const RoboChessApp({super.key});

  @override
  Widget build(BuildContext context) {
    var app = MaterialApp(
      title: 'Robo Chess',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      onGenerateRoute: (RouteSettings settings) {
        Map<String, WidgetBuilder> routes = {
          RoboChessRoutes.home: (context) => const HomeScreen(),
          RoboChessRoutes.game: (context) {
            final arguments = settings.arguments! as List<dynamic>;
            dynamic game = arguments[1];
            return GameScreen(
              authorizationCode: arguments[0] as String,
              gameId: game["gameId"] as String,
              playerColor: game["color"] == "white"
                  ? flutter_chess.Color.WHITE
                  : flutter_chess.Color.BLACK,
              opponentName: game["opponent"]["username"],
            );
          },
          RoboChessRoutes.settings: (context) => const SettingsScreen(),
        };
        return MaterialPageRoute(builder: routes[settings.name]!);
      },
    );

    // Use ScopedModel to provide the bluetooth connection to every screen
    return ScopedModel(
      model: BluetoothConnectionModel(),
      child: app,
    );
  }
}
