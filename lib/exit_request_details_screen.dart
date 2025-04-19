import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class RequestDetailsScreen extends StatelessWidget {
  final QueryDocumentSnapshot request;

  const RequestDetailsScreen({Key? key, required this.request})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // استرداد البيانات كخريطة
    final data = request.data() as Map<String, dynamic>;

    // التحقق من أن البيانات ليست فارغة
    if (data == null) {
      return Scaffold(
        appBar: AppBar(title: Text("خطأ")),
        body: Center(child: Text("حدث خطأ أثناء جلب بيانات الطلب.")),
      );
    }

    // استخراج الحقول بأمان
    final studentName = data['studentName'] ?? 'غير محدد';
    final grade =
        data['grade']?.toString().isNotEmpty == true
            ? data['grade']
            : 'غير محدد';
    final reason = data['reason'] ?? 'غير محدد';
    final date = data['date'] ?? 'غير محدد';
    final time = data['time'] ?? 'غير محدد';
    final attachedFileUrl = data['attachedFileUrl'];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text("تفاصيل الطلب", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // الصندوق الرمادي
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "الطالبة:",
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(studentName, textAlign: TextAlign.center),
                  SizedBox(height: 10),
                  Text(
                    "الصف:",
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(grade.toString(), textAlign: TextAlign.center),
                  SizedBox(height: 10),
                  Text(
                    "سبب الاستئذان:",
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(reason, textAlign: TextAlign.center),
                  SizedBox(height: 10),
                  Text(
                    "وقت الاستئذان:",
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text("$time", textAlign: TextAlign.center),
                ],
              ),
            ),

            // زر عرض الملف (إذا وُجد)
            if (attachedFileUrl != null && attachedFileUrl.isNotEmpty) ...[
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final uri = Uri.parse(attachedFileUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    } else {
                      throw Exception('Failed to launch URL');
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("حدث خطأ أثناء فتح الملف")),
                    );
                  }
                },
                child: Text("عرض الملف", style: TextStyle(color: Colors.blue)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ] else ...[
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("لا يوجد ملف لعرضه")));
                },
                child: Text("عرض الملف", style: TextStyle(color: Colors.blue)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],

            // أزرار القبول والرفض
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        await FirebaseFirestore.instance
                            .collection('requests')
                            .doc(request.id)
                            .update({
                              'status': 'completed',
                              'decision': 'accepted',
                              'timestamp': FieldValue.serverTimestamp(),
                            });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("تم قبول الطلب")),
                        );
                        Navigator.pop(context); // العودة إلى الشاشة السابقة
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("حدث خطأ أثناء قبول الطلب")),
                        );
                      }
                    },
                    child: Text("قبول", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[900],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        await FirebaseFirestore.instance
                            .collection('excuses')
                            .doc(request.id)
                            .update({
                              'status': 'completed',
                              'decision': 'accepted', // أو 'rejected'
                              'timestamp': FieldValue.serverTimestamp(),
                            });
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text("تم رفض الطلب")));
                        Navigator.pop(context); // العودة إلى الشاشة السابقة
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("حدث خطأ أثناء رفض الطلب")),
                        );
                      }
                    },
                    child: Text("رفض", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[900],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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
