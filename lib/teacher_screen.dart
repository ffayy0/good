import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mut6/PreviousRequestsScreen.dart';
import 'package:mut6/class_screen.dart';
import 'package:mut6/widgets/teacher_custom_drawer.dart';
import 'alert_screen.dart'; // استيراد صفحة AlertScreen

class StudyStageScreen extends StatefulWidget {
  final Duration exitDuration; // المدة المحددة
  StudyStageScreen({required this.exitDuration});

  @override
  _StudyStageScreenState createState() => _StudyStageScreenState();
}

class _StudyStageScreenState extends State<StudyStageScreen>
    with WidgetsBindingObserver {
  DateTime? exitTime; // وقت انتهاء الطلب
  bool isTimerFinished = false; // لتحديد ما إذا انتهى المؤقت أم لا
  bool isTimerRunning = false; // لمنع تشغيل المؤقت أكثر من مرة
  bool isAlertShown = false; // لمنع عرض التنبيه أكثر من مرة

  // إضافة GlobalKey لفتح وإغلاق القائمة الجانبية
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    exitTime = DateTime.now().add(widget.exitDuration); // استخدام المدة المحددة
    startTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // عندما يعود المستخدم إلى التطبيق، تحقق من الوقت المتبقي
      if (exitTime != null &&
          DateTime.now().isAfter(exitTime!) &&
          !isAlertShown) {
        setState(() {
          isTimerFinished = true;
        });
        showAlertDialog();
      }
    }
  }

  void startTimer() {
    if (exitTime != null && !isTimerRunning) {
      Duration remainingTime = exitTime!.difference(DateTime.now());
      if (remainingTime > Duration.zero) {
        print("المؤقت بدأ. الوقت المتبقي: ${remainingTime.inSeconds} ثانية");
        isTimerRunning = true; // تعطيل تشغيل المؤقت مرة أخرى
        Timer(remainingTime, () {
          print("المؤقت انتهى!");
          setState(() {
            isTimerFinished = true;
          });
          showAlertDialog();
        });
      } else {
        print("الوقت قد انتهى بالفعل.");
        setState(() {
          isTimerFinished = true;
        });
        showAlertDialog();
      }
    }
  }

  void showAlertDialog() {
    if (!isAlertShown) {
      isAlertShown = true; // تعطيل عرض التنبيه مرة أخرى
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AlertScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, // إضافة المفتاح للتحكم في القائمة الجانبية
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text("المعلمين", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        automaticallyImplyLeading: false, // إزالة زر الرجوع
        actions: [
          IconButton(
            icon: Icon(Icons.menu, color: Colors.white), // أيقونة القائمة
            onPressed: () {
              _scaffoldKey.currentState
                  ?.openEndDrawer(); // فتح القائمة الجانبية
            },
          ),
        ],
      ),
      endDrawer: TeacherCustomDrawer(), // استخدام ملف TeacherCustomDrawer
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              ":طلبات الخروج من الحصة",
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            ),
            SizedBox(height: 20),
            CustomButton(
              title: "طلب جديد",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ClassScreen()),
                );
              },
            ),
            SizedBox(height: 15),
            CustomButton(
              title: "الطلبات السابقة",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PreviousRequestsScreen(),
                  ),
                );
              },
            ),
            // تم حذف النص "انتهت مدة الخروج!"
          ],
        ),
      ),
    );
  }
}

class CustomButton extends StatelessWidget {
  final String title;
  final VoidCallback? onPressed;
  const CustomButton({required this.title, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      height: 45,
      minWidth: 250,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      color: const Color.fromARGB(255, 1, 113, 189),
      textColor: Colors.white,
      onPressed: onPressed,
      child: Text(title, style: TextStyle(fontSize: 18)),
    );
  }
}
