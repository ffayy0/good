import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RequestDetailsScreen extends StatelessWidget {
  final String studentName;
  final String grade;
  final String teacherName;
  final String exitTime;
  final QueryDocumentSnapshot<Object?> request; // تأكد من وجود هذا الباراميتر
  final String requestId;

  // تأكد من إضافة request هنا في الكونستركتر
  RequestDetailsScreen({
    required this.studentName,
    required this.grade,
    required this.teacherName,
    required this.exitTime,
    required this.request, // التأكد من تمرير الباراميتر
    required this.requestId,
  });

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
                  Text("الطالبة: $studentName", style: TextStyle(fontSize: 18)),
                  Text("الصف: $grade", style: TextStyle(fontSize: 18)),
                  Text("المعلمة: $teacherName", style: TextStyle(fontSize: 18)),
                  Text("وقت الخروج: $exitTime", style: TextStyle(fontSize: 18)),
                ],
              ),
            ),
            Spacer(),
            MaterialButton(
              onPressed: () {
                // يمكن إضافة وظيفة عند النقر على زر "اكتمل"
                print("اكتمل");
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
