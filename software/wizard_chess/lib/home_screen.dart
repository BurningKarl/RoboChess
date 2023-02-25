import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:wizard_chess/bluetooth_connection_model.dart';
import 'package:wizard_chess/bluetooth_connection_widget.dart';
import 'package:wizard_chess/routes.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
        ],
      ),
      body: Column(
        children: [
          Expanded(
              child: ListView(
            children: [
              Card(
                child: ListTile(
                  title: const Text('Play remotely'),
                  onTap: () {},
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Play against the computer'),
                  onTap: () {
                    Navigator.pushNamed(context, WizardChessRoutes.game);
                  },
                ),
              )
            ],
          )),
          const BluetoothConnectionWidget(),
        ],
      ),
    );
  }
}
