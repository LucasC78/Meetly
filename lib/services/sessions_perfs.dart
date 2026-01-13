import 'package:shared_preferences/shared_preferences.dart';

class SessionPrefs {
  static const _stayLoggedInKey = 'stay_logged_in';

  static Future<void> setStayLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_stayLoggedInKey, value);
  }

  static Future<bool> getStayLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_stayLoggedInKey) ?? true; // ✅ par défaut ON
  }
}
