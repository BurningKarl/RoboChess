import 'package:flutter/material.dart';

void main() {
  runApp(const WizardChessApp());
}

class WizardChessApp extends StatelessWidget {
  const WizardChessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wizard Chess',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool connected = false;

  void tryToConnect() {
    setState(() {
      connected = true;
    });
  }

  void disconnect() {
    setState(() {
      connected = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Expanded(
              child: ListView(
            children: [
              const Card(
                child: ListTile(
                  title: Text('Play remotely'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Play against the computer'),
                  onTap: () {},
                ),
              )
            ],
          )),
          const Divider(
            height: 0,
          ),
          ListTile(
            title: connected
                ? const Text('Connected to chess board')
                : const Text('Not connected to chess board'),
            leading: Icon(
              connected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
              color: connected ? Colors.green : Colors.red,
            ),
            trailing: TextButton(
              child:
                  connected ? const Text('DISCONNECT') : const Text('CONNECT'),
              onPressed: () {
                if (connected) {
                  disconnect();
                } else {
                  tryToConnect();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
