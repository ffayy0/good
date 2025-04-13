import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

import 'widgets/custom_button.dart';
import 'widgets/custom_text_field.dart';

class AddTeacherScreen extends StatelessWidget {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController idController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController specialtyController = TextEditingController();

  final String senderEmail = "8ffaay01@gmail.com";
  final String senderPassword = "urwn frcb fzug ucyz"; // App Password

  Future<bool> isTeacherDuplicate(String id, String email, String phone) async {
    var checks = await Future.wait([
      FirebaseFirestore.instance
          .collection('teachers')
          .where('id', isEqualTo: id)
          .get(),
      FirebaseFirestore.instance
          .collection('teachers')
          .where('email', isEqualTo: email)
          .get(),
      FirebaseFirestore.instance
          .collection('teachers')
          .where('phone', isEqualTo: phone)
          .get(),
    ]);
    return checks.any((snapshot) => snapshot.docs.isNotEmpty);
  }

  Future<void> addTeacher(BuildContext context) async {
    String name = nameController.text.trim();
    String id = idController.text.trim();
    String phone = phoneController.text.trim();
    String email = emailController.text.trim();
    String specialty = specialtyController.text.trim();

    if ([name, id, phone, email, specialty].any((element) => element.isEmpty)) {
      showSnackBar(context, "يجب ملء جميع الحقول قبل الإضافة");
      return;
    }

    final phoneRegex = RegExp(r'^05\d{8}$');
    if (!phoneRegex.hasMatch(phone)) {
      showSnackBar(
        context,
        "رقم الجوال غير صحيح. يجب أن يبدأ بـ 05 ويتكون من 10 أرقام",
      );
      return;
    }

    bool isDuplicate = await isTeacherDuplicate(id, email, phone);
    if (isDuplicate) {
      showSnackBar(context, "هذا المعلم مسجل مسبقًا، لا يمكن تكرار البيانات.");
      return;
    }

    try {
      String password = generateRandomPassword();
      await FirebaseFirestore.instance.collection('teachers').add({
        'name': name,
        'id': id,
        'phone': phone,
        'email': email,
        'specialty': specialty,
        'password': password,
        'createdAt': Timestamp.now(),
      });

      await sendEmail(email, name, id, password, specialty);
      showSnackBar(
        context,
        "تمت إضافة المعلم بنجاح، وتم إرسال كلمة المرور عبر البريد",
      );

      nameController.clear();
      idController.clear();
      phoneController.clear();
      emailController.clear();
      specialtyController.clear();
    } catch (e) {
      print("❌ خطأ أثناء الإضافة: $e");
      showSnackBar(context, "حدث خطأ أثناء الإضافة");
    }
  }

  Future<void> sendEmail(
    String recipientEmail,
    String name,
    String teacherId,
    String password,
    String specialty,
  ) async {
    final smtpServer = gmail(senderEmail, senderPassword);

    final message =
        Message()
          ..from = Address(senderEmail, 'Mutabie App')
          ..recipients.add(recipientEmail)
          ..subject = 'تم تسجيلك كمعلم في تطبيق متابع'
          ..headers['X-Priority'] = '1'
          ..headers['X-MSMail-Priority'] = 'High'
          ..text =
              'مرحبًا $name،\n\nتم تسجيلك بنجاح في تطبيق متابع.\nرقم المعلم: $teacherId\nالتخصص: $specialty\nكلمة المرور: $password\n\nتحياتنا، فريق متابع.'
          ..html = """
        <html>
          <body style="font-family: Arial; direction: rtl;">
            <h3>مرحبًا $name،</h3>
            <p>تم تسجيلك بنجاح في <strong>تطبيق متابع</strong>.</p>
            <p>
              <strong>رقم المعلم:</strong> $teacherId<br>
              <strong>التخصص:</strong> $specialty<br>
              <strong>كلمة المرور:</strong> $password
            </p>
            <p>يرجى تغيير كلمة المرور بعد تسجيل الدخول.</p>
            <p>تحياتنا،<br>فريق متابع</p>
          </body>
        </html>
      """;

    try {
      await send(message, smtpServer);
    } catch (e) {
      print("❌ فشل في إرسال الإيميل: $e");
    }
  }

  String generateRandomPassword() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(
      8,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text("إضافة معلم", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            CustomTextField(
              controller: nameController,
              icon: Icons.person,
              hintText: "اسم المعلم",
            ),
            SizedBox(height: 15),
            CustomTextField(
              controller: idController,
              icon: Icons.badge,
              hintText: "رقم المعلم",
            ),
            SizedBox(height: 15),
            CustomTextField(
              controller: phoneController,
              icon: Icons.phone,
              hintText: "رقم الهاتف",
            ),
            SizedBox(height: 15),
            CustomTextField(
              controller: emailController,
              icon: Icons.email,
              hintText: "البريد الإلكتروني",
            ),
            SizedBox(height: 15),
            CustomTextField(
              controller: specialtyController,
              icon: Icons.school,
              hintText: "التخصص",
            ),
            SizedBox(height: 20),
            CustomButtonAuth(
              title: "إضافة",
              onPressed: () async => await addTeacher(context),
              color: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }
}
