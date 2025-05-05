import 'dart:async';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mut6/Classscreen.dart';
import 'package:mut6/alert_screen.dart';
import 'package:mut6/teacher_previous_requests_screen.dart';
import 'package:mut6/widgets/teacher_custom_drawer.dart';
import 'package:shared_preferences/shared_preferences.dart'; // إضافة SharedPreferences

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

  // دالة لفتح ClassScreen مع تمرير schoolId
  Future<void> _openClassScreen(BuildContext context) async {
    try {
      // استرداد schoolId من SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final schoolId = prefs.getString('schoolId') ?? '';
      if (schoolId.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("لا يمكن تحديد معرف المدرسة")));
        return;
      }
      print(
        "School ID from SharedPreferences: $schoolId",
      ); // ✅ طباعة schoolId للتحقق
      // تمرير schoolId إلى ClassScreen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => ClassScreen(schoolId: schoolId), // ✅ تمرير schoolId
        ),
      );
    } catch (e) {
      print("❌ خطأ أثناء استرداد معرف المدرسة: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("حدث خطأ أثناء فتح الصفحة")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // 🔽 تم تغيير لون الخلفية إلى أبيض نقي
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text("المعلمين", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
          ),
        ],
      ),
      endDrawer: TeacherCustomDrawer(),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.network(
              'https://i.postimg.cc/DwnKf079/321e9c9d-4d67-4112-a513-d368fc26b0c0.jpg',
            ),
            SizedBox(height: 20),
            Text(
              ":طلبات الخروج من الحصة",
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            ),
            SizedBox(height: 20),
            CustomButton(
              title: "طلب جديد",
              onPressed: () => _openClassScreen(context), // ✅ تعديل هنا
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
          ],
        ),
      ),
    );
  }
}
