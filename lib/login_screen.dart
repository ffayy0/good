import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mut6/GuardianPasswordRecoveryScreen.dart';
import 'package:mut6/SchoolPasswordRecoveryScreen.dart';
import 'package:mut6/School_screen.dart';
import 'package:mut6/registerr_screen.dart';

class LoginSchoolScreen extends StatefulWidget {
  const LoginSchoolScreen({Key? key}) : super(key: key);

  @override
  _LoginSchoolScreenState createState() => _LoginSchoolScreenState();
}

class _LoginSchoolScreenState extends State<LoginSchoolScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _login() async {
    try {
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      // عرض رسالة نجاح تسجيل الدخول باستخدام SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("تم تسجيل الدخول بنجاح!"),
          backgroundColor: Colors.green,
        ),
      );

      // الانتقال إلى شاشة المدرسة مباشرة بعد نجاح تسجيل الدخول
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  SchoolScreen(schoolName: userCredential.user?.email ?? ''),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = '';
      if (e.code == 'user-not-found') {
        errorMessage = "الحساب غير مسجل.";
      } else if (e.code == 'wrong-password' || e.code == 'invalid-email') {
        errorMessage = "البيانات المدخلة غير صحيحة.";
      } else {
        errorMessage = "حدث خطأ: ${e.message}";
      }

      // عرض رسالة الخطأ باستخدام SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green, // نفس درجة اللون الأخضر
        elevation: 0,
        title: const Text(
          "تسجيل دخول المدرسة",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // العودة إلى الشاشة السابقة
            Navigator.pop(context);
          },
        ),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              'https://i.postimg.cc/DwnKf079/321e9c9d-4d67-4112-a513-d368fc26b0c0.jpg',
              height: 180,
            ),
            const SizedBox(height: 30),
            _buildInputField(
              _emailController,
              'البريد الإلكتروني  ',
              Icons.person,
            ),
            const SizedBox(height: 10),
            _buildInputField(
              _passwordController,
              'كلمة المرور',
              Icons.lock,
              obscureText: true,
            ),
            const SizedBox(height: 20),
            _buildActionButton('تسجيل دخول', _login),
            const SizedBox(height: 10),
            _buildPasswordRecoveryButton(), // زر استعادة كلمة المرور

            const SizedBox(height: 20),
            const Text('إنشاء حساب جديد', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 5),
            _buildActionButton('تسجيل', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RegisterScreen()),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color.fromARGB(255, 1, 113, 189)),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.grey[300],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildPasswordRecoveryButton() {
    return TextButton(
      onPressed: () {
        // الانتقال إلى شاشة استعادة كلمة المرور
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SchoolPasswordRecoveryScreen(),
          ),
        );
      },
      child: const Text(
        'استعادة كلمة المرور',
        style: TextStyle(color: Color.fromARGB(255, 1, 113, 189), fontSize: 16),
      ),
    );
  }

  Widget _buildActionButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 1, 113, 189),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
    );
  }
}
