import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ✅ تم الإضافة

class AddParentsScreen extends StatelessWidget {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final String senderEmail = "8ffaay01@gmail.com"; // ✉️ بريد المرسل
  final String senderPassword = "vljn jaxv hukr qbct"; // 🔑 كلمة مرور التطبيق
  final TextEditingController nameController = TextEditingController();
  final TextEditingController idController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final Color _iconColor = const Color(0xFF007AFF);
  final Color _buttonColor = Colors.green;
  final Color _textFieldFillColor = Colors.grey[100]!;
  final Color _textColor = Colors.black87;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _buttonColor,
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildTextField(nameController, "اسم ولي الأمر", Icons.person),
              const SizedBox(height: 10),
              _buildTextField(
                idController,
                "رقم الهوية",
                Icons.credit_card,
                isNumber: true,
              ),
              const SizedBox(height: 10),
              _buildTextField(
                phoneController,
                "الهاتف",
                Icons.phone,
                isNumber: true,
              ),
              const SizedBox(height: 10),
              _buildTextField(
                emailController,
                "البريد الإلكتروني",
                Icons.email,
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    String parentName = nameController.text.trim();
                    String parentId = idController.text.trim();
                    String phone = phoneController.text.trim();
                    String email = emailController.text.trim();

                    if (parentName.isEmpty ||
                        parentId.isEmpty ||
                        phone.isEmpty ||
                        email.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("جميع الحقول مطلوبة لإكمال العملية"),
                        ),
                      );
                      return;
                    }

                    if (parentName.split(' ').length < 3) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "اسم ولي الأمر يجب أن يكون ثلاثيًا على الأقل.",
                          ),
                        ),
                      );
                      return;
                    }

                    if (!phone.startsWith('05') || phone.length != 10) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "رقم الهاتف يجب أن يبدأ بـ 05 ويكون 10 أرقام.",
                          ),
                        ),
                      );
                      return;
                    }

                    final emailRegex = RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    );
                    if (!emailRegex.hasMatch(email)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("صيغة البريد الإلكتروني غير صحيحة."),
                        ),
                      );
                      return;
                    }

                    if (parentId.length != 10 ||
                        !RegExp(r'^\d{10}$').hasMatch(parentId)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "رقم الهوية يجب أن يتكون من 10 أرقام فقط.",
                          ),
                        ),
                      );
                      return;
                    }

                    bool isDuplicate = await isParentDuplicate(
                      parentId,
                      email,
                      phone,
                    );
                    if (isDuplicate) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "رقم الهوية أو البريد الإلكتروني أو الهاتف مسجل مسبقًا.",
                          ),
                        ),
                      );
                      return;
                    }

                    String password = generateRandomPassword();

                    // ✅ الحصول على schoolId من SharedPreferences
                    final SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    final String? _schoolId = prefs.getString('schoolId');

                    if (_schoolId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "لم يتم العثور على بيانات المدرسة. يرجى تسجيل الدخول مجددًا.",
                          ),
                        ),
                      );
                      return;
                    }

                    // ✅ إضافة ولي الأمر مع استخدام schoolId من SharedPreferences
                    await firestore.collection('parents').doc(parentId).set({
                      'id': parentId,
                      'name': parentName,
                      'phone': phone,
                      'email': email,
                      'password': password,
                      'role': 'parent',
                      'schoolId': _schoolId, // ✅ تم التحديث هنا
                      'createdAt': Timestamp.now(),
                    });

                    await sendEmail(email, parentName, parentId, password);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "تمت إضافة ولي الأمر وتم إرسال البريد بنجاح!",
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'إضافة ولي الأمر',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _buttonColor,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    minimumSize: Size(
                      MediaQuery.of(context).size.width / 2,
                      50,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> isParentDuplicate(String id, String email, String phone) async {
    var querySnapshot = await firestore.collection('parents').doc(id).get();
    if (querySnapshot.exists) return true;
    var queryEmail =
        await firestore
            .collection('parents')
            .where('email', isEqualTo: email)
            .get();
    if (queryEmail.docs.isNotEmpty) return true;
    var queryPhone =
        await firestore
            .collection('parents')
            .where('phone', isEqualTo: phone)
            .get();
    if (queryPhone.docs.isNotEmpty) return true;
    return false;
  }

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
              "مرحبًا $name،\n"
              "تم تسجيلك بنجاح في تطبيق متابع.\n"
              "بيانات تسجيل الدخول الخاصة بك:\n"
              "رقم ولي الأمر: $parentId\n"
              "كلمة المرور: $password\n"
              "يرجى تغيير كلمة المرور بعد تسجيل الدخول.\n"
              "تحياتنا، فريق متابع.";

    try {
      await send(message, smtpServer);
      print("📩 تم إرسال البريد الإلكتروني بنجاح إلى $recipientEmail");
    } catch (e) {
      print("❌ خطأ في إرسال البريد: $e");
    }
  }

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

  String generateRandomPassword() {
    const String chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(
      8,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

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
        labelStyle: const TextStyle(color: Colors.black54),
        border: OutlineInputBorder(),
        prefixIcon: Icon(icon, color: _iconColor),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: _iconColor),
        ),
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: _textFieldFillColor,
      ),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: _textColor),
    );
  }
}
