import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BarcodeScannerScreen extends StatefulWidget {
  @override
  _BarcodeScannerScreenState createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String barcodeResult = "لم يتم المسح بعد";
  final Set<String> scannedBarcodes = {}; // لتخزين الباركود المسجلة

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  // دالة لتسجيل الحضور مع حالة محددة
  void registerAttendance(String studentId, String status) async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      // تحديث أو إضافة حالة الحضور في Firestore
      await firestore.collection('attendance').doc(studentId).set(
        {
          'student_id': studentId,
          'status': status, // حالة الحضور (حضور/غياب/تأخير)
          'timestamp': FieldValue.serverTimestamp(), // تاريخ ووقت التسجيل
        },
        SetOptions(merge: true),
      ); // استخدام merge لتجنب الكتابة فوق البيانات السابقة

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("تم تسجيل الحضور للطالب: $studentId")),
      );
    } catch (e) {
      print("خطأ أثناء التسجيل: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("خطأ أثناء تسجيل الحضور!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("مسح الباركود وتسجيل الحضور")),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: QRView(
              key: qrKey,
              onQRViewCreated: (QRViewController qrController) {
                setState(() => controller = qrController);
                qrController.scannedDataStream.listen((scanData) {
                  String scannedId = scanData.code ?? "خطأ في المسح";

                  // التحقق مما إذا كان الباركود قد تم مسحه بالفعل
                  if (!scannedBarcodes.contains(scannedId)) {
                    setState(() {
                      barcodeResult = scannedId;
                      scannedBarcodes.add(
                        scannedId,
                      ); // إضافة الباركود إلى المجموعة
                    });

                    // عرض نافذة حوار لاختيار حالة الحضور
                    showDialog(
                      context: context,
                      builder: (context) {
                        String selectedStatus = "حضور"; // الحالة الافتراضية

                        return AlertDialog(
                          title: Text("اختر حالة الحضور"),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                title: Text("حضور"),
                                leading: Radio<String>(
                                  value: "حضور",
                                  groupValue: selectedStatus,
                                  onChanged: (value) {
                                    setState(() => selectedStatus = value!);
                                  },
                                ),
                              ),
                              ListTile(
                                title: Text("غياب"),
                                leading: Radio<String>(
                                  value: "غياب",
                                  groupValue: selectedStatus,
                                  onChanged: (value) {
                                    setState(() => selectedStatus = value!);
                                  },
                                ),
                              ),
                              ListTile(
                                title: Text("تأخير"),
                                leading: Radio<String>(
                                  value: "تأخير",
                                  groupValue: selectedStatus,
                                  onChanged: (value) {
                                    setState(() => selectedStatus = value!);
                                  },
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context); // إغلاق النافذة
                              },
                              child: Text("إلغاء"),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context); // إغلاق النافذة
                                registerAttendance(
                                  scannedId,
                                  selectedStatus,
                                ); // تسجيل الحضور
                              },
                              child: Text("تأكيد"),
                            ),
                          ],
                        );
                      },
                    );
                  }
                });
              },
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                "النتيجة: $barcodeResult",
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
