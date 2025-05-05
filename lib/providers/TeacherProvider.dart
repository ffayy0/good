import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherProvider with ChangeNotifier {
  String? _teacherId;
  String? _teacherName;
  String? _schoolId;

  // Getters لاسترجاع البيانات
  String? get teacherId => _teacherId;
  String? get teacherName => _teacherName;
  String? get schoolId => _schoolId;

  // دالة لتعيين بيانات المعلم يدويًا
  void setTeacherData(String id, String name, String schoolId) {
    _teacherId = id;
    _teacherName = name;
    _schoolId = schoolId;
    notifyListeners();
  }

  // دالة لمسح بيانات المعلم
  void clearTeacherData() {
    _teacherId = null;
    _teacherName = null;
    _schoolId = null;

    notifyListeners(); // إشعار المستمعين بتحديث البيانات
  }

  // دالة لجلب بيانات المعلم من Firestore باستخدام teacherId
  Future<void> fetchTeacherData(String teacherId) async {
    try {
      // جلب بيانات المعلم من Firestore باستخدام المعرف (teacherId)
      final doc =
          await FirebaseFirestore.instance
              .collection('teachers')
              .doc(teacherId)
              .get();
      if (!doc.exists) throw Exception("لم يتم العثور على بيانات المعلم");

      final data = doc.data() as Map<String, dynamic>;

      if (!data.containsKey('name') || !data.containsKey('schoolId')) {
        throw Exception("بيانات المعلم غير مكتملة");
      }

      setTeacherData(doc.id, data['name'], data['schoolId']);
      print("✅ تم جلب بيانات المعلم بنجاح: $_teacherName / $_schoolId");
    } catch (e) {
      print("❌ خطأ أثناء جلب بيانات المعلم: $e");
      rethrow;
    }
  }
}
