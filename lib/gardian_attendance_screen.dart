import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // لاستخدام Firestore
import 'package:mut6/excuse_upload_screen.dart';

class AttendanceScreen extends StatelessWidget {
  final String studentId;
  final String guardianId; // إضافة معلمة guardianId

  AttendanceScreen({
    super.key,
    required this.studentId,
    required this.guardianId, // إضافة guardianId كمعلمة إجبارية
  });

  final List<Map<String, dynamic>> attendanceRecords = [
    {"day": "الأحد", "date": "٣/١", "status": "حاضر", "color": Colors.green},
    {
      "day": "الاثنين",
      "date": "٣/٢",
      "status": "متأخر",
      "color": Colors.orange,
    },
    {"day": "الثلاثاء", "date": "٣/٣", "status": "حاضر", "color": Colors.green},
    {"day": "الأربعاء", "date": "٣/٤", "status": "غائب", "color": Colors.red},
    {"day": "الخميس", "date": "٣/٥", "status": "حاضر", "color": Colors.green},
    {"day": "الأحد", "date": "٣/٨", "status": "حاضر", "color": Colors.green},
    {"day": "الاثنين", "date": "٣/٩", "status": "حاضر", "color": Colors.green},
    {
      "day": "الثلاثاء",
      "date": "٣/١٠",
      "status": "حاضر",
      "color": Colors.green,
    },
    {
      "day": "الأربعاء",
      "date": "٣/١١",
      "status": "حاضر",
      "color": Colors.green,
    },
  ];

  Future<Map<String, dynamic>?> _fetchStudentData(String studentId) async {
    try {
      // البحث عن الطالب في جميع المراحل والفصول
      final stages = ['first', 'second', 'third'];
      for (var stage in stages) {
        final classes = ['1', '2', '3', '4', '5', '6'];
        for (var schoolClass in classes) {
          final snapshot =
              await FirebaseFirestore.instance
                  .collection('stages')
                  .doc(stage)
                  .collection(schoolClass)
                  .doc(studentId)
                  .get();

          if (snapshot.exists) {
            return {
              "name": snapshot['name'],
              "schoolClass": "$schoolClass/$stage", // الصف الدراسي
            };
          }
        }
      }
      print("Student not found with ID: $studentId");
      return null;
    } catch (e) {
      print("Error fetching student data: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "سجل الحضور",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            FutureBuilder<Map<String, dynamic>?>(
              future: _fetchStudentData(studentId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError || !snapshot.hasData) {
                  return const Center(
                    child: Text("حدث خطأ أثناء جلب البيانات"),
                  );
                } else {
                  final studentData = snapshot.data!;
                  return Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "معلومات الطالب: ${studentData['name']}", // عرض اسم الطالب
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "الصف: ${studentData['schoolClass']}", // عرض الصف الدراسي
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        "الحالة",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "اليوم / التاريخ",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(thickness: 1),
                  Column(
                    children:
                        attendanceRecords.map((record) {
                          return InkWell(
                            onTap:
                                record["status"] == "غائب" ||
                                        record["status"] == "متأخر"
                                    ? () {
                                      // التنقل إلى صفحة ExcuseUploadScreen مع تمرير guardianId
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => ExcuseUploadScreen(
                                                day: record["day"],
                                                date: record["date"],
                                                status: record["status"],
                                                guardianId:
                                                    guardianId, // تمرير guardianId
                                              ),
                                        ),
                                      );
                                    }
                                    : null,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.circle,
                                        color: record["color"],
                                        size: 16,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        record["status"],
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    "${record["day"]} ${record["date"]}",
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
