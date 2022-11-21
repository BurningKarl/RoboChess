import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:scoped_model/scoped_model.dart';

enum BluetoothConnectionState {
  bluetoothOff,
  disconnected,
  connecting,
  connected,
}

class BluetoothConnectionModel extends Model {
  final String chessboardAddress = 'E0:D4:64:32:A1:76';
  BluetoothState bluetoothState = BluetoothState.UNKNOWN;
  bool connecting = false;
  // BluetoothConnection? connection;
  bool? connection; // TODO: Replace by real connection object

  BluetoothConnectionModel() {
    FlutterBluetoothSerial.instance.state.then((state) {
      bluetoothState = state;
      notifyListeners();
    });

    FlutterBluetoothSerial.instance.onStateChanged().listen((state) {
      bluetoothState = state;
      notifyListeners();
    });
  }

  dispose() {
    // connection?.dispose();
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

  void tryToConnect() {
    connecting = true;
    notifyListeners();
    // BluetoothConnection.toAddress(chessboardAddress).then((newConnection) {
    Future<bool>.delayed(const Duration(seconds: 2), () => true)
        .then((newConnection) {
      print(newConnection);
      connection = newConnection;
      connecting = false;
      notifyListeners();
    });
  }

  void disconnect() {
    // connection?.finish();
    connection = null;
    notifyListeners();
  }
}
