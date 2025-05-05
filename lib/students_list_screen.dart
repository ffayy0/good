import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mut6/providers/TeacherProvider.dart';
import 'package:provider/provider.dart';
import 'time_selection_screen.dart';

class StudentsListScreen extends StatefulWidget {
  final String stage;
  final String schoolClass;

  StudentsListScreen({required this.stage, required this.schoolClass});

  @override
  _StudentsListScreenState createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends State<StudentsListScreen> {
  Map<String, bool> students = {};
  bool isLoading = true;
  String? selectedStudent;

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  Future<void> fetchStudents() async {
    try {
      final teacherProvider = Provider.of<TeacherProvider>(
        context,
        listen: false,
      );
      final schoolId = teacherProvider.schoolId;

      if (schoolId == null || schoolId.isEmpty) {
        throw Exception("معرف المدرسة غير متوفر في بيانات المعلم");
      }

      final studentSnapshot =
          await FirebaseFirestore.instance
              .collection('students')
              .where('stage', isEqualTo: widget.stage.trim())
              .where('schoolClass', isEqualTo: widget.schoolClass.trim())
              .where('schoolId', isEqualTo: schoolId.trim()) // الفلترة المهمة
              .get();

      print(
        "المستندات المسترجعة: ${studentSnapshot.docs.map((doc) => doc.data())}",
      );

      if (mounted) {
        setState(() {
          students = Map.fromEntries(
            studentSnapshot.docs
                .where((doc) => doc.data().containsKey('name'))
                .map((doc) => MapEntry(doc['name'], false)),
          );
          isLoading = false;
        });
      }
    } catch (e) {
      print("❌ خطأ أثناء جلب بيانات الطلاب: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final teacherProvider = Provider.of<TeacherProvider>(context);
    final teacherName = teacherProvider.teacherName ?? "غير محدد";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        centerTitle: true,
        title: Text(
          "${widget.stage} / ${widget.schoolClass}",
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Expanded(
                      child:
                          students.isEmpty
                              ? Center(child: Text("لم يتم العثور على طلاب"))
                              : ListView(
                                children:
                                    students.keys.map((String key) {
                                      return CheckboxListTile(
                                        title: Text(
                                          key,
                                          textAlign: TextAlign.right,
                                        ),
                                        value: students[key],
                                        onChanged: (bool? value) {
                                          setState(() {
                                            students.updateAll(
                                              (key, _) => false,
                                            );
                                            students[key] = value!;
                                            selectedStudent =
                                                students[key] == true
                                                    ? key
                                                    : null;
                                          });
                                        },
                                        controlAffinity:
                                            ListTileControlAffinity.leading,
                                        activeColor: Colors.blue,
                                      );
                                    }).toList(),
                              ),
                    ),
                    MaterialButton(
                      onPressed: () async {
                        if (selectedStudent == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("يرجى اختيار طالب واحد على الأقل"),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => TimeSelectionScreen(
                                  studentName: selectedStudent!,
                                  grade:
                                      "${widget.stage} / ${widget.schoolClass}",
                                ),
                          ),
                        );

                        setState(() {
                          students[selectedStudent!] = false;
                          selectedStudent = null;
                        });
                      },
                      color: Color.fromARGB(255, 1, 113, 189),
                      textColor: Colors.white,
                      child: Text("موافق"),
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
