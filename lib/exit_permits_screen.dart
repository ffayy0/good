import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExitPermitsScreen extends StatelessWidget {
  static final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // دالة لإضافة طلب تصريح خروج جديد إلى Firestore
  static Future<void> addStudent({
    required String studentName,
    required String grade,
    required String teacherName,
    required String exitTime,
  }) async {
    try {
      await firestore.collection('requests').add({
        'studentName': studentName,
        'grade': grade,
        'teacherName': teacherName,
        'exitTime': Timestamp.fromDate(
          DateTime.parse(exitTime),
        ), // تخزين الوقت كـ Timestamp
        'status': 'active', // الحالة الافتراضية للطلب
      });
      print("تمت إضافة الطلب بنجاح.");
    } catch (e) {
      print("❌ خطأ أثناء إضافة الطلب: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text('تصاريح الخروج'),
      ),
      body: Center(child: Text('هذه صفحة تصاريح الخروج')),
    );
  }
}
