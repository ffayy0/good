import 'package:flutter/material.dart';
import 'package:mut6/AgentChildrenScreen.dart';
import 'package:mut6/widgets/custom_button.dart';
import 'package:mut6/widgets/guardian_custom_drawer.dart';

class AgentScreen extends StatelessWidget {
  final String agentId; // معرف الوكيل
  final String guardianId; // معرف ولي الأمر

  const AgentScreen({
    super.key,
    required this.agentId,
    required this.guardianId,
  });

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
          "الوكيل",
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // إضافة اللوجو هنا
            Image.network(
              'https://i.postimg.cc/DwnKf079/321e9c9d-4d67-4112-a513-d368fc26b0c0.jpg',
              width: 200,
              height: 189,
            ),
            const SizedBox(height: 30), // مسافة بين اللوجو والزر
            // زر طلب النداء
            CustomButton(
              title: "طلب نداء",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => AgentChildrenScreen(
                          agentId: agentId,
                          guardianId: guardianId, // تمرير guardianId هنا
                        ),
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
