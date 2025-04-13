import 'package:flutter/material.dart';
import 'package:mut6/PreviousRequestsScreen.dart';
import 'package:mut6/home_screen.dart';
import '../widgets/custom_button.dart'; // استيراد الزر الصحيح
import '../widgets/custom_drawer.dart';
import 'exit_permits_screen.dart';
import 'class_screen.dart' hide CustomButton; // إخفاء الزر المتعارض

class AdminScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "الإداريين",
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
                    Scaffold.of(context).openEndDrawer();
                  },
                ),
          ),
        ],
      ),
      endDrawer: CustomDrawer(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.network(
                'https://i.postimg.cc/DwnKf079/321e9c9d-4d67-4112-a513-d368fc26b0c0.jpg',
                width: 200,
                height: 189,
              ),
              const SizedBox(height: 70),
              CustomButton(
                title: "طلبات الاستئذان",
                onPressed: () {
                  print("تم الضغط على طلبات الاستئذان");
                },
              ),
              const SizedBox(height: 35),
              CustomButton(
                title: "تصاريح الخروج من الحصة",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ExitPermitsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 35),
              CustomButton(
                title: "حضور الطلاب",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ClassScreen()),
                  );
                },
              ),
              const SizedBox(height: 35),
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
      ),
    );
  }
}
