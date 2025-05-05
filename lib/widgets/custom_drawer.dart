import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mut6/AddTeacherScreen.dart';
import 'package:mut6/BarcodeScannerScreen.dart' as barcode;
import 'package:mut6/StudentSearchScreen.dart';
import 'package:mut6/add_parents_screen.dart';
import 'package:mut6/add_students_screen.dart' as student;
import 'package:mut6/add_teachers_screen.dart';
import 'package:mut6/home_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:typed_data';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({super.key});

  @override
  _CustomDrawerState createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  final bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          drawerItem(
            title: "إضافة أولياء الأمور",
            iconText: "+",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddParentsScreen()),
              );
            },
          ),
          drawerItem(
            title: "إضافة طلاب",
            iconText: "+",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => student.StudentBarcodeScreen(),
                ),
              );
            },
          ),
          drawerItem(
            title: "إضافة معلمين",
            iconText: "+",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddTeacherScreen()),
              );
            },
          ),
          drawerItem(
            title: "المعلمين",
            icon: Icons.person,
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              final schoolId = prefs.getString('schoolId') ?? '';

              if (schoolId.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("لا يمكن تحديد معرف المدرسة")),
                );
                return;
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TeachersListScreen(schoolId: schoolId),
                ),
              );
            },
          ),
          drawerItem(
            title: "مسح الباركود",
            icon: Icons.qr_code_scanner,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => barcode.BarcodeScannerScreen(),
                ),
              );
            },
          ),
          drawerItem(
            title: "استعلام عن بيانات طالب",
            icon: Icons.search,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => StudentSearchScreen()),
              );
            },
          ),
          const Spacer(),
          drawerItem(
            title: "تسجيل خروج",
            icon: Icons.logout,
            onTap: () => _logout(context),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget drawerItem({
    required String title,
    IconData? icon,
    String? iconText,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            if (icon != null)
              Icon(icon, color: Colors.blue, size: 24)
            else if (iconText != null)
              Text(
                iconText,
                style: const TextStyle(fontSize: 24, color: Colors.blue),
              ),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _logout(BuildContext context) async {
    try {
      // حذف بيانات SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // تسجيل الخروج من Firebase
      await FirebaseAuth.instance.signOut();

      // التنقل إلى صفحة البداية
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      print("❌ خطأ في تسجيل الخروج: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('فشل تسجيل الخروج: $e')));
    }
  }
}
