//تصاريخ الخروج عند الاداري
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'RequestDetailsScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExitPermitsScreen extends StatelessWidget {
  static final FirebaseFirestore firestore = FirebaseFirestore.instance;
  String? _schoolId;

  // دالة لاسترداد معرف المدرسة
  Future<void> _loadSchoolId() async {
    final prefs = await SharedPreferences.getInstance();
    _schoolId = prefs.getString('schoolId');
  }

  @override
  Widget build(BuildContext context) {
    // استدعاء الدالة لتحميل معرف المدرسة
    _loadSchoolId();

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
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder(
          future: _loadSchoolId(),
          builder: (context, snapshot) {
            if (_schoolId == null) {
              return Center(child: CircularProgressIndicator());
            }
            return StreamBuilder<QuerySnapshot>(
              stream:
                  firestore
                      .collection('requests') // استخدام نفس المجموعة عند الحفظ
                      .where(
                        'status',
                        isEqualTo: 'active',
                      ) // عرض الطلبات النشطة فقط
                      .where(
                        'schoolId',
                        isEqualTo: _schoolId,
                      ) // تصفية الطلبات حسب المدرسة
                      .orderBy(
                        'exitTime',
                        descending: true,
                      ) // ترتيب الطلبات حسب وقت الخروج
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text("خطأ: ${snapshot.error.toString()}"),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                final requests = snapshot.data!.docs;
                if (requests.isEmpty) {
                  return Center(
                    child: Text(
                      "لا توجد تصاريح نشطة حتى الآن.",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
                                  exitTime: DateFormat(
                                    'yyyy-MM-dd – HH:mm',
                                  ).format(exitTime),
                                  requestId: request.id, // تمرير معرف الطلب
                                ),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 4,
                        margin: EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "الطالب: ${data['studentName']}",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "الصف: ${data['grade']}",
                                style: TextStyle(fontSize: 14),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "المعلم: ${data['teacherName']}",
                                style: TextStyle(fontSize: 14),
                              ),
                              SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "وقت الخروج: ${DateFormat('hh:mm a').format(exitTime)}",
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () async {
                                      await _deleteRequest(request.id);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text("تم حذف الطلب بنجاح."),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  // دالة لحذف الطلب
  Future<void> _deleteRequest(String requestId) async {
    try {
      await firestore.collection('requests').doc(requestId).delete();
      print("✅ تم حذف الطلب بنجاح.");
    } catch (e) {
      print("❌ خطأ أثناء حذف الطلب: $e");
      rethrow;
    }
  }
}
