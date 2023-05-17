import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart' as flutter_chess;
import 'package:wizard_chess/game_screen.dart';
import 'package:wizard_chess/routes.dart';
import 'package:wizard_chess/bluetooth_connection_model.dart';
import 'package:wizard_chess/home_screen.dart';
import 'package:wizard_chess/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WizardChessApp());
}

class WizardChessApp extends StatelessWidget {
  const WizardChessApp({super.key});

  @override
  Widget build(BuildContext context) {
    var app = MaterialApp(
      title: 'Wizard Chess',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      onGenerateRoute: (RouteSettings settings) {
        Map<String, WidgetBuilder> routes = {
          WizardChessRoutes.home: (context) => const HomeScreen(),
          WizardChessRoutes.game: (context) {
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
          WizardChessRoutes.settings: (context) => const SettingsScreen(),
          // TODO: Add these screens
          // WizardChessRoutes.history: (context) => null,
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
