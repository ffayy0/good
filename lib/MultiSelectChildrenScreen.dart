import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mut6/authorization_screen.dart';

class MultiSelectChildrenScreen extends StatefulWidget {
  final String guardianId; // معرف ولي الأمر المسجل
  final String serviceType; // نوع الخدمة (مثل "التوكيل")
  const MultiSelectChildrenScreen({
    super.key,
    required this.guardianId,
    required this.serviceType,
  });

  @override
  _MultiSelectChildrenScreenState createState() =>
      _MultiSelectChildrenScreenState();
}

class _MultiSelectChildrenScreenState extends State<MultiSelectChildrenScreen> {
  late Future<List<Map<String, dynamic>>> _studentsFuture;
  Map<String, bool> selectedStudents = {}; // قائمة الطلاب المحددين

  @override
  void initState() {
    super.initState();
    _studentsFuture = _fetchStudentsByGuardianId(widget.guardianId);
  }

  // دالة لجلب بيانات الطلاب من Firestore
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
        });
      }
    } catch (e) {
      print("❌ خطأ أثناء جلب بيانات الطلاب: $e");
    }
    return students;
  }

  // دالة للتوجيه إلى الصفحة الصحيحة بناءً على الخدمة
  void _navigateToServiceScreen(List<Map<String, dynamic>> students) {
    // استخراج قائمة الطلاب المحددين
    List<Map<String, dynamic>> selectedStudentsList =
        students
            .where((student) => selectedStudents[student["id"]] == true)
            .toList();

    if (selectedStudentsList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("يرجى اختيار طالب واحد على الأقل")),
      );
      return;
    }

    // التحقق من أن نوع الخدمة هو "التوكيل"
    if (widget.serviceType == "delegation") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => AuthorizationScreen(
                //  students: selectedStudentsList, // تمرير قائمة الطلاب المحددين
                guardianId: widget.guardianId, // تمرير معرف ولي الأمر
              ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("خدمة غير مدعومة في هذه الصفحة")),
      );
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
                        final student = students[index];
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
                              Checkbox(
                                value: selectedStudents[student["id"]] ?? false,
                                onChanged: (value) {
                                  setState(() {
                                    selectedStudents[student["id"]] = value!;
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
                                  student["name"],
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
            ElevatedButton(
              onPressed: () {
                _studentsFuture.then((students) {
                  _navigateToServiceScreen(students);
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 1, 113, 189),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                minimumSize: Size(double.infinity, 50),
              ),
              child: const Text(
                "التالي",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
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
