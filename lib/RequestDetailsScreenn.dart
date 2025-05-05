import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RequestDetailsScreen extends StatelessWidget {
  final String studentName;
  final String grade;
  final String teacherName;
  final String exitTime;
  final String requestId;

  RequestDetailsScreen({
    required this.studentName,
    required this.grade,
    required this.teacherName,
    required this.exitTime,
    required this.requestId,
  });

  Future<void> markRequestAsCompleted(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(requestId)
          .update({
            'status': 'completed', // تحديث الحالة إلى "مكتمل"
          });
      print("تم تحديث حالة الطلب إلى مكتمل.");
      Navigator.pop(context); // العودة إلى الشاشة السابقة بعد الإكمال
    } catch (e) {
      print("❌ خطأ أثناء تحديث حالة الطلب: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("حدث خطأ أثناء تحديث حالة الطلب.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        centerTitle: true,
        title: Text("معلومات الطلب", style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("الطالب: $studentName", style: TextStyle(fontSize: 18)),
                  Text(
                    "الصف: ${grade.isNotEmpty ? grade : 'غير محدد'}",
                    style: TextStyle(fontSize: 18),
                  ),
                  Text("المعلم: $teacherName", style: TextStyle(fontSize: 18)),
                  Text("وقت الخروج: $exitTime", style: TextStyle(fontSize: 18)),
                ],
              ),
            ),
            Spacer(),
            MaterialButton(
              onPressed: () {
                markRequestAsCompleted(context);
              },
              color: Color.fromARGB(255, 1, 113, 189),
              textColor: Colors.white,
              child: Text("اكتمل"),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              height: 50,
              minWidth: double.infinity,
            ),
          ],
        ),
      ),
    );
  }
}
