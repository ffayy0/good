import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mut6/PasswordRecoveryScreen.dart';
import 'package:mut6/admin_screen.dart';
import 'package:mut6/home_screen.dart';
import 'package:mut6/providers/TeacherProvider.dart';
import 'package:mut6/teacher_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginEmployeeScreen extends StatefulWidget {
  const LoginEmployeeScreen({Key? key}) : super(key: key);

  @override
  _LoginEmployeeScreenState createState() => _LoginEmployeeScreenState();
}

class _LoginEmployeeScreenState extends State<LoginEmployeeScreen> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _login() async {
    try {
      String id = _idController.text.trim();
      String password = _passwordController.text.trim();

      if (id.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("الرجاء إدخال جميع الحقول"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      var adminQuery =
          await FirebaseFirestore.instance
              .collection('admins')
              .where('id', isEqualTo: id)
              .limit(1)
              .get();

      var teacherQuery =
          await FirebaseFirestore.instance
              .collection('teachers')
              .where('id', isEqualTo: id)
              .limit(1)
              .get();

      if (adminQuery.docs.isNotEmpty) {
        _validateAndNavigate(adminQuery.docs.first, password, "admin");
      } else if (teacherQuery.docs.isNotEmpty) {
        _validateAndNavigate(teacherQuery.docs.first, password, "teacher");
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("الحساب غير مسجل"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("❌ خطأ أثناء تسجيل الدخول: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("حدث خطأ أثناء تسجيل الدخول"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _validateAndNavigate(
    DocumentSnapshot userDoc,
    String password,
    String role,
  ) async {
    var userData = userDoc.data() as Map<String, dynamic>;
    String storedPassword = userData['password'];

    if (storedPassword != password) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("كلمة المرور غير صحيحة"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("تم تسجيل الدخول بنجاح!"),
        backgroundColor: Colors.green,
      ),
    );

    Widget nextScreen;
    if (role == "admin") {
      // حفظ schoolId في SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('schoolId', userData['schoolId']);

      nextScreen = const AdminScreen();
    } else {
      final teacherProvider = Provider.of<TeacherProvider>(
        context,
        listen: false,
      );
      teacherProvider.setTeacherData(userData['id'], userData['name']);

      int exitMinutes = userData['exitDuration'] ?? 10;
      nextScreen = StudyStageScreen(
        exitDuration: Duration(minutes: exitMinutes),
      );
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => nextScreen),
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

  Widget _buildPasswordRecoveryButton() {
    return TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PasswordRecoveryScreen()),
        );
      },
      child: const Text(
        'استعادة كلمة المرور',
        style: TextStyle(color: Color.fromARGB(255, 1, 113, 189), fontSize: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        title: const Text(
          "تسجيل دخول الموظفين",
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
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          },
        ),
      ),
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
            _buildInputField(_idController, 'رقم الهوية ', Icons.person),
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
            _buildPasswordRecoveryButton(),
          ],
        ),
      ),
    );
  }
}
