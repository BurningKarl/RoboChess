import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings with ChangeNotifier {
  static const String lichessApiKey = 'lichess-api-key';
  SharedPreferences? preferences;

  Settings() {
    SharedPreferences.getInstance().then((value) {
      preferences = value;
      notifyListeners();
    });
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