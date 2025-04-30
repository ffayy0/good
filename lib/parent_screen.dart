import 'package:flutter/material.dart';
import 'package:mut6/authorization_screen.dart';
import 'package:mut6/children_screen.dart';
import 'package:mut6/widgets/guardian_custom_drawer.dart';
import 'lib/screens/gardian_previous_requests_screen.dart';

class GuardianScreen extends StatelessWidget {
  final String guardianId; // معرف ولي الأمر المسجل

  const GuardianScreen({Key? key, required this.guardianId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false, // تعطيل زر الرجوع
        backgroundColor: Colors.green,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "ولي الأمر",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Builder(
            builder:
                (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () {
                    Scaffold.of(
                      context,
                    ).openEndDrawer(); // فتح القائمة الجانبية من الجهة اليمنى
                  },
                ),
          ),
        ],
      ),
      endDrawer:
          GuardianCustomDrawer(), // استخدام القائمة الجانبية من الجهة اليمنى
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // إضافة اللوجو هنا
            Image.network(
              'https://i.postimg.cc/DwnKf079/321e9c9d-4d67-4112-a513-d368fc26b0c0.jpg',
              width: 200,
              height: 189,
            ),
            const SizedBox(height: 30), // مسافة بين اللوجو والأزرار
            CustomButton(
              title: "سجل الحضور",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => ChildrenScreen(
                          guardianId: guardianId,
                          serviceType:
                              "attendance", // تحديد نوع الخدمة (الحضور)
                        ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            CustomButton(
              title: "طلب استئذان",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => ChildrenScreen(
                          guardianId: guardianId,
                          serviceType:
                              "permission", // تحديد نوع الخدمة (طلب الاستئذان)
                        ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            CustomButton(
              title: "طلب نداء",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => ChildrenScreen(
                          guardianId: guardianId,
                          serviceType:
                              "call_request", // تحديد نوع الخدمة (طلب النداء)
                        ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            CustomButton(
              title: "توكيل",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => AuthorizationScreen(
                          guardianId: guardianId, // تمرير معرف ولي الأمر
                        ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
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

// ودجة الزر المخصصة
class CustomButton extends StatelessWidget {
  final String title;
  final void Function()? onPressed;

  const CustomButton({super.key, required this.title, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: MaterialButton(
        height: 50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        color: const Color.fromARGB(255, 1, 113, 189),
        textColor: Colors.white,
        onPressed: onPressed,
        child: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
