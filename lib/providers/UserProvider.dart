import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  String? _userId;
  String? _userName;
  String? _userRole; // "admin" أو "teacher"

  // Getters لاسترجاع البيانات
  String? get userId => _userId;
  String? get userName => _userName;
  String? get userRole => _userRole;

  // دالة لتعيين بيانات المستخدم
  void setUser(String id, String name, String role) {
    _userId = id;
    _userName = name;
    _userRole = role;
    notifyListeners(); // إشعار المستمعين بتحديث البيانات
  }

  // دالة لمسح بيانات المستخدم
  void clearUser() {
    _userId = null;
    _userName = null;
    _userRole = null;
    notifyListeners(); // إشعار المستمعين بتحديث البيانات
  }
}
