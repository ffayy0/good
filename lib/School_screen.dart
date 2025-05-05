import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // أضف هذا السطر
import 'package:mut6/RequestsListScreen.dart';
import 'widgets/custom_button_auth.dart';

class SchoolScreen extends StatelessWidget {
  final String schoolName;

  const SchoolScreen({Key? key, required this.schoolName}) : super(key: key);

  Future<void> _logout(BuildContext context) async {
    // امسح بيانات التخزين المحلي
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // يمسح schoolId وأي بيانات ثانية محفوظة

    print("تم تسجيل الخروج بنجاح");

    // الانتقال إلى شاشة البداية
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      endDrawer: Drawer(
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 50, right: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () {
                        _logout(context); // استخدم الدالة المحدثة
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "تسجيل خروج",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.exit_to_app, color: Colors.blue),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.network(
                    'https://i.postimg.cc/DwnKf079/321e9c9d-4d67-4112-a513-d368fc26b0c0.jpg',
                    width: 280,
                    height: 189,
                  ),
                  const SizedBox(height: 70),
                  CustomButtonAuth(
                    title: "الإداريين",
                    onPressed: () {
                      Navigator.pushNamed(context, '/AdminScreen');
                    },
                  ),
                  const SizedBox(height: 35),
                  CustomButtonAuth(
                    title: "إضافة إداري جديد",
                    onPressed: () {
                      Navigator.pushNamed(context, '/AddAdminScreen');
                    },
                  ),
                  const SizedBox(height: 35),
                  CustomButtonAuth(
                    title: "وقت تسجيل الحضور",
                    onPressed: () {
                      Navigator.pushNamed(context, '/SchoolDashboardScreen');
                    },
                  ),
                  const SizedBox(height: 35),
                  CustomButtonAuth(
                    title: "طلبات النداء",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => CallScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Builder(
                  builder: (context) {
                    return IconButton(
                      icon: Icon(Icons.menu, color: Colors.blue),
                      onPressed: () {
                        Scaffold.of(context).openEndDrawer();
                      },
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
}
