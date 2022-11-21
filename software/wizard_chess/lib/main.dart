import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';

import 'package:wizard_chess/routes.dart';
import 'package:wizard_chess/bluetooth_connection_model.dart';
import 'package:wizard_chess/home_screen.dart';

void main() {
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
        // TODO: Add these screens
        // WizardChessRoutes.game: (context) => null,
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
