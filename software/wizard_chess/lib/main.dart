import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
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
      routes: {
        WizardChessRoutes.home: (context) => const HomeScreen(),
        WizardChessRoutes.game: (context) => const GameScreen(),
        WizardChessRoutes.settings: (context) => const SettingsScreen(),
        // TODO: Add these screens
        // WizardChessRoutes.history: (context) => null,
      },
    );

    // Use ScopedModel to provide the bluetooth connection to every screen
    return ScopedModel(
      model: BluetoothConnectionModel(),
      child: app,
    );
  }
}
