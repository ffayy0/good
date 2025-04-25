import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class StudentCardScreen extends StatefulWidget {
  final String name;
  final String id;
  final String stage;
  final String schoolClass;
  final String guardianId;
  final String guardianEmail;
  final String guardianPhone;
  final String qrData;

  const StudentCardScreen({
    required this.name,
    required this.id,
    required this.stage,
    required this.schoolClass,
    required this.guardianId,
    required this.guardianEmail,
    required this.guardianPhone,
    required this.qrData,
  });

  @override
  State<StudentCardScreen> createState() => _StudentCardScreenState();
}

class _StudentCardScreenState extends State<StudentCardScreen> {
  final ScreenshotController screenshotController = ScreenshotController();

  // تعريف الألوان المستخدمة
  final Color _iconColor = const Color(
    0xFF007AFF,
  ); // أزرق مشابه للون iOS الافتراضي
  final Color _buttonColor = const Color(0xFF007AFF); // نفس اللون الأزرق للزر
  final Color _textColor = Colors.black87; // نص أسود داكن (أكثر وضوحًا)

  // بيانات المرسل
  final String senderEmail = "8ffaay01@gmail.com"; // ✉️ بريد المرسل
  final String senderPassword = "vljn jaxv hukr qbct"; // 🔑 كلمة مرور التطبيق

  Future<void> _saveCardAsImage() async {
    try {
      // طلب الأذونات
      await Permission.storage.request();
      await Permission.photos.request(); // مهم جداً لـ iOS

      final imageBytes = await screenshotController.capture();
      if (imageBytes != null) {
        final result = await ImageGallerySaver.saveImage(
          Uint8List.fromList(imageBytes),
          quality: 100,
          name: 'student_card_${widget.id}',
        );

        print("🔽 تم الحفظ: $result");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ تم حفظ البطاقة كصورة في المعرض')),
        );
      }
    } catch (e) {
      print('❌ خطأ في الحفظ: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('فشل في حفظ البطاقة')));
    }
  }

  // ✅ دالة إعادة إرسال البريد الإلكتروني
  Future<void> _resendEmail() async {
    try {
      // إعادة إرسال البريد الإلكتروني
      await sendEmail(
        widget.guardianEmail,
        widget.name,
        widget
            .guardianId, // هنا يمكن استخدام نفس البيانات أو جلبها من Firebase إذا كانت مختلفة
        widget.id,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ تم إعادة إرسال البريد الإلكتروني بنجاح')),
      );
    } catch (e) {
      print('❌ خطأ في إعادة إرسال البريد: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في إعادة إرسال البريد الإلكتروني')),
      );
    }
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
              "تم تسجيلك بنجاح في تطبيق متابع.\n\n"
              "بيانات تسجيل الدخول الخاصة بك:\n"
              "رقم ولي الأمر: $parentId\n"
              "كلمة المرور: $password\n\n"
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'بطاقة الطالب',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: _buttonColor, // نفس لون الزر
        iconTheme: const IconThemeData(color: Colors.white), // أيقونة بيضاء
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Screenshot(
              controller: screenshotController,
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 5,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.network(
                        'https://i.postimg.cc/DwnKf079/321e9c9d-4d67-4112-a513-d368fc26b0c0.jpg',
                        height: 80,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "بطاقة الطالب",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _buttonColor, // نفس لون الزر
                        ),
                      ),
                      const Divider(),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "الاسم: ${widget.name}",
                              style: TextStyle(color: _textColor),
                            ),
                            Text(
                              "رقم الهوية: ${widget.id}",
                              style: TextStyle(color: _textColor),
                            ),
                            Text(
                              "المرحلة: ${widget.stage}",
                              style: TextStyle(color: _textColor),
                            ),
                            Text(
                              "الصف: ${widget.schoolClass}",
                              style: TextStyle(color: _textColor),
                            ),
                            Text(
                              "رقم ولي الأمر: ${widget.guardianId}",
                              style: TextStyle(color: _textColor),
                            ),
                            Text(
                              "هاتف ولي الأمر: ${widget.guardianPhone}",
                              style: TextStyle(color: _textColor),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      QrImageView(
                        data: widget.qrData,
                        version: QrVersions.auto,
                        size: 150.0,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Column(
              children: [
                ElevatedButton.icon(
                  onPressed: _saveCardAsImage,
                  icon: Icon(Icons.download, color: Colors.white),
                  label: const Text(
                    "حفظ البطاقة كصورة",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _buttonColor, // نفس اللون الأزرق للزر
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 30,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 10), // مسافة بين الأزرار
                ElevatedButton.icon(
                  onPressed: _resendEmail,
                  icon: Icon(Icons.email, color: Colors.white),
                  label: const Text(
                    "إعادة إرسال البريد الإلكتروني",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _buttonColor, // نفس اللون الأزرق للزر
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 30,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
