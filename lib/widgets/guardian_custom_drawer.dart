import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mut6/home_screen.dart';

class GuardianCustomDrawer extends StatelessWidget {
  const GuardianCustomDrawer({super.key});

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      // توجيه إلى صفحة البداية (Home Screen) باستخدام MaterialPageRoute
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
          // مسافة صغيرة في الأعلى لتجنب أن يكون الخيار في أعلى الشاشة مباشرةً
          const SizedBox(height: 70),

          // خيار تسجيل الخروج بعد المسافة الصغيرة
          drawerItem(
            title: "تسجيل خروج",
            icon: Icons.logout,
            onTap: () => _signOut(context),
          ),

          // يمكنك إضافة المزيد من الخيارات هنا إذا كنت بحاجة
          const SizedBox(height: 10), // مسافة صغيرة بين الخيارات
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
            Icon(
              icon,
              color: const Color.fromARGB(255, 33, 150, 243),
              size: 22,
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
}
