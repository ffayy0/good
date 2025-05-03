import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ExcuseDetailsScreen extends StatelessWidget {
  final String studentName;
  final String date;
  final String reason;
  final String fileUrl;
  final String className; // إضافة هذه المعلمة

  const ExcuseDetailsScreen({
    required this.studentName,
    required this.date,
    required this.reason,
    required this.fileUrl,
    required this.className, // تمرير اسم الصف هنا
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFAF3FA), // خلفية وردية فاتحة
      appBar: AppBar(
        title: Text("تفاصيل العذر"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 16, color: Colors.black),
                      children: [
                        TextSpan(
                          text: "اسم الطالب: ",
                          style: TextStyle(color: Colors.blue),
                        ),
                        TextSpan(text: studentName),
                      ],
                    ),
                  ),

                  SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 16, color: Colors.black),
                      children: [
                        TextSpan(
                          text: "السبب: ",
                          style: TextStyle(color: Colors.blue),
                        ),
                        TextSpan(text: reason),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 16, color: Colors.black),
                      children: [
                        TextSpan(
                          text: "التاريخ: ",
                          style: TextStyle(color: Colors.blue),
                        ),
                        TextSpan(text: date),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            if (fileUrl.isNotEmpty)
              TextButton(
                onPressed: () {
                  launchFile(fileUrl);
                },
                child: Text("عرض الملف", style: TextStyle(color: Colors.blue)),
                style: TextButton.styleFrom(
                  backgroundColor: Color(0xFFF2F2F2),
                  minimumSize: Size(double.infinity, 40),
                ),
              ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, false); // رفض
                    },
                    child: Text("رفض"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, true); // قبول
                    },
                    child: Text("قبول"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
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

  void launchFile(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
