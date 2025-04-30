import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentCardScreen extends StatefulWidget {
  final String name;
  final String id;
  final String stage;
  final String schoolClass;
  final String guardianId;
  final String guardianEmail;
  final String guardianPhone;

  const StudentCardScreen({
    required this.name,
    required this.id,
    required this.stage,
    required this.schoolClass,
    required this.guardianId,
    required this.guardianEmail,
    required this.guardianPhone,
    required String qrData,
  });

  @override
  State<StudentCardScreen> createState() => _StudentCardScreenState();
}

class _StudentCardScreenState extends State<StudentCardScreen> {
  final ScreenshotController screenshotController = ScreenshotController();
  final Color _iconColor = const Color(0xFF007AFF);
  final Color _buttonColor = const Color(0xFF007AFF);
  final Color _textColor = Colors.black87;

  final String senderEmail = "8ffaay01@gmail.com";
  final String senderPassword = "vljn jaxv hukr qbct";

  String? schoolId;

  @override
  void initState() {
    super.initState();
    _loadSchoolId();
  }

  Future<void> _loadSchoolId() async {
    final prefs = await SharedPreferences.getInstance();
    final storedSchoolId = prefs.getString('schoolId');

    if (storedSchoolId != null && storedSchoolId.isNotEmpty) {
      setState(() {
        schoolId = storedSchoolId;
      });
    } else {
      await _fetchSchoolIdFromStudent();
    }
  }

  Future<void> _fetchSchoolIdFromStudent() async {
    try {
      final studentSnapshot =
          await FirebaseFirestore.instance
              .collection('students')
              .where('id', isEqualTo: widget.id)
              .limit(1)
              .get();

      if (studentSnapshot.docs.isNotEmpty) {
        final studentData =
            studentSnapshot.docs.first.data() as Map<String, dynamic>;
        final fetchedSchoolId = studentData['schoolId'] ?? '';

        setState(() {
          schoolId = fetchedSchoolId;
        });

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('schoolId', fetchedSchoolId);
      } else {
        print('❗ لم يتم العثور على الطالب.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لم يتم العثور على بيانات الطالب')),
        );
      }
    } catch (e) {
      print('❌ خطأ أثناء جلب بيانات الطالب: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء جلب بيانات الطالب: $e')),
      );
    }
  }

  Future<void> _saveCardAsImage() async {
    try {
      await Permission.storage.request();
      await Permission.photos.request();

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

  Future<void> _resendEmail() async {
    try {
      await sendEmail(
        widget.guardianEmail,
        widget.name,
        widget.guardianId,
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
    if (schoolId == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final String qrContent =
        "${widget.id}|"
        "${widget.name}|"
        "${widget.stage}|"
        "${widget.schoolClass}|"
        "${widget.guardianId}|"
        "${widget.guardianPhone}|"
        "$schoolId";

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'بطاقة الطالب',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: _buttonColor,
        iconTheme: const IconThemeData(color: Colors.white),
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
                          color: _buttonColor,
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
                        data: qrContent,
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
                  icon: const Icon(Icons.download, color: Colors.white),
                  label: const Text(
                    "حفظ البطاقة كصورة",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _buttonColor,
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 30,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _resendEmail,
                  icon: const Icon(Icons.email, color: Colors.white),
                  label: const Text(
                    "إعادة إرسال البريد الإلكتروني",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _buttonColor,
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
