// lib/provider/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../globals.dart';

class AuthProvider extends ChangeNotifier {
  AppUser? _user;
  bool _isAuthenticated = false;

  AppUser? get user => _user;
  bool get isAuthenticated => _isAuthenticated;

  Future<void> login(int id) async {
    if (appUsers.containsKey(id)) {
      _user = appUsers[id];
      _isAuthenticated = true;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('userId', id);

      currentUser = _user; // Atualiza global
      notifyListeners();
    } else {
      throw Exception('Código inválido');
    }
  }

  Future<void> loadSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getInt('userId');
    if (savedId != null && appUsers.containsKey(savedId)) {
      _user = appUsers[savedId];
      _isAuthenticated = true;
      currentUser = _user;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    _user = null;
    _isAuthenticated = false;
    currentUser = null;
    notifyListeners();
  }
}