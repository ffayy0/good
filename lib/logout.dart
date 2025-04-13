import 'package:flutter/material.dart';

class LogoutScreen extends StatelessWidget {
  const LogoutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // المحتوى الرئيسي
            Container(
              color: Colors.white,
              child: const Center(
                child: Text(
                  'المحتوى هنا',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ),
            ),

            // زر تسجيل الخروج في الأعلى
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: drawerItem(
                  title: "تسجيل خروج",
                  icon: Icons.logout,
                  onTap: () {
                    // الانتقال إلى الصفحة الرئيسية
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/HomeScreen', // استبدلها بمسار الصفحة الرئيسية
                      (route) => false,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget drawerItem({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min, // حتى لا يمتد على كامل الشاشة
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
    );
  }
}
