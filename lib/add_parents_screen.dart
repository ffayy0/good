import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class AddParentsScreen extends StatelessWidget {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final String senderEmail = "8ffaay01@gmail.com"; // ✉️ بريد المرسل
  final String senderPassword = "vljn jaxv hukr qbct"; // 🔑 كلمة مرور التطبيق

  // ✅ تعريف المتحكمات
  final TextEditingController nameController = TextEditingController();
  final TextEditingController idController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  // تحديد اللون الأزرق الفاتح المستخدم للأيقونات والزر
  final Color _buttonColor = Color(0xFF0171BD); // الأزرق الفاتح
  final Color _textFieldFillColor = Colors.grey[200]!; // اللون الرمادي الفاتح
  final Color _textColor = const Color.fromARGB(
    255,
    12,
    68,
    114,
  ); // تغيير النص إلى الأزرق داخل المربعات

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "إضافة أولياء الأمور",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            _buildTextField(nameController, "اسم ولي الأمر", Icons.person),
            SizedBox(height: 10),
            _buildTextField(
              idController,
              "رقم الهوية",
              Icons.credit_card,
              isNumber: true,
            ),
            SizedBox(height: 10),
            _buildTextField(
              phoneController,
              "الهاتف",
              Icons.phone,
              isNumber: true,
            ),
            SizedBox(height: 10),
            _buildTextField(emailController, "البريد الإلكتروني", Icons.email),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                // يتم أخذ البيانات من الحقول المدخلة
                String parentName = nameController.text;
                String parentId = idController.text;
                String phone = phoneController.text;
                String email = emailController.text;

                bool isDuplicate = await isParentDuplicate(
                  parentId,
                  email,
                  phone,
                );
                if (isDuplicate) {
                  print("⚠️ ولي الأمر $parentName مسجل مسبقًا، لم يتم إضافته.");
                  return;
                }

                // توليد كلمة مرور عشوائية
                String password = generateRandomPassword();

                // إضافة البيانات إلى Firebase
                await firestore.collection('parents').add({
                  'id': parentId,
                  'name': parentName,
                  'phone': phone,
                  'email': email,
                  'password': password,
                  'createdAt': Timestamp.now(),
                });

                // إرسال البريد الإلكتروني
                await sendEmail(email, parentName, parentId, password);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "تمت إضافة ولي الأمر وتم إرسال البريد بنجاح!",
                    ),
                  ),
                );
              },
              child: Text('إضافة ولي الأمر'),
              style: ElevatedButton.styleFrom(backgroundColor: _buttonColor),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ التحقق من تكرار بيانات ولي الأمر
  Future<bool> isParentDuplicate(String id, String email, String phone) async {
    var querySnapshot =
        await firestore.collection('parents').where('id', isEqualTo: id).get();
    if (querySnapshot.docs.isNotEmpty) return true;

    querySnapshot =
        await firestore
            .collection('parents')
            .where('email', isEqualTo: email)
            .get();
    if (querySnapshot.docs.isNotEmpty) return true;

    querySnapshot =
        await firestore
            .collection('parents')
            .where('phone', isEqualTo: phone)
            .get();
    if (querySnapshot.docs.isNotEmpty) return true;

    return false;
  }

  // ✅ إرسال البريد الإلكتروني
  Future<void> sendEmail(
    String recipientEmail,
    String name,
    String parentId,
    String password,
  ) async {
    final smtpServer = getSmtpServer(senderEmail, senderPassword);

    final message =
        Message()
          ..from = Address(senderEmail, "Mutabie App")
          ..recipients.add(recipientEmail)
          ..subject = "تفاصيل حسابك كولي أمر"
          ..text =
              "مرحبًا $name،\n\n"
              "تم تسجيلك بنجاح في تطبيق متابع.\n"
              "بيانات تسجيل الدخول الخاصة بك:\n"
              "رقم ولي الأمر: $parentId\n"
              "كلمة المرور: $password\n\n"
              "يرجى تغيير كلمة المرور بعد تسجيل الدخول.\n\n"
              "تحياتنا، فريق متابع.";

    try {
      await send(message, smtpServer);
      print("📩 تم إرسال البريد الإلكتروني بنجاح إلى $recipientEmail");
    } catch (e) {
      print("❌ خطأ في إرسال البريد: $e");
    }
  }

  // ✅ اختيار SMTP بناءً على نوع البريد
  SmtpServer getSmtpServer(String email, String password) {
    String domain = email.split('@').last.toLowerCase();

    switch (domain) {
      case 'gmail.com':
        return gmail(email, password);
      case 'outlook.com':
      case 'hotmail.com':
      case 'live.com':
        return SmtpServer(
          'smtp.office365.com',
          port: 587,
          username: email,
          password: password,
          ssl: false,
          allowInsecure: true,
        );
      case 'yahoo.com':
        return SmtpServer(
          'smtp.mail.yahoo.com',
          port: 587,
          username: email,
          password: password,
          ssl: false,
          allowInsecure: true,
        );
      case 'icloud.com':
        return SmtpServer(
          'smtp.mail.me.com',
          port: 587,
          username: email,
          password: password,
          ssl: false,
          allowInsecure: true,
        );
      case 'zoho.com':
        return SmtpServer(
          'smtp.zoho.com',
          port: 587,
          username: email,
          password: password,
          ssl: true,
          allowInsecure: false,
        );
      default:
        return SmtpServer(
          'smtp.$domain',
          port: 587,
          username: email,
          password: password,
          ssl: false,
          allowInsecure: true,
        );
    }
  }

  // ✅ توليد كلمة مرور عشوائية
  String generateRandomPassword() {
    const String chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(
      8,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  // ✅ بناء حقل النص بشكل مشترك (مشابه للطلاب)
  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: _buttonColor),
        border: OutlineInputBorder(),
        prefixIcon: Icon(icon, color: _buttonColor), // نفس اللون للأيقونة
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: _buttonColor),
        ),
        hintStyle: TextStyle(color: _textColor), // تغيير النص إلى اللون الأزرق
        filled: true,
        fillColor: _textFieldFillColor, // خلفية حقل الإدخال
      ),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
    );
  }
}
