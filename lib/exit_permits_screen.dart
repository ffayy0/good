import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mut6/RequestDetailsScreen.dart';

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
        title: Text(
          "تصاريح الخروج من الحصة",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream:
              firestore
                  .collection('requests')
                  .where(
                    'status',
                    isEqualTo: 'active',
                  ) // عرض الطلبات النشطة فقط
                  .orderBy('exitTime', descending: true)
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text("خطأ: ${snapshot.error.toString()}"));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            final requests = snapshot.data!.docs;
            if (requests.isEmpty) {
              return Center(
                child: Text(
                  "لا توجد تصاريح حتى الآن.",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              );
            }
            return ListView.builder(
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final request = requests[index];
                final data = request.data() as Map<String, dynamic>;
                final exitTime = (data['exitTime'] as Timestamp).toDate();
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => RequestDetailsScreen(
                              studentName: data['studentName'],
                              grade: data['grade'],
                              teacherName: data['teacherName'],
                              exitTime: exitTime.toString(),
                              requestId: request.id, // تمرير معرف الطلب
                            ),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(bottom: 12),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "الطالبة: ${data['studentName']}",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "الصف: ${data['grade']}",
                          style: TextStyle(fontSize: 14),
                        ),
                        Text(
                          "المعلمة: ${data['teacherName']}",
                          style: TextStyle(fontSize: 14),
                        ),
                        Text(
                          "وقت الخروج: ${exitTime.hour}:${exitTime.minute}",
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
