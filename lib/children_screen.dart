import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mut6/helpsc.dart';
import 'request_permission_screen.dart'; // صفحة طلب الاستئذان
import 'attendence_screen.dart'; // صفحة عرض سجل الحضور
import 'call_screen.dart'; // صفحة طلب النداء

class ChildrenScreen extends StatefulWidget {
  final String guardianId; // معرف ولي الأمر المسجل
  final String serviceType; // نوع الخدمة المختارة

  const ChildrenScreen({
    Key? key,
    required this.guardianId,
    required this.serviceType,
  }) : super(key: key);

  @override
  _ChildrenScreenState createState() => _ChildrenScreenState();
}

class _ChildrenScreenState extends State<ChildrenScreen> {
  late Future<List<Map<String, dynamic>>> _studentsFuture;
  String? _selectedStudentId;

  @override
  void initState() {
    super.initState();
    _studentsFuture = _fetchStudentsByGuardianId(widget.guardianId);
  }

  Future<List<Map<String, dynamic>>> _fetchStudentsByGuardianId(
    String guardianId,
  ) async {
    List<Map<String, dynamic>> students = [];
    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('students')
              .where('guardianId', isEqualTo: guardianId)
              .get();

      for (var doc in querySnapshot.docs) {
        students.add({
          "id": doc['id'],
          "name": doc['name'],
          "schoolClass": doc['schoolClass'],
          "stage": doc['stage'],
          "schoolId": doc['schoolId'], // ✅ إضافة schoolId
        });
      }
    } catch (e) {
      print("❌ خطأ أثناء جلب بيانات الطلاب: $e");
    }
    return students;
  }

  void _navigateToServiceScreen(List<Map<String, dynamic>> students) {
    if (_selectedStudentId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("يرجى اختيار طالب واحد")));
      return;
    }

    final selectedStudent = students.firstWhere(
      (student) => student["id"] == _selectedStudentId,
    );

    switch (widget.serviceType) {
      case "attendance":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => GuardianAttendanceScreen(
                  studentId: selectedStudent["id"],
                  guardianId: widget.guardianId,
                  studentName: '',
                  childName: '',
                ),
          ),
        );
        break;

      case "permission":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => RequestPermissionScreen(
                  studentId: selectedStudent["id"],
                  studentName: selectedStudent["name"],
                  schoolId: selectedStudent["schoolId"], // ✅ تمرير schoolId
                ),
          ),
        );
        break;

      case "call_request":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => RequestHelpScreen(
                  studentId: selectedStudent["id"],
                  studentName: selectedStudent["name"],
                  schoolId: selectedStudent["schoolId"], // ✅ تمرير schoolId
                  // ملاحظة: إذا حبيت تمرر schoolId هنا أيضًا، خبرني أعدله لك
                ),
          ),
        );
        break;

      default:
        print("خدمة غير معروفة");
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
          "التابعين",
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
            const SizedBox(height: 30),
            // إضافة اللوجو هنا
            Image.network(
              'https://i.postimg.cc/DwnKf079/321e9c9d-4d67-4112-a513-d368fc26b0c0.jpg',
              width: 200,
              height: 189,
            ),
            const SizedBox(height: 30), // مسافة بين اللوجو والفقرات التالية
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _studentsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text("حدث خطأ: ${snapshot.error}"));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text("لا توجد طلاب مسجلين لهذا ولي الأمر."),
                    );
                  } else {
                    final students = snapshot.data!;
                    return ListView.builder(
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 15,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            textDirection: TextDirection.rtl,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Radio<String>(
                                value: students[index]["id"],
                                groupValue: _selectedStudentId,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedStudentId = value;
                                  });
                                },
                                activeColor: const Color.fromARGB(
                                  255,
                                  1,
                                  113,
                                  189,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  students[index]["name"],
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 1, 113, 189),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                onPressed: () {
                  _studentsFuture.then((students) {
                    _navigateToServiceScreen(students);
                  });
                },
                child: const Text(
                  "التالي",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
