import 'dart:async';

import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:wizard_chess/ndjson.dart';
import 'package:permission_handler/permission_handler.dart';

enum BluetoothConnectionState {
  bluetoothOff,
  disconnected,
  connecting,
  connected,
}

class BluetoothConnectionModel extends Model {
  final String chessboardName = "HC-06";
  BluetoothState bluetoothState = BluetoothState.UNKNOWN;
  bool connecting = false;
  BluetoothConnection? connection;
  var messageQueue = StreamController<dynamic>.broadcast();

  BluetoothConnectionModel() {
    FlutterBluetoothSerial.instance.state.then((state) {
      bluetoothState = state;
      notifyListeners();
    });

    // BluetoothState is about whether device Bluetooth is turned on or off
    FlutterBluetoothSerial.instance.onStateChanged().listen((state) {
      bluetoothState = state;
      notifyListeners();
    });

    // Automatically handle pairing requests for HC-06
    FlutterBluetoothSerial.instance.setPairingRequestHandler((request) async {
      if (request.pairingVariant == PairingVariant.Pin) {
        return "1234";
      } else {
        return null;
      }
    });
  }

  dispose() {
    connection?.dispose();
    FlutterBluetoothSerial.instance.setPairingRequestHandler(null);
  }

  BluetoothConnectionState connectionState() {
    if (bluetoothState != BluetoothState.STATE_ON) {
      return BluetoothConnectionState.bluetoothOff;
    } else if (connection != null) {
      return BluetoothConnectionState.connected;
    } else if (connecting) {
      return BluetoothConnectionState.connecting;
    } else {
      return BluetoothConnectionState.disconnected;
    }
  }

  Future<void> tryToConnect() async {
    connecting = true;
    notifyListeners();

    if (!(await Permission.bluetooth.request()).isGranted || !(await Permission.location.request()).isGranted) {
      connecting = false;
      notifyListeners();

      // TODO: Explain that we need precise location permission to connect
      // to the board via Bluetooth
      return;
    }

    try {
      BluetoothDiscoveryResult result = await FlutterBluetoothSerial.instance
          .startDiscovery()
          .firstWhere((result) => result.device.name == chessboardName);
      connection = await BluetoothConnection.toAddress(result.device.address);
    } on StateError {
      // The chessboard was not found (error thrown by firstWhere)
    } catch (error) {
      // Probably a Bluetooth error
      print("Error:");
      print(error);
    } finally {
      connecting = false;
      notifyListeners();
    }

    if (connection != null) {
      messageQueue.sink.addStream(connection!.input!
          .toJsonStream()
          .where((event) => event['version'] == 1)
          .asBroadcastStream());
    }
  }

  void disconnect() {
    connection?.finish();
    connection = null;
    notifyListeners();
  }
}
