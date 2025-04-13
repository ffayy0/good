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

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void registerAttendance(String studentId) async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      await firestore.collection('attendance').add({
        'student_id': studentId,
        'timestamp': FieldValue.serverTimestamp(), // تاريخ ووقت التسجيل
      });

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
                  setState(() => barcodeResult = scannedId);
                  registerAttendance(scannedId); // تسجيل الحضور مباشرة
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
