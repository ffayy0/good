import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceScreen extends StatefulWidget {
  final String studentId; // معرف الطالب
  final String guardianId; // معرف ولي الأمر

  const AttendanceScreen({
    Key? key,
    required this.studentId,
    required this.guardianId,
  }) : super(key: key);

  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  late Future<Map<String, dynamic>> _studentDataFuture;
  late Future<List<Map<String, dynamic>>> _attendanceRecordsFuture;

  @override
  void initState() {
    super.initState();
    _studentDataFuture = _fetchStudentData(widget.studentId);
    _attendanceRecordsFuture = _fetchAttendanceRecords(widget.studentId);
  }

  // دالة لجلب بيانات الطالب
  Future<Map<String, dynamic>> _fetchStudentData(String studentId) async {
    try {
      final studentDoc =
          await FirebaseFirestore.instance
              .collection('students')
              .doc(studentId)
              .get();
      if (studentDoc.exists) {
        return studentDoc.data()!;
      } else {
        throw Exception("لم يتم العثور على بيانات الطالب");
      }
    } catch (e) {
      print("❌ خطأ أثناء جلب بيانات الطالب: $e");
      throw Exception("حدث خطأ أثناء جلب بيانات الطالب");
    }
  }

  // دالة لجلب سجل الحضور
  Future<List<Map<String, dynamic>>> _fetchAttendanceRecords(
    String studentId,
  ) async {
    try {
      final attendanceSnapshot =
          await FirebaseFirestore.instance
              .collection('attendance')
              .where('studentId', isEqualTo: studentId)
              .orderBy('date', descending: true)
              .get();
      return attendanceSnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print("❌ خطأ أثناء جلب سجل الحضور: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text("سجل الحضور"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // عرض بيانات الطالب
            FutureBuilder<Map<String, dynamic>>(
              future: _studentDataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError || !snapshot.hasData) {
                  return const Center(
                    child: Text("حدث خطأ أثناء جلب بيانات الطالب"),
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
                          "معلومات الطالب: ${studentData['name']}",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "الصف: ${studentData['schoolClass']}",
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "المرحلة: ${studentData['stage']}",
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 20),
            // عرض سجل الحضور
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _attendanceRecordsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError || !snapshot.hasData) {
                    return const Center(
                      child: Text("حدث خطأ أثناء جلب بيانات الحضور"),
                    );
                  } else if (snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text("لا توجد بيانات حضور متاحة"),
                    );
                  } else {
                    final attendanceRecords = snapshot.data!;
                    return ListView.builder(
                      itemCount: attendanceRecords.length,
                      itemBuilder: (context, index) {
                        final record = attendanceRecords[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          child: ListTile(
                            title: Text(
                              "التاريخ: ${record['date'] ?? 'غير محدد'}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              "الحالة: ${record['status'] ?? 'غير محدد'}",
                              style: TextStyle(
                                color:
                                    record['status'] == 'حضور'
                                        ? Colors.green
                                        : Colors.red,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
