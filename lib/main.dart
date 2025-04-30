import 'package:firebase_core/firebase_core.dart'; // استيراد Firebase Core
import 'package:flutter/material.dart';
import 'package:mut6/MapScreen.dart';
import 'package:mut6/SchoolDashboardScreen.dart';
import 'package:mut6/WelcomeScreen.dart';
import 'package:mut6/add_admin_screen.dart';
import 'package:mut6/home_screen.dart';
import 'package:mut6/login_screen.dart';
import 'package:mut6/map_picker_screen.dart';
import 'package:mut6/modifyAdminScreen.dart';
import 'package:mut6/provider.dart';
import 'package:mut6/providers/TeacherProvider.dart';
import 'package:provider/provider.dart'; // تأكد من استيراد شاشة إدارة المشرفين إذا كنت تستخدمها

void main() async {
  // تهيئة Widgets وFirebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // تهيئة Firebase
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => TeacherProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mutabie App', // اسم التطبيق
      initialRoute: '/', // المسار المبدئي للتطبيق
      routes: {
        '/': (context) => const WelcomeScreen(), // شاشة الترحيب
        '/login': (context) => LoginSchoolScreen(), // شاشة تسجيل الدخول
        '/AddAdminScreen': (context) => AddAdminScreen(), // شاشة إضافة مشرف
        '/AdminScreen': (context) => AdminListScreen(), // شاشة قائمة المشرفين
        '/MapScreen': (context) => MapScreen(), // إذا كنت تستخدم شاشة الخريطة
        '/SchoolDashboardScreen':
            (context) => SchoolDashboardScreen(), // إذا كنت تستخدم شاشة الخريطة
        '/map_picker': (context) => MapPickerScreen(),
        '/home': (context) => HomeScreen(),

        // يمكنك إضافة أي مسارات أخرى إذا كنت بحاجة إليها
      },
    );
  }
}
