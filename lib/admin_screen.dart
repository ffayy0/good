import 'package:flutter/material.dart';
import 'package:mut6/AdminAttendanceViewer.dart';
import 'package:mut6/Permission_screen.dart';
import 'package:mut6/exit_permits_screen.dart';
import 'package:mut6/teacher_previous_requests_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/custom_button.dart';
import '../widgets/custom_drawer.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  Future<void> _openAttendanceViewer(BuildContext context) async {
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
        builder: (context) => ClassAttendanceWithDate(schoolId: schoolId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
                onPressed: () async {
                  // استرداد schoolId من SharedPreferences
                  final prefs = await SharedPreferences.getInstance();
                  final schoolId = prefs.getString('schoolId') ?? '';

                  if (schoolId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("لا يمكن تحديد معرف المدرسة"),
                      ),
                    );
                    return;
                  }

                  // تمرير schoolId إلى PermissionScreen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => PermissionScreen(schoolId: schoolId),
                    ),
                  );
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
                onPressed: () => _openAttendanceViewer(context),
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
