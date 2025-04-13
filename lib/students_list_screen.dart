import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'time_selection_screen.dart'; // استيراد صفحة تحديد الوقت

class StudentsListScreen extends StatefulWidget {
  final String stage;
  final String schoolClass;

  StudentsListScreen({required this.stage, required this.schoolClass});

  @override
  _StudentsListScreenState createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends State<StudentsListScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  Map<String, bool> students = {};
  String? teacherName; // اسم المعلمة
  bool isLoading = true; // حالة التحميل

  // خريطة لتحويل الأسماء العربية إلى الإنجليزية
  final Map<String, String> stageMap = {
    "أولى ثانوي": "first",
    "ثاني ثانوي": "second",
    "ثالث ثانوي": "third",
  };

  @override
  void initState() {
    super.initState();
    fetchStudentsAndTeacher();
  }

  Future<void> fetchStudentsAndTeacher() async {
    try {
      // تحويل المرحلة إلى اللغة الإنجليزية
      final formattedStage =
          stageMap[widget.stage.trim()] ?? widget.stage.trim().toLowerCase();
      final schoolClass = widget.schoolClass.trim();

      // استعلام Firestore للحصول على بيانات الطلاب
      final studentSnapshot =
          await firestore
              .collection('stages') // المجموعة الرئيسية
              .doc(formattedStage) // المرحلة (مثل "first")
              .collection(schoolClass) // الكلاس (مثل "1")
              .get();

      // طباعة المستندات المسترجعة للتحقق
      print(
        "المستندات المسترجعة: ${studentSnapshot.docs.map((doc) => doc.data())}",
      );

      // استرداد معرف المعلمة من أول مستند
      final teacherId =
          studentSnapshot.docs.isNotEmpty &&
                  studentSnapshot.docs.first.data().containsKey('teacherId')
              ? studentSnapshot.docs.first['teacherId']
              : null;

      if (teacherId != null) {
        // استعلام Firestore للحصول على اسم المعلمة
        final teacherSnapshot =
            await firestore
                .collection('teachers') // المجموعة الخاصة بالمعلمات
                .doc(teacherId) // معرف المعلمة
                .get();

        // التحقق من وجود المستند والحقل `name`
        if (teacherSnapshot.exists &&
            teacherSnapshot.data()!.containsKey('name')) {
          teacherName = teacherSnapshot['name'];
        } else {
          teacherName = "غير محدد";
          print("⚠️ لم يتم العثور على المعلم مع المعرف: $teacherId");
        }
      } else {
        teacherName = "غير محدد";
        print("⚠️ لم يتم العثور على معرف المعلم في بيانات الطلاب.");
      }

      if (mounted) {
        setState(() {
          // التحقق من وجود الحقل `name` في كل مستند
          students = Map.fromEntries(
            studentSnapshot.docs
                .where((doc) => doc.data().containsKey('name'))
                .map((doc) => MapEntry(doc['name'], false)),
          );
          isLoading = false; // إيقاف حالة التحميل
        });
      }
    } catch (e) {
      print("❌ خطأ أثناء جلب بيانات الطلاب أو المعلمة: $e");
      if (mounted) {
        setState(() {
          isLoading = false; // إيقاف حالة التحميل في حال حدوث خطأ
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
                                        onChanged: (bool? value) async {
                                          if (value == true) {
                                            // عند تحديد اسم الطالب، انتقل إلى صفحة تحديد الوقت
                                            await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (
                                                      context,
                                                    ) => TimeSelectionScreen(
                                                      studentName: key,
                                                      grade:
                                                          "${widget.stage} / ${widget.schoolClass}", // المرحلة والصف
                                                      teacherName:
                                                          teacherName ??
                                                          "غير محدد", // اسم المعلمة
                                                    ),
                                              ),
                                            );

                                            // إعادة تعيين حالة الـ Checkbox بعد العودة
                                            setState(() {
                                              students[key] = false;
                                            });
                                          } else {
                                            setState(() {
                                              students[key] = value!;
                                            });
                                          }
                                        },
                                        controlAffinity:
                                            ListTileControlAffinity.leading,
                                      );
                                    }).toList(),
                              ),
                    ),
                    MaterialButton(
                      onPressed: () {
                        // يمكنك إضافة وظيفة عند النقر على الزر "موافق"
                        print("تم تحديد الطلاب: $students");
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
