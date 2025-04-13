import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart'; // لاختيار الملف
import 'package:firebase_storage/firebase_storage.dart'; // لتخزين الملف في Firebase Storage
import 'package:cloud_firestore/cloud_firestore.dart'; // لإدارة Firestore
import 'package:mut6/parent_screen.dart';

class ExcuseUploadScreen extends StatefulWidget {
  final String day;
  final String date;
  final String status;
  final String guardianId; // إضافة معلمة guardianId

  const ExcuseUploadScreen({
    super.key,
    required this.day,
    required this.date,
    required this.status,
    required this.guardianId, // إضافة guardianId كمعلمة إجبارية
  });

  @override
  _ExcuseUploadScreenState createState() => _ExcuseUploadScreenState();
}

class _ExcuseUploadScreenState extends State<ExcuseUploadScreen> {
  PlatformFile? pickedFile; // لتخزين الملف المختار
  bool isUploading = false; // لمعرفة حالة الرفع

  // دالة لاختيار الملف
  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpeg', 'jpg'], // أنواع الملفات المدعومة
    );

    if (result != null) {
      setState(() {
        pickedFile = result.files.first; // تخزين الملف المختار
      });
    }
  }

  // دالة لرفع الملف إلى Firebase
  Future<void> uploadFile(BuildContext context) async {
    if (pickedFile == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("يرجى اختيار ملف أولاً")));
      return;
    }

    setState(() {
      isUploading = true; // تفعيل حالة الرفع
    });

    try {
      // 1. رفع الملف إلى Firebase Storage
      final storageRef = FirebaseStorage.instance.ref().child(
        'excuses/${pickedFile!.name}',
      ); // مسار تخزين الملف
      final uploadTask = storageRef.putData(pickedFile!.bytes!); // رفع الملف
      final snapshot = await uploadTask.whenComplete(() {});

      // 2. الحصول على رابط الملف
      final fileUrl = await snapshot.ref.getDownloadURL();

      // 3. حفظ بيانات العذر في Firestore
      await FirebaseFirestore.instance.collection('excuses').add({
        'day': widget.day, // اليوم
        'date': widget.date, // التاريخ
        'status': widget.status, // الحالة (غائب أو متأخر)
        'fileUrl': fileUrl, // رابط الملف
        'timestamp': DateTime.now(), // وقت الرفع
      });

      // 4. عرض رسالة نجاح والانتقال إلى GuardianScreen
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("تم رفع العذر بنجاح")));

      // التنقل إلى GuardianScreen وإزالة جميع الصفحات الأخرى من الـ Stack
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder:
              (context) => GuardianScreen(
                guardianId: widget.guardianId, // تمرير guardianId
              ),
        ),
        (route) => false, // إزالة جميع الصفحات الأخرى
      );
    } catch (e) {
      // عرض رسالة خطأ في حال فشل الرفع
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("حدث خطأ أثناء الرفع: $e")));
    } finally {
      setState(() {
        isUploading = false; // إيقاف حالة الرفع
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "رفع العذر",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "معلومات الطالبة: مريم خالد",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "الصف: ١/٢",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        "الحالة",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "اليوم / التاريخ",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(thickness: 1),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            widget.status == "غائب"
                                ? Icons.circle
                                : Icons.access_time,
                            color:
                                widget.status == "غائب"
                                    ? Colors.red
                                    : Colors.orange,
                            size: 16,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            widget.status == "غائب" ? "غائب" : "متأخر",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      Text(
                        "${widget.day} ${widget.date}",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                ":الرجاء إرفاق العذر",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: pickFile, // عند النقر، يتم اختيار الملف
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    pickedFile != null
                        ? "تم اختيار: ${pickedFile!.name}" // عرض اسم الملف إذا تم اختياره
                        : "PDF , JPEG", // نص افتراضي إذا لم يتم اختيار ملف
                    style: TextStyle(
                      color: pickedFile != null ? Colors.black : Colors.black54,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: 150,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 1, 113, 189),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                onPressed:
                    isUploading
                        ? null
                        : () => uploadFile(context), // تعطيل الزر أثناء الرفع
                child:
                    isUploading
                        ? const CircularProgressIndicator(
                          color: Colors.white,
                        ) // عرض مؤشر التحميل
                        : const Text(
                          "رفع العذر",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
