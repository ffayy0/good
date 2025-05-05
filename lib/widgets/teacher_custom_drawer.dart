import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:mut6/home_screen.dart';
import 'package:mut6/providers/TeacherProvider.dart';

class TeacherCustomDrawer extends StatelessWidget {
  Future<void> _signOut(BuildContext context) async {
    try {
      // تسجيل الخروج من Firebase
      await FirebaseAuth.instance.signOut();

      // مسح بيانات المعلم من TeacherProvider
      final teacherProvider = context.read<TeacherProvider>();
      teacherProvider.clearTeacherData();

      // التوجيه إلى الصفحة الرئيسية
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("فشل تسجيل الخروج: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 70),
          drawerItem(
            title: "تسجيل خروج",
            icon: Icons.logout,
            onTap: () => _signOut(context),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget drawerItem({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: Colors.blue, size: 22),
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
}
