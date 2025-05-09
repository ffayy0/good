import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mut6/providers/TeacherProvider.dart';
import 'package:mut6/teacher_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TimeSelectionScreen extends StatefulWidget {
  final String studentName;
  final String grade;

  TimeSelectionScreen({required this.studentName, required this.grade});

  @override
  _TimeSelectionScreenState createState() => _TimeSelectionScreenState();
}

class _TimeSelectionScreenState extends State<TimeSelectionScreen> {
  bool isTenMinutesSelected = false;
  bool isOtherSelected = false;
  Duration selectedDuration = Duration(minutes: 3); // المدة الافتراضية
  String? _schoolId; // لإضافة معرف المدرسة

  @override
  void initState() {
    super.initState();
    _loadSchoolId(); // استدعاء الدالة لتحميل معرف المدرسة
  }

  Future<void> _loadSchoolId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _schoolId = prefs.getString('schoolId'); // استرداد معرف المدرسة
    });
  }

  void _showTimerPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext builder) {
        return Container(
          height: 250,
          child: CupertinoTimerPicker(
            mode: CupertinoTimerPickerMode.ms,
            initialTimerDuration: selectedDuration,
            onTimerDurationChanged: (Duration newDuration) {
              setState(() {
                selectedDuration = newDuration;
              });
            },
          ),
        );
      },
    );
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
        title: Text("تحديد الوقت", style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "اسم الطالب: ${widget.studentName}",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              "اسم المعلم: $teacherName",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Checkbox(
                  value: isTenMinutesSelected,
                  onChanged: (bool? value) {
                    setState(() {
                      isTenMinutesSelected = value!;
                      isOtherSelected = false;
                      selectedDuration = Duration(minutes: 10);
                    });
                  },
                  activeColor:
                      Colors.blue, // تغيير لون المربع إلى الأزرق عند اختياره
                ),
                Text("10 دقائق"),
                SizedBox(width: 20),
                Checkbox(
                  value: isOtherSelected,
                  onChanged: (bool? value) {
                    setState(() {
                      isOtherSelected = value!;
                      isTenMinutesSelected = false;
                    });
                  },
                  activeColor:
                      Colors.blue, // تغيير لون المربع إلى الأزرق عند اختياره
                ),
                GestureDetector(
                  onTap:
                      isOtherSelected ? () => _showTimerPicker(context) : null,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Text(
                          isOtherSelected
                              ? "${selectedDuration.inMinutes} دقيقة"
                              : "أخرى",
                          style: TextStyle(color: Colors.black),
                        ),
                        SizedBox(width: 5),
                        Icon(Icons.arrow_drop_down, color: Colors.black),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Spacer(),
            MaterialButton(
              onPressed: () async {
                try {
                  // التحقق من اختيار المدة
                  if (!isTenMinutesSelected && !isOtherSelected) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("حدد المدة أولا"),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // التحقق من أن المدة ليست أقل من دقيقتين
                  if (selectedDuration < Duration(minutes: 2)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("لا يمكن اختيار مدة أقل من دقيقتين"),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // التحقق من توفر schoolId
                  if (_schoolId == null || _schoolId!.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("لم يتم تحديد معرف المدرسة"),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // حساب وقت الخروج بناءً على الوقت الحالي والمدة المحددة
                  DateTime now = DateTime.now();
                  DateTime exitTime = now.add(selectedDuration);

                  // إضافة الطلب إلى Firestore مع إضافة schoolId
                  await FirebaseFirestore.instance.collection('requests').add({
                    'studentName': widget.studentName,
                    'grade': widget.grade,
                    'teacherName': teacherName,
                    'exitTime': Timestamp.fromDate(
                      exitTime,
                    ), // تخزين الوقت كـ Timestamp
                    'status': 'active', // الحالة الافتراضية للطلب
                    'schoolId': _schoolId, // إضافة معرف المدرسة
                  });

                  // التنقل إلى الصفحة الرئيسية مع تمرير المدة المحددة
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              StudyStageScreen(exitDuration: selectedDuration),
                    ),
                    (route) => false,
                  );
                } catch (e) {
                  print("حدث خطأ: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("حدث خطأ أثناء معالجة الطلب"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              color: Color.fromARGB(255, 1, 113, 189),
              textColor: Colors.white,
              child: Text("تأكيد"),
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
