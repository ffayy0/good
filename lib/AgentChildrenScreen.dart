import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AgentChildrenScreen extends StatefulWidget {
  final String agentId; // معرف الوكيل
  const AgentChildrenScreen({Key? key, required this.agentId})
    : super(key: key);

  @override
  _AgentChildrenScreenState createState() => _AgentChildrenScreenState();
}

class _AgentChildrenScreenState extends State<AgentChildrenScreen> {
  late Future<List<Map<String, dynamic>>> _studentsFuture;

  @override
  void initState() {
    super.initState();
    _studentsFuture = _fetchStudentsByAgentId(widget.agentId);
  }

  // دالة لجلب أسماء الطلاب المرتبطين بالوكيل من Firestore
  Future<List<Map<String, dynamic>>> _fetchStudentsByAgentId(
    String agentId,
  ) async {
    List<Map<String, dynamic>> students = [];
    try {
      // جلب جميع التوكيلات المرتبطة بالوكيل
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('AgentStudents') // مجموعة التوكيلات
              .where('agentId', isEqualTo: agentId)
              .get();

      for (var doc in querySnapshot.docs) {
        // لكل توكيل، استرداد بيانات الطالب من المجموعة students
        final studentSnapshot =
            await FirebaseFirestore.instance
                .collection('students')
                .doc(doc['studentId']) // معرف الطالب المرتبط بالتوكيل
                .get();

        if (studentSnapshot.exists) {
          students.add({
            "id": studentSnapshot.id,
            "name": studentSnapshot['name'], // اسم الطالب
          });
        } else {
          print(
            "⚠️ الطالب مع المعرف ${doc['studentId']} غير موجود في Firestore.",
          );
        }
      }
    } catch (e) {
      print("❌ خطأ أثناء جلب بيانات الطلاب: $e");
    }
    return students;
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
                      child: Text("لا توجد طلاب مسجلين لهذا الوكيل."),
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
                              const SizedBox(width: 10),
                              Icon(Icons.person, color: Colors.blue),
                            ],
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
