import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // لاستيراد Firestore
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen({Key? key}) : super(key: key);

  @override
  _PasswordRecoveryScreenState createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  final TextEditingController _idController = TextEditingController();

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
    final smtpServer = gmail(
      '8ffaay01@gmail.com',
      'vljn jaxv hukr qbct',
    ); // استبدل بالبيانات الخاصة بك
    final message =
        Message()
          ..from = Address('8ffaay01@gmail.com', ' Mutabie')
          ..recipients.add(email)
          ..subject = 'استعادة كلمة المرور'
          ..html = '''
        <html dir="rtl">
          <body>
            <p>مرحبًا،</p>
            <p>تم طلب استعادة كلمة المرور الخاصة بك.</p>
            <p>كلمة المرور الجديدة هي: <b>$newPassword</b></p>
            <p>يرجى تسجيل الدخول باستخدام هذه الكلمة  .</p>
            <p>تحياتنا،</p>
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
    String id = _idController.text.trim();

    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("الرجاء إدخال الرقم الوظيفي"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // البحث عن المستخدم باستخدام رقم الهوية في Firestore
      var userQuery =
          await FirebaseFirestore.instance
              .collection('admins')
              .where('id', isEqualTo: id)
              .limit(1)
              .get();

      if (userQuery.docs.isEmpty) {
        // البحث في مجموعة المعلمين إذا لم يتم العثور على المستخدم في مجموعة الإداريين
        userQuery =
            await FirebaseFirestore.instance
                .collection('teachers')
                .where('id', isEqualTo: id)
                .limit(1)
                .get();
      }

      if (userQuery.docs.isNotEmpty) {
        // إذا تم العثور على المستخدم، نحصل على البريد الإلكتروني
        var userDoc = userQuery.docs.first;
        var userData = userDoc.data() as Map<String, dynamic>;
        String email = userData['email'];

        if (email.isNotEmpty) {
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
              content: Text("البريد الإلكتروني غير موجود في بياناتك"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("الرقم الوظيفي غير موجود"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("حدث خطأ أثناء استعادة كلمة المرور"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text("استعادة كلمة المرور"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'أدخل الرقم الوظيفي لاستعادة كلمة المرور:',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            _buildInputField(_idController, 'الرقم الوظيفي', Icons.person),
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
