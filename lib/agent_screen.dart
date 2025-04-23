import 'package:flutter/material.dart';
import 'package:mut6/widgets/guardian_custom_drawer.dart';
import 'AgentChildrenScreen.dart'; // صفحة التابعين
import 'children_screen.dart'; // صفحة التابعين

class AgentScreen extends StatelessWidget {
  final String agentId; // معرف الوكيل
  const AgentScreen({Key? key, required this.agentId}) : super(key: key);

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
                        ), // استخدام agentId هنا
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
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 1, 113, 189),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
