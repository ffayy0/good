import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class SchoolPasswordRecoveryScreen extends StatefulWidget {
  const SchoolPasswordRecoveryScreen({Key? key}) : super(key: key);

  @override
  _SchoolPasswordRecoveryScreenState createState() =>
      _SchoolPasswordRecoveryScreenState();
}

class _SchoolPasswordRecoveryScreenState
    extends State<SchoolPasswordRecoveryScreen> {
  final TextEditingController _emailController = TextEditingController();

  // دالة لتوليد كلمة مرور عشوائية
  String _generateRandomPassword() {
    const String chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(
      8,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  // دالة لإرسال كلمة المرور الجديدة إلى البريد الإلكتروني
  Future<void> _sendNewPasswordEmail(String email, String newPassword) async {
    final smtpServer = gmail('8ffaay01@gmail.com', 'vljn jaxv hukr qbct');
    // استبدل بالبيانات الخاصة بك
    final message =
        Message()
          ..from = Address('your-email@gmail.com', 'Password Recovery')
          ..recipients.add(email)
          ..subject = 'استعادة كلمة المرور'
          ..html = '''
        <html dir="rtl">
          <body>
            <p>مرحبًا،</p>
            <p>تم طلب استعادة كلمة المرور الخاصة بك.</p>
            <p>كلمة المرور الجديدة هي: <b>$newPassword</b></p>
            <p>يرجى تسجيل الدخول باستخدام هذه الكلمة والاحتفاظ بها في مكان آمن.</p>
            <p>تحياتنا،</p>
            <p>فريق متابع</p>
          </body>
        </html>
      ''';

    try {
      await send(message, smtpServer);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("تم إرسال كلمة المرور الجديدة إلى بريدك الإلكتروني"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("حدث خطأ أثناء إرسال البريد الإلكتروني"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // دالة لاستعادة كلمة المرور
  Future<void> _recoverPassword() async {
    String email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("الرجاء إدخال البريد الإلكتروني"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // البحث عن المستخدم باستخدام البريد الإلكتروني في Firestore
      var querySnapshot =
          await FirebaseFirestore.instance
              .collection('schools') // تأكد من أن هذه هي المجموعة الصحيحة
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        // إذا تم العثور على المستخدم، نحصل على بيانات المستخدم
        var userDoc = querySnapshot.docs.first;
        var userData = userDoc.data() as Map<String, dynamic>;
        String storedEmail = userData['email'];

        if (storedEmail == email) {
          // توليد كلمة مرور عشوائية جديدة
          String newPassword = _generateRandomPassword();

          // تحديث كلمة المرور في Firestore
          await FirebaseFirestore.instance.doc(userDoc.reference.path).update({
            'password': newPassword,
          });

          // إرسال كلمة المرور الجديدة إلى البريد الإلكتروني
          await _sendNewPasswordEmail(email, newPassword);

          Navigator.pop(context); // العودة إلى شاشة تسجيل الدخول
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("البريد الإلكتروني غير مطابق للبيانات المسجلة"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("البريد الإلكتروني غير موجود"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("❌ خطأ أثناء استعادة كلمة المرور: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("حدث خطأ أثناء استعادة كلمة المرور"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("استعادة كلمة المرور للمدرسة"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'أدخل البريد الإلكتروني لاستعادة كلمة المرور:',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            _buildInputField(
              _emailController,
              'البريد الإلكتروني',
              Icons.email,
            ),
            const SizedBox(height: 20),
            _buildActionButton('إرسال كلمة المرور الجديدة', _recoverPassword),
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
