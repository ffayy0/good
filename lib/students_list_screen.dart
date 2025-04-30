import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mut6/providers/TeacherProvider.dart';
import 'package:provider/provider.dart';
import 'time_selection_screen.dart'; // استيراد صفحة تحديد الوقت

class StudentsListScreen extends StatefulWidget {
  final String stage;
  final String schoolClass;

  StudentsListScreen({required this.stage, required this.schoolClass});

  @override
  _StudentsListScreenState createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends State<StudentsListScreen> {
  Map<String, bool> students = {};
  bool isLoading = true; // حالة التحميل
  String? selectedStudent; // الطالب المحدد

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  Future<void> fetchStudents() async {
    try {
      // استعلام Firestore للحصول على بيانات الطلاب
      final studentSnapshot =
          await FirebaseFirestore.instance
              .collection('students')
              .where('stage', isEqualTo: widget.stage.trim())
              .where('schoolClass', isEqualTo: widget.schoolClass.trim())
              .get();

      // طباعة المستندات المسترجعة للتحقق
      print(
        "المستندات المسترجعة: ${studentSnapshot.docs.map((doc) => doc.data())}",
      );

      if (mounted) {
        setState(() {
          // التحقق من وجود الحقل name في كل مستند
          students = Map.fromEntries(
            studentSnapshot.docs
                .where((doc) => doc.data().containsKey('name'))
                .map((doc) => MapEntry(doc['name'], false)),
          );
          isLoading = false; // إيقاف حالة التحميل
        });
      }
    } catch (e) {
      print("❌ خطأ أثناء جلب بيانات الطلاب: $e");
      if (mounted) {
        setState(() {
          isLoading = false; // إيقاف حالة التحميل في حال حدوث خطأ
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // الحصول على اسم المعلم من TeacherProvider
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
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator()) // عرض مؤشر التحميل
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
                                            // إعادة تعيين جميع الخيارات
                                            students.updateAll(
                                              (key, _) => false,
                                            );
                                            // تحديد الطالب الجديد
                                            students[key] = value!;
                                            // تخزين اسم الطالب المحدد
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
                        // التحقق مما إذا تم اختيار طالب واحد على الأقل
                        if (selectedStudent == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("يرجى اختيار طالب واحد على الأقل"),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        // الانتقال إلى صفحة تحديد الوقت
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => TimeSelectionScreen(
                                  studentName: selectedStudent!,
                                  grade:
                                      "${widget.stage} / ${widget.schoolClass}", // المرحلة والصف
                                ),
                          ),
                        );

                        // إعادة تعيين الطالب المحدد بعد العودة
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
