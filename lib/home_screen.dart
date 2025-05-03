import 'package:flutter/material.dart';
import 'package:mut6/login_employee_screen.dart';
import 'package:mut6/login_parent_screen.dart';
import 'package:mut6/login_screen.dart';
import 'package:mut6/widgets/custom_button.dart';

class HomeScreen extends StatelessWidget {
  final void Function(Locale)? setLocale;

  const HomeScreen({super.key, this.setLocale});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 30),
                Image.network(
                  'https://i.postimg.cc/DwnKf079/321e9c9d-4d67-4112-a513-d368fc26b0c0.jpg',
                  width: 280,
                  height: 189,
                ),
                const SizedBox(height: 70),
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
                CustomButton(
                  title: "ولي الأمر والوكيل",
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
      ),
    );
  }
}
