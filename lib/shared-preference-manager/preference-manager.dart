import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesManager {
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<bool> saveBool(String key, bool value) async {
    await init();

    return await _prefs.setBool(key, value);
  }

  Future<bool> getBool(String key) async {
    await init();

    return _prefs.getBool(key) ?? false;
  }

  Future<bool> saveString(String key, String value) async {
    await init();

    return await _prefs.setString(key, value);
  }

  Future<String> getString(String key) async {
    await init();

    return _prefs.getString(key) ?? '';
  }

  Future<bool> saveInt(String key, int value) async {
    await init();

    return await _prefs.setInt(key, value);
  }

  Future<int> getInt(String key) async {
    await init();

    return _prefs.getInt(key) ?? 0;
  }

  Future<bool> saveDouble(String key, double value) async {
    await init();

    return await _prefs.setDouble(key, value);
  }

  Future<double> getDouble(String key) async {
    await init();

    return _prefs.getDouble(key) ?? 0.0;
  }

  Future<bool> saveStringList(String key, List<String> value) async {
    await init();

    return await _prefs.setStringList(key, value);
  }

  Future<List<String>> getStringList(String key) async {
    await init();

    return _prefs.getStringList(key) ?? [];
  }

  clearPreferenceByKey(String key) async {
    await init();
    _prefs.remove(key);
  }

  clearAllPreference() async {
    await init();
  }
}
