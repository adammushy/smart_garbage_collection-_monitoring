import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesManager {
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }


  Future<bool> saveBool(String key, bool value) async {
    return await _prefs.setBool(key, value);
  }

  bool getBool(String key) {
    return _prefs.getBool(key) ?? false;
  }

  Future<bool> saveString(String key, String value) async {
    return await _prefs.setString(key, value);
  }

  String getString(String key) {
    return _prefs.getString(key) ?? '';
  }

  Future<bool> saveInt(String key, int value) async {
    return await _prefs.setInt(key, value);
  }

  int getInt(String key) {
    return _prefs.getInt(key) ?? 0;
  }

  Future<bool> saveDouble(String key, double value) async {
    return await _prefs.setDouble(key, value);
  }

  double getDouble(String key) {
    return _prefs.getDouble(key) ?? 0.0;
  }

  Future<bool> saveStringList(String key, List<String> value) async {
    return await _prefs.setStringList(key, value);
  }

  List<String> getStringList(String key) {
    return _prefs.getStringList(key) ?? [];
  }
}
