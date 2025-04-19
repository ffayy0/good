import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:qr_flutter/qr_flutter.dart';

class StudentCardScreen extends StatefulWidget {
  final String name;
  final String id;
  final String stage;
  final String schoolClass;
  final String guardianId;
  final String guardianEmail;
  final String guardianPhone;
  final String qrData;

  StudentCardScreen({
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
                      Image.asset(
                        'https://i.postimg.cc/DwnKf079/321e9c9d-4d67-4112-a513-d368fc26b0c0.jpg',
                        height: 80,
                      ),
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
                            Text("هاتف ولي الأمر: ${widget.guardianPhone}"),
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
              onPressed: _saveCardAsImage,
              icon: Icon(Icons.download),
              label: Text("حفظ البطاقة كصورة"),
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
