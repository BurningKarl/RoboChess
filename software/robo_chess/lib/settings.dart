import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings with ChangeNotifier {
  static const String lichessApiKey = 'lichess-api-key';
  SharedPreferences? preferences;

  static final Settings _singleton = Settings._();

  Settings._() {
    SharedPreferences.getInstance().then((value) {
      preferences = value;
      notifyListeners();
    });
  }

  factory Settings.getInstance() {
    return _singleton;
  }

  Object? get(String key) {
    return preferences?.get(key);
  }

  String? getString(String key) {
    return get(key) as String?;
  }

  Future<bool> setString(String key, String value) async {
    bool valueChanged = false;
    if (preferences != null) {
      valueChanged = await preferences!.setString(key, value);
    }
    if (valueChanged) {
      notifyListeners();
    }
    return valueChanged;
  }
}