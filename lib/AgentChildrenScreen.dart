import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mut6/RequestsListScreen.dart';
import 'package:mut6/call_screen.dart';

class AgentChildrenScreen extends StatefulWidget {
  final String agentId; // معرف الوكيل
  const AgentChildrenScreen({
    super.key,
    required this.agentId,
    required String guardianId,
  });

  @override
  _AgentChildrenScreenState createState() => _AgentChildrenScreenState();
}

class _AgentChildrenScreenState extends State<AgentChildrenScreen> {
  late Future<List<Map<String, dynamic>>> _studentsFuture;
  Map<String, bool> selectedStudents = {}; // التابعين المختارين

  @override
  void initState() {
    super.initState();
    _studentsFuture = _fetchStudentsByAgentId(widget.agentId);
  }

  Future<List<Map<String, dynamic>>> _fetchStudentsByAgentId(
    String agentId,
  ) async {
    List<Map<String, dynamic>> students = [];
    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('AgentStudents')
              .where('agentId', isEqualTo: agentId)
              .get();

      for (var doc in querySnapshot.docs) {
        students.add({
          "id": doc['studentId'],
          "name": doc['studentName'],
          "stage": doc['stage'],
          "schoolClass": doc['schoolClass'],
        });
      }
    } catch (e) {
      print("❌ خطأ أثناء جلب بيانات التابعين: $e");
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
                        final studentId = student['id'];
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
                            children: [
                              Checkbox(
                                value: selectedStudents[studentId] ?? false,
                                onChanged: (value) {
                                  setState(() {
                                    selectedStudents[studentId] = value!;
                                  });
                                },
                                activeColor: Colors.blue,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      student["name"],
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "المرحلة: ${student['stage']}، الصف: ${student['schoolClass']}",
                                      style: const TextStyle(fontSize: 15),
                                      textAlign: TextAlign.right,
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.person, color: Colors.blue),
                            ],
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),

            // ✅ زر التالي تحت القائمة
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final selectedList =
                    selectedStudents.entries
                        .where((entry) => entry.value == true)
                        .map((entry) => entry.key)
                        .toList();

                if (selectedList.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('يرجى اختيار تابع واحد على الأقل')),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              RequestHelpScreen(studentId: '', studentName: ''),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 15),
                minimumSize: Size(double.infinity, 50),
              ),
              child: const Text(
                "التالي",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
