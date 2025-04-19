import 'package:flutter/material.dart';

class TeacherProvider with ChangeNotifier {
  String? _teacherId;
  String? _teacherName;

  String? get teacherId => _teacherId;
  String? get teacherName => _teacherName;

  void setTeacherData(String id, String name) {
    _teacherId = id;
    _teacherName = name;
    notifyListeners();
  }

  void clearTeacherData() {
    _teacherId = null;
    _teacherName = null;
    notifyListeners();
  }
}
