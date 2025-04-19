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
    // جلب بيانات الطالب
    _studentDataFuture = _fetchStudentData(widget.studentId);
    // جلب سجل الحضور
    _attendanceRecordsFuture = _fetchAttendanceRecords(widget.studentId);
  }

  // دالة لجلب بيانات الطالب من Firestore
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

  // دالة لجلب سجل الحضور من Firestore
  Future<List<Map<String, dynamic>>> _fetchAttendanceRecords(
    String studentId,
  ) async {
    try {
      final attendanceSnapshot =
          await FirebaseFirestore.instance
              .collection('attendance')
              .where('studentId', isEqualTo: studentId)
              .orderBy(
                'date',
                descending: true,
              ) // ترتيب السجل حسب التاريخ بشكل تنازلي
              .get();

      return attendanceSnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print("❌ خطأ أثناء جلب سجل الحضور: $e");
      return [];
    }
  }

  // دالة للتحقق من وجود سجل حضور سابق لنفس اليوم
  Future<bool> _isAttendanceRecordedToday(String studentId) async {
    try {
      // الحصول على التاريخ الحالي بتنسيق yyyy-MM-dd
      String currentDate = DateTime.now().toString().split(' ')[0];

      // التحقق من وجود سجل حضور بنفس studentId والتاريخ الحالي
      final query =
          await FirebaseFirestore.instance
              .collection('attendance')
              .where('studentId', isEqualTo: studentId)
              .where('date', isEqualTo: currentDate)
              .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      print("❌ خطأ أثناء التحقق من سجل الحضور: $e");
      return false;
    }
  }

  // دالة لتسجيل الحضور
  Future<void> _markAttendance(String studentId) async {
    try {
      // التحقق من وجود سجل حضور سابق لنفس اليوم
      bool isRecorded = await _isAttendanceRecordedToday(studentId);
      if (isRecorded) {
        _showSnackBar('تم تسجيل الحضور لهذا الطالب اليوم بالفعل');
        return;
      }

      // الحصول على التاريخ الحالي
      String currentDate = DateTime.now().toString().split(' ')[0];

      // إضافة سجل حضور جديد إلى Firestore
      await FirebaseFirestore.instance.collection('attendance').add({
        'studentId': studentId,
        'status': 'حضور',
        'date': currentDate,
        'timestamp': Timestamp.now(),
      });

      _showSnackBar('تم تسجيل الحضور بنجاح');
    } catch (e) {
      print("❌ خطأ أثناء تسجيل الحضور: $e");
      _showSnackBar('حدث خطأ أثناء تسجيل الحضور');
    }
  }

  // عرض رسالة تنبيه
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text("تسجيل الحضور"),
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
        child: Column(
          children: [
            // عرض بيانات الطالب
            FutureBuilder<Map<String, dynamic>>(
              future: _studentDataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError || !snapshot.hasData) {
                  return Center(child: Text("حدث خطأ أثناء جلب بيانات الطالب"));
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
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 5),
                        Text(
                          "الصف: ${studentData['schoolClass']}",
                          style: TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 5),
                        Text(
                          "المرحلة: ${studentData['stage']}",
                          style: TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
            SizedBox(height: 20),

            // زر تسجيل الحضور
            ElevatedButton(
              onPressed: () {
                _markAttendance(widget.studentId);
              },
              child: Text('تسجيل الحضور'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 15),
                minimumSize: Size(MediaQuery.of(context).size.width / 2, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            SizedBox(height: 20),

            // عرض سجل الحضور
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _attendanceRecordsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError || !snapshot.hasData) {
                    return Center(
                      child: Text("حدث خطأ أثناء جلب بيانات الحضور"),
                    );
                  } else if (snapshot.data!.isEmpty) {
                    return Center(child: Text("لا توجد بيانات حضور متاحة"));
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
                              style: TextStyle(fontWeight: FontWeight.bold),
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
