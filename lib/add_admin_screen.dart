import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'widgets/custom_button_auth.dart';
import 'widgets/custom_text_field.dart';

class AddAdminScreen extends StatelessWidget {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController idController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  final String senderEmail = "8ffaay01@gmail.com"; // ✉️ بريد المشرف
  final String senderPassword =
      "vljn jaxv hukr qbct"; // 🔑 كلمة مرور التطبيق (App Password)

  Future<bool> isAdminDuplicate(String id, String email, String phone) async {
    var querySnapshot =
        await FirebaseFirestore.instance
            .collection('admins')
            .where('id', isEqualTo: id)
            .get();
    if (querySnapshot.docs.isNotEmpty) return true;

    querySnapshot =
        await FirebaseFirestore.instance
            .collection('admins')
            .where('email', isEqualTo: email)
            .get();
    if (querySnapshot.docs.isNotEmpty) return true;

    querySnapshot =
        await FirebaseFirestore.instance
            .collection('admins')
            .where('phone', isEqualTo: phone)
            .get();
    if (querySnapshot.docs.isNotEmpty) return true;

    return false;
  }

  Future<void> addAdmin(BuildContext context) async {
    String name = nameController.text.trim();
    String id = idController.text.trim();
    String phone = phoneController.text.trim();
    String email = emailController.text.trim();

    if ([name, id, phone, email].any((element) => element.isEmpty)) {
      showSnackBar(context, "يجب ملء جميع الحقول قبل الإضافة");
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$').hasMatch(email)) {
      showSnackBar(context, "البريد الإلكتروني غير صحيح.");
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

    final idRegex = RegExp(r'^\d{10}$');
    if (!idRegex.hasMatch(id)) {
      showSnackBar(context, "رقم الإداري يجب أن يتكون من 10 أرقام فقط.");
      return;
    }

    bool isDuplicate = await isAdminDuplicate(id, email, phone);
    if (isDuplicate) {
      showSnackBar(context, "هذا الإداري مسجل مسبقًا، لا يمكن تكرار البيانات.");
      return;
    }

    try {
      String password = generateRandomPassword();
      await FirebaseFirestore.instance
          .collection('admins')
          .doc(id) // ✅ هنا التعديل الوحيد: استخدام id كمفتاح المستند
          .set({
            'name': name,
            'id': id,
            'phone': phone,
            'email': email,
            'password': password,
            'role': 'assistant',
            'schoolId': FirebaseAuth.instance.currentUser!.uid,
            'createdAt': Timestamp.now(),
          });

      await sendEmail(email, name, id, password);

      showSnackBar(
        context,
        "تمت إضافة الإداري بنجاح، وتم إرسال كلمة المرور عبر البريد",
      );

      nameController.clear();
      idController.clear();
      phoneController.clear();
      emailController.clear();
    } catch (e) {
      print("Error adding admin: $e");
      showSnackBar(context, "حدث خطأ أثناء الإضافة");
    }
  }

  Future<void> sendEmail(
    String recipientEmail,
    String name,
    String adminId,
    String password,
  ) async {
    final smtpServer = gmail(senderEmail, senderPassword);

    final message =
        Message()
          ..from = Address(senderEmail, 'Mutabie App')
          ..recipients.add(recipientEmail)
          ..subject = 'تم تسجيلك في تطبيق متابع'
          ..headers['X-Priority'] = '1'
          ..headers['X-MSMail-Priority'] = 'High'
          ..text =
              'مرحبًا $name،\n\n'
              'تم تسجيلك بنجاح في تطبيق متابع.\n'
              'رقم الإداري: $adminId\n'
              'كلمة المرور: $password\n\n'
              'تحياتنا،\nفريق متابع.'
          ..html = """
        <html>
          <body style="font-family: Arial; direction: rtl;">
            <h3>مرحبًا $name،</h3>
            <p>تم تسجيلك بنجاح في <strong>تطبيق متابع</strong>.</p>
            <p><strong>رقم الإداري:</strong> $adminId<br>
            <strong>كلمة المرور:</strong> $password</p>
            <p>يمكنك الآن تسجيل الدخول إلى التطبيق.</p>
            <p>تحياتنا،<br>فريق متابع</p>
          </body>
        </html>
      """;

    try {
      await send(message, smtpServer);
      print("✅ تم إرسال البريد الإلكتروني بنجاح إلى $recipientEmail");
    } catch (e) {
      print("❌ خطأ في إرسال البريد: $e");
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
        title: Text("إضافة إداري", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            CustomTextField(
              controller: nameController,
              icon: Icons.person,
              hintText: "اسم الإداري",
              iconColor: Colors.blue,
            ),
            SizedBox(height: 15),
            CustomTextField(
              controller: idController,
              icon: Icons.badge,
              hintText: "رقم الهوية الاداري",
              iconColor: Colors.blue,
            ),
            SizedBox(height: 15),
            CustomTextField(
              controller: phoneController,
              icon: Icons.phone,
              hintText: "رقم الهاتف",
              iconColor: Colors.blue,
            ),
            SizedBox(height: 15),
            CustomTextField(
              controller: emailController,
              icon: Icons.email,
              hintText: "البريد الإلكتروني",
              iconColor: Colors.blue,
            ),
            SizedBox(height: 20),
            CustomButtonAuth(
              title: "إضافة",
              onPressed: () async => await addAdmin(context),
              color: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }
}
