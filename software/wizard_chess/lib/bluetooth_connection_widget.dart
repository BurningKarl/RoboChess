import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:wizard_chess/bluetooth_connection_model.dart';

class BluetoothConnectionWidget extends StatelessWidget {
  const BluetoothConnectionWidget({super.key});

  Future<void> showFailurePopup(
      BuildContext context, BluetoothConnectionFailure failure) async {
    String message = "";
    switch (failure) {
      case BluetoothConnectionFailure.missingPermissions:
        message =
            "Permission for nearby devices and precise device location are necessary to connect to the chess board.";
        break;
      case BluetoothConnectionFailure.boardNotFound:
        message =
            "The chess board could not be found. Please ensure it is turned on.";
        break;
      case BluetoothConnectionFailure.bluetoothError:
        message = "A Bluetooth error occurred. Please try again.";
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
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Close pop-up
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<BluetoothConnectionModel>(
        builder: (context, child, model) {
      ListTile tile;
      switch (model.connectionState()) {
        case BluetoothConnectionState.bluetoothOff:
          tile = ListTile(
            title: const Text("Bluetooth off"),
            leading: const Icon(Icons.bluetooth_disabled, color: Colors.red),
            trailing: TextButton(
              onPressed: FlutterBluetoothSerial.instance.requestEnable,
              child: const Text('TURN ON'),
            ),
          );
          break;
        case BluetoothConnectionState.disconnected:
          tile = ListTile(
            title: const Text("No connection"),
            leading: const Icon(Icons.bluetooth, color: Colors.red),
            trailing: TextButton(
              onPressed: () async {
                var failure = await model.tryToConnect();
                if (failure != null && context.mounted) {
                  showFailurePopup(context, failure);
                }
              },
              child: const Text('CONNECT'),
            ),
          );
          break;
        case BluetoothConnectionState.connecting:
          tile = const ListTile(
            title: Text('Connecting...'),
            leading: Icon(Icons.bluetooth, color: Colors.red),
            trailing: CircularProgressIndicator(),
          );
          break;
        case BluetoothConnectionState.connected:
          tile = ListTile(
            title: const Text("Connected"),
            leading: const Icon(Icons.bluetooth_connected, color: Colors.green),
            trailing: TextButton(
              onPressed: model.disconnect,
              child: const Text('DISCONNECT'),
            ),
          );
          break;
      }

      return Column(
        children: [
          const Divider(
            height: 0,
          ),
          tile,
        ],
      );
    });
  }
}
