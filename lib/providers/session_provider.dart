import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionProvider extends ChangeNotifier {
  String? _sessionId;
  bool _loading = false;

  String? get sessionId => _sessionId;
  bool get loading => _loading;

  Future<void> loadSavedSession() async {
    _loading = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    _sessionId = prefs.getString('sessionId');
    _loading = false;
    notifyListeners();
  }

  Future<void> saveSession(String id) async {
    _sessionId = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sessionId', id);
    notifyListeners();
  }

  Future<void> clearSession() async {
    _sessionId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sessionId');
    notifyListeners();
  }
}
