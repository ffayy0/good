import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExcuseUploadScreen extends StatefulWidget {
  final String day;
  final String date;
  final String status;
  final String guardianId;
  final String studentId;

  const ExcuseUploadScreen({
    super.key,
    required this.day,
    required this.date,
    required this.status,
    required this.guardianId,
    required this.studentId,
  });

  @override
  _ExcuseUploadScreenState createState() => _ExcuseUploadScreenState();
}

class _ExcuseUploadScreenState extends State<ExcuseUploadScreen> {
  PlatformFile? pickedFile;
  bool isUploading = false;
  TextEditingController reasonController = TextEditingController();

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpeg', 'jpg'],
    );

    if (result != null) {
      setState(() {
        pickedFile = result.files.first;
      });
    }
  }

  Future<void> uploadFile(BuildContext context) async {
    if (reasonController.text.trim().isEmpty && pickedFile == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("يرجى كتابة سبب أو رفع ملف")));
      return;
    }

    setState(() {
      isUploading = true;
    });

    try {
      String fileUrl = '';

      if (pickedFile != null) {
        final storageRef = FirebaseStorage.instance.ref().child(
          'excuses/${pickedFile!.name}',
        );
        final uploadTask = storageRef.putData(pickedFile!.bytes!);
        final snapshot = await uploadTask.whenComplete(() {});
        fileUrl = await snapshot.ref.getDownloadURL();
      }

      // ✅ تم تغيير اسم المجموعة من "excuses" إلى "student_excuses"
      await FirebaseFirestore.instance.collection('student_excuses').add({
        'day': widget.day,
        'date': widget.date,
        'status': widget.status,
        'studentId': widget.studentId,
        'reason': reasonController.text,
        'fileUrl': fileUrl,
        'timestamp': DateTime.now(),
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("تم حفظ العذر بنجاح")));

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("خطأ: $e")));
    } finally {
      setState(() {
        isUploading = false;
      });
    }
  }

  @override
  void dispose() {
    reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "رفع العذر",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ مربع معلومات الطالب - تم استعادته
            StreamBuilder<DocumentSnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('students')
                      .doc(widget.studentId)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text("لا توجد بيانات للطالب"),
                  );
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                final studentName = data['name'] ?? 'غير معروف';

                return Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "معلومات الطالب: $studentName",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "الحالة",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "اليوم / التاريخ",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Divider(thickness: 1),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                widget.status == "غياب"
                                    ? Icons.circle
                                    : Icons.access_time,
                                color:
                                    widget.status == "غياب"
                                        ? Colors.red
                                        : Colors.orange,
                                size: 16,
                              ),
                              SizedBox(width: 5),
                              Text(
                                widget.status == "غياب" ? "غياب" : "تأخير",
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          Text(
                            "${widget.day} ${widget.date}",
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

            SizedBox(height: 30),

            // 📝 مربع النص لكتابة السبب - كبير + خط واضح + حدود زرقاء
            Container(
              margin: EdgeInsets.only(bottom: 20),
              child: TextField(
                controller: reasonController,
                maxLines: 4,
                style: TextStyle(fontSize: 18), // ✅ زيادة حجم الخط داخل المربع
                decoration: InputDecoration(
                  labelText: "اكتب سبب الغياب أو التأخير هنا...",
                  labelStyle: TextStyle(
                    fontSize: 16,
                    color: Colors.blue,
                  ), // ✅ لون التلميح أزرق
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.blue,
                      width: 2,
                    ), // ✅ الحدود الزرقاء
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.blue.shade700,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[200], // خلفية فاتحة
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                ),
              ),
            ),

            SizedBox(height: 10),

            // 🔁 اختيار الملف (اختياري)
            InkWell(
              onTap: pickFile,
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
                        ? "ملف مختار: ${pickedFile!.name}"
                        : "PDF , JPEG (اختياري)",
                    style: TextStyle(
                      color: pickedFile != null ? Colors.black : Colors.black54,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 40),

            // ✅ زر التالي في المنتصف
            Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton(
                  onPressed: isUploading ? null : () => uploadFile(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 1, 113, 189),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child:
                      isUploading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                            "التالي",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ),
            ),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
