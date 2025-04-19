import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

import 'widgets/custom_button.dart';
import 'widgets/custom_button_auth.dart';
import 'widgets/custom_text_field.dart';

class AddTeacherScreen extends StatelessWidget {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController idController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController specialtyController = TextEditingController();

  final String senderEmail = "8ffaay01@gmail.com";
  final String senderPassword = "urwn frcb fzug ucyz"; // App Password

  Future<String?> checkTeacherDuplicates(
    String id,
    String email,
    String phone,
  ) async {
    final firestore = FirebaseFirestore.instance;

    final idCheck =
        await firestore.collection('teachers').where('id', isEqualTo: id).get();
    if (idCheck.docs.isNotEmpty) return "رقم المعلم مستخدم من قبل.";

    final emailCheck =
        await firestore
            .collection('teachers')
            .where('email', isEqualTo: email)
            .get();
    if (emailCheck.docs.isNotEmpty) return "البريد الإلكتروني مستخدم من قبل.";

    final phoneCheck =
        await firestore
            .collection('teachers')
            .where('phone', isEqualTo: phone)
            .get();
    if (phoneCheck.docs.isNotEmpty) return "رقم الجوال مستخدم من قبل.";

    return null;
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

    // التحقق من الاسم الثلاثي
    if (name.split(' ').length < 3) {
      showSnackBar(context, "الرجاء إدخال الاسم الثلاثي على الأقل");
      return;
    }

    // التحقق من رقم الجوال
    final phoneRegex = RegExp(r'^05\d{8}$');
    if (!phoneRegex.hasMatch(phone)) {
      showSnackBar(
        context,
        "رقم الجوال غير صحيح. يجب أن يبدأ بـ 05 ويتكون من 10 أرقام",
      );
      return;
    }

    // التحقق من صيغة البريد
    if (!RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$',
    ).hasMatch(email)) {
      showSnackBar(context, "البريد الإلكتروني غير صحيح");
      return;
    }

    // التحقق من التكرار
    String? duplicateMessage = await checkTeacherDuplicates(id, email, phone);
    if (duplicateMessage != null) {
      showSnackBar(context, "⚠️ $duplicateMessage");
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

  // ✅ إرسال البريد الإلكتروني
  Future<void> sendEmail(
    String recipientEmail,
    String name,
    String teacherId,
    String password,
    String specialty,
  ) async {
    final smtpServer = getSmtpServer(senderEmail, senderPassword);

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
