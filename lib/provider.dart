import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  String? _userId;
  String? _userName;
  String? _userRole; // "admin" أو "teacher"

  String? get userId => _userId;
  String? get userName => _userName;
  String? get userRole => _userRole;

  void setUser(String id, String name, String role) {
    _userId = id;
    _userName = name;
    _userRole = role;
    notifyListeners();
  }

  void clearUser() {
    _userId = null;
    _userName = null;
    _userRole = null;
    notifyListeners();
  }
}
