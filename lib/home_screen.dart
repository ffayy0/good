import 'package:flutter/material.dart';
import 'package:mut6/login_screen.dart';
import 'login_employee_screen.dart'; // استيراد شاشة الموظفين
//import 'login_school_screen.dart'; // استيراد شاشة المدرسة
import 'login_parent_screen.dart'; // استيراد شاشة أولياء الأمور

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // شعار التطبيق
              Image.network(
                'https://i.postimg.cc/DwnKf079/321e9c9d-4d67-4112-a513-d368fc26b0c0.jpg', // رابط الصورة
                width: 280,
                height: 189,
              ),
              const SizedBox(height: 70),

              // زر "المدرسة"
              CustomButton(
                title: "المدرسة",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LoginSchoolScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              // زر "الموظفين"
              CustomButton(
                title: "الموظفين",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LoginEmployeeScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              // زر "ولي أمر الطالب"
              CustomButton(
                title: " ولي الأمر والوكيل",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LoginParentScreen(),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: const Color.fromARGB(255, 1, 113, 189),
        textColor: Colors.white,
        onPressed: onPressed,
        child: Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
