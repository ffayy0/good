import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:mut6/widgets/custom_button_auth.dart' show CustomButtonAuth;
import 'widgets/custom_text_field.dart' show CustomTextField;
import 'package:shared_preferences/shared_preferences.dart';

class AddTeacherScreen extends StatefulWidget {
  @override
  State<AddTeacherScreen> createState() => _AddTeacherScreenState();
}

class _AddTeacherScreenState extends State<AddTeacherScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController idController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController specialtyController = TextEditingController();
  final Color _iconColor = const Color(0xFF007AFF);
  final String senderEmail = "8ffaay01@gmail.com";
  final String senderPassword = "urwn frcb fzug ucyz";

  String? _schoolId;

  @override
  void initState() {
    super.initState();
    _loadSchoolId();
  }

  Future<void> _loadSchoolId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _schoolId = prefs.getString('schoolId');
    });
  }

  Future<String?> checkTeacherDuplicates(
    String id,
    String email,
    String phone,
  ) async {
    final firestore = FirebaseFirestore.instance;

    final idCheck = await firestore.collection('teachers').doc(id).get();
    if (idCheck.exists) return "رقم المعلم مستخدم من قبل.";

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

    if (_schoolId == null) {
      showSnackBar(
        context,
        "تعذر إضافة المعلم: لم يتم العثور على معرف المدرسة",
      );
      return;
    }

    if ([name, id, phone, email, specialty].any((e) => e.isEmpty)) {
      showSnackBar(context, "يجب ملء جميع الحقول قبل الإضافة");
      return;
    }

    if (name.split(' ').length < 3) {
      showSnackBar(context, "الرجاء إدخال الاسم الثلاثي على الأقل");
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

    if (!RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$',
    ).hasMatch(email)) {
      showSnackBar(context, "البريد الإلكتروني غير صحيح");
      return;
    }

    final idRegex = RegExp(r'^\d{10}$');
    if (!idRegex.hasMatch(id)) {
      showSnackBar(context, "رقم هوية المعلم يجب أن يتكون من 10 أرقام فقط");
      return;
    }

    if (specialty.isEmpty) {
      showSnackBar(context, "يرجى إدخال التخصص");
      return;
    }

    // التحقق من وجود أي نوع من الأرقام (إنجليزية أو عربية)
    if (specialty.contains(RegExp(r'[0-9\u0660-\u0669]'))) {
      showSnackBar(context, 'التخصص لا يجب أن يحتوي على أرقام');
      return;
    }

    // التحقق من أن التخصص يحتوي على أحرف فقط (بدون رموز أو أرقام)
    if (!RegExp(r'^[a-zA-Z\u0600-\u06FF]+$').hasMatch(specialty)) {
      showSnackBar(
        context,
        'التخصص يجب أن يحتوي على أحرف فقط بدون أرقام أو رموز',
      );
      return;
    }

    String? duplicateMessage = await checkTeacherDuplicates(id, email, phone);
    if (duplicateMessage != null) {
      showSnackBar(context, "⚠️ $duplicateMessage");
      return;
    }

    try {
      String password = generateRandomPassword();
      await FirebaseFirestore.instance.collection('teachers').doc(id).set({
        'name': name,
        'id': id,
        'phone': phone,
        'email': email,
        'specialty': specialty,
        'password': password,
        'schoolId': _schoolId, // ✅ تم التعديل هنا
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
        );
      case 'yahoo.com':
        return SmtpServer(
          'smtp.mail.yahoo.com',
          port: 587,
          username: email,
          password: password,
        );
      case 'icloud.com':
        return SmtpServer(
          'smtp.mail.me.com',
          port: 587,
          username: email,
          password: password,
        );
      case 'zoho.com':
        return SmtpServer(
          'smtp.zoho.com',
          port: 587,
          username: email,
          password: password,
          ssl: true,
        );
      default:
        return SmtpServer(
          'smtp.$domain',
          port: 587,
          username: email,
          password: password,
        );
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
    if (_schoolId == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
              iconColor: _iconColor,
            ),
            SizedBox(height: 15),
            CustomTextField(
              controller: idController,
              icon: Icons.badge,
              hintText: "رقم هوية المعلم",
              iconColor: _iconColor,
            ),
            SizedBox(height: 15),
            CustomTextField(
              controller: phoneController,
              icon: Icons.phone,
              hintText: "رقم الهاتف",
              iconColor: _iconColor,
            ),
            SizedBox(height: 15),
            CustomTextField(
              controller: emailController,
              icon: Icons.email,
              hintText: "البريد الإلكتروني",
              iconColor: _iconColor,
            ),
            SizedBox(height: 15),
            CustomTextField(
              controller: specialtyController,
              icon: Icons.school,
              hintText: "التخصص",
              iconColor: _iconColor,
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
