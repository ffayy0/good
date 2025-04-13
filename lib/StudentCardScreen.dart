import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:intl/intl.dart';

class StudentCardScreen extends StatefulWidget {
  final String name;
  final String id;
  final String stage;
  final String schoolClass;
  final String guardianId;
  final String guardianEmail;
  final String qrData;

  StudentCardScreen({
    required this.name,
    required this.id,
    required this.stage,
    required this.schoolClass,
    required this.guardianId,
    required this.guardianEmail,
    required this.qrData,
  });

  @override
  State<StudentCardScreen> createState() => _StudentCardScreenState();
}

class _StudentCardScreenState extends State<StudentCardScreen> {
  final GlobalKey _globalKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _checkAndSaveStudent(); // يتأكد قبل الإضافة
  }

  String _fixArabic(String text) {
    return Intl.message(text, name: 'fixArabic', locale: 'ar');
  }

  Future<Uint8List> _generatePDF() async {
    final pdf = pw.Document();

    final customFont = await rootBundle.load(
      "assets/fonts/Tajawal-Regular.ttf",
    );
    final ttf = pw.Font.ttf(customFont.buffer.asByteData());

    final logoData = await rootBundle.load('assets/images/logo.png');
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a6,
        build: (context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(15),
              border: pw.Border.all(color: PdfColors.blue, width: 2),
            ),
            padding: pw.EdgeInsets.all(16),
            child: pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Center(child: pw.Image(logoImage, height: 60)),
                  pw.SizedBox(height: 10),
                  pw.Center(
                    child: pw.Text(
                      _fixArabic('بطاقة الطالب'),
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        font: ttf,
                        color: PdfColors.blue,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Divider(color: PdfColors.blue50),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    _fixArabic("الاسم: ${widget.name}"),
                    style: pw.TextStyle(fontSize: 14, font: ttf),
                  ),
                  pw.Text(
                    _fixArabic("رقم الهوية: ${widget.id}"),
                    style: pw.TextStyle(fontSize: 14, font: ttf),
                  ),
                  pw.Text(
                    _fixArabic("المرحلة: ${widget.stage}"),
                    style: pw.TextStyle(fontSize: 14, font: ttf),
                  ),
                  pw.Text(
                    _fixArabic("الصف: ${widget.schoolClass}"),
                    style: pw.TextStyle(fontSize: 14, font: ttf),
                  ),
                  pw.Text(
                    _fixArabic("رقم ولي الأمر: ${widget.guardianId}"),
                    style: pw.TextStyle(fontSize: 14, font: ttf),
                  ),
                  pw.SizedBox(height: 12),
                  pw.Center(
                    child: pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: widget.qrData,
                      width: 100,
                      height: 100,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<void> _sendEmailWithPDF() async {
    try {
      final pdfBytes = await _generatePDF();
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/student_card.pdf';
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      final smtpServer = gmail('8ffaay01@gmail.com', 'vljn jaxv hukr qbct');

      final message =
          Message()
            ..from = Address('your_email@gmail.com', 'Student App')
            ..recipients.add(widget.guardianEmail)
            ..subject = 'بطاقة الطالب PDF'
            ..text = 'مرحبًا، مرفق بطاقة الطالب بصيغة PDF.'
            ..attachments.add(FileAttachment(file));

      await send(message, smtpServer);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إرسال البطاقة بالبريد الإلكتروني')),
      );
    } catch (e) {
      print("خطأ في الإرسال: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('فشل في إرسال البطاقة')));
    }
  }

  Future<void> _checkAndSaveStudent() async {
    final firestore = FirebaseFirestore.instance;
    final docRef = firestore.collection('students').doc(widget.id);

    final docSnapshot = await docRef.get();
    if (docSnapshot.exists) {
      // الطالب مضاف مسبقًا، فقط نقوم بعرض الرسالة
      print('الطالب مضاف مسبقًا');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('الطالب مضاف مسبقًا، لن يتم تنفيذ العملية')),
      );
    } else {
      // الطالب غير مضاف، نقوم بإضافته
      await docRef.set({
        'name': widget.name,
        'id': widget.id,
        'stage': widget.stage,
        'schoolClass': widget.schoolClass,
        'guardianId': widget.guardianId,
      });
      print('تمت إضافة الطالب');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('تم تسجيل الطالب بنجاح')));
      await _sendEmailWithPDF(); // إرسال البطاقة فقط إذا الطالب جديد
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('بطاقة الطالب'),
        backgroundColor: const Color.fromARGB(255, 1, 113, 189),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            RepaintBoundary(
              key: _globalKey,
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
                      Image.asset('assets/images/logo.png', height: 80),
                      SizedBox(height: 10),
                      Text(
                        "بطاقة الطالب",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: const Color.fromARGB(255, 1, 113, 189),
                        ),
                      ),
                      Divider(),
                      SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("الاسم: ${widget.name}"),
                            Text("رقم الهوية: ${widget.id}"),
                            Text("المرحلة: ${widget.stage}"),
                            Text("الصف: ${widget.schoolClass}"),
                            Text("رقم ولي الأمر: ${widget.guardianId}"),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
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
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _sendEmailWithPDF,
              icon: Icon(Icons.refresh),
              label: Text("إعادة إرسال البطاقة"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 1, 113, 189),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
