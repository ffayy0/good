import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'attached excuses.dart';

class AdminStudentsListScreen extends StatefulWidget {
  final String stage;
  final String schoolClass;

  const AdminStudentsListScreen({
    super.key,
    required this.stage,
    required this.schoolClass,
  });

  @override
  _AdminStudentsListScreen createState() => _AdminStudentsListScreen();
}

class _AdminStudentsListScreen extends State<AdminStudentsListScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  Map<String, bool> students = {};
  String? teacherName;
  bool isLoading = true;
  String? selectedStudent;

  final Map<String, String> stageMap = {
    "أولى ابتدائي": "first",
    "ثاني ابتدائي": "second",
    "ثالث ابتدائي": "third",
  };

  @override
  void initState() {
    super.initState();
    fetchStudentsAndTeacher();
  }

  Future<void> fetchStudentsAndTeacher() async {
    try {
      final formattedStage =
          stageMap[widget.stage.trim()] ?? widget.stage.trim().toLowerCase();
      final studentSnapshot =
          await firestore
              .collection('stages')
              .doc(formattedStage)
              .collection(widget.schoolClass)
              .get();

      final teacherId =
          studentSnapshot.docs.isNotEmpty &&
                  studentSnapshot.docs.first.data().containsKey('teacherId')
              ? studentSnapshot.docs.first['teacherId']
              : null;

      if (teacherId != null) {
        final teacherSnapshot =
            await firestore.collection('teachers').doc(teacherId).get();
        teacherName =
            teacherSnapshot.exists &&
                    teacherSnapshot.data()!.containsKey('name')
                ? teacherSnapshot['name']
                : "غير محدد";
      } else {
        teacherName = "غير محدد";
      }

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
      print("خطأ أثناء جلب بيانات الطلاب أو المعلمة: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          onPressed: () {
            Navigator.pop(context);
          },
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
                            ),
                          );
                          return;
                        }
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AttachedExcuses(),
                          ),
                        );
                        setState(() {
                          students[selectedStudent!] = false;
                          selectedStudent = null;
                        });
                      },
                      color: Color.fromARGB(255, 1, 113, 189),
                      textColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      height: 50,
                      minWidth: double.infinity,
                      child: Text("موافق"),
                    ),
                  ],
                ),
              ),
    );
  }
}
