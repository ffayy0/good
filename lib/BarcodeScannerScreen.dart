import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BarcodeScannerScreen extends StatefulWidget {
  @override
  _BarcodeScannerScreenState createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String barcodeResult = "لم يتم المسح بعد";
  final Set<String> scannedBarcodes = {};

  DateTime? attendanceStartTime;
  String? schoolId;

  @override
  void initState() {
    super.initState();
    _loadSchoolData();
  }

  Future<void> _loadSchoolData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      schoolId = prefs.getString('schoolId') ?? '';

      if (schoolId == null || schoolId!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ لم يتم العثور على معرف المدرسة")),
        );
        return;
      }

      final schoolDoc =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(schoolId)
              .get();

      if (schoolDoc.exists &&
          schoolDoc.data()!.containsKey('attendanceStartTime')) {
        final timeString = schoolDoc['attendanceStartTime'] as String;
        final parts = timeString.split(':');
        if (parts.length == 2) {
          final hour = int.tryParse(parts[0]) ?? 7;
          final minute = int.tryParse(parts[1]) ?? 0;
          attendanceStartTime = DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
            hour,
            minute,
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ لم يتم العثور على وقت بداية الدوام")),
        );
      }
    } catch (e) {
      print("❌ خطأ أثناء جلب بيانات المدرسة: $e");
    }
  }

  void registerAttendance({
    required String studentId,
    required String studentName,
    required String stage,
    required String schoolClass,
    required String guardianId,
    required String guardianPhone,
    required String scannedSchoolId,
    required DateTime scanTime,
  }) async {
    try {
      if (attendanceStartTime == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("❌ وقت بداية الدوام غير معروف")));
        return;
      }

      FirebaseFirestore firestore = FirebaseFirestore.instance;

      String status;
      final difference = scanTime.difference(attendanceStartTime!).inMinutes;

      if (difference <= 0) {
        status = 'حضور';
      } else if (difference > 0 && difference <= 40) {
        status = 'تأخير';
      } else {
        status = 'غياب';
      }

      await firestore.collection('attendance_records').add({
        'studentId': studentId,
        'studentName': studentName,
        'stage': stage,
        'schoolClass': schoolClass,
        'guardianId': guardianId,
        'guardianPhone': guardianPhone,
        'status': status,
        'timestamp': FieldValue.serverTimestamp(),
        'schoolId': scannedSchoolId,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ تم تسجيل $status للطالب: $studentName")),
      );
    } catch (e) {
      print("❌ خطأ أثناء التسجيل: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("حدث خطأ أثناء تسجيل الحضور!")));
    }
  }

  void _resetScan() {
    setState(() {
      barcodeResult = "لم يتم المسح بعد";
    });
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
                controller = qrController;
                qrController.scannedDataStream.listen((scanData) {
                  String scannedId = scanData.code ?? "خطأ في المسح";

                  if (!scannedBarcodes.contains(scannedId)) {
                    final parts = scannedId.split('|');

                    if (parts.length < 7) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("❌ بيانات QR غير كاملة")),
                      );
                      return;
                    }

                    setState(() {
                      barcodeResult = scannedId;
                      scannedBarcodes.add(scannedId);
                    });

                    final String studentId = parts[0];
                    final String studentName = parts[1];
                    final String stage = parts[2];
                    final String schoolClass = parts[3];
                    final String guardianId = parts[4];
                    final String guardianPhone = parts[5];
                    final String scannedSchoolId = parts[6];
                    final scanTime = DateTime.now();

                    registerAttendance(
                      studentId: studentId,
                      studentName: studentName,
                      stage: stage,
                      schoolClass: schoolClass,
                      guardianId: guardianId,
                      guardianPhone: guardianPhone,
                      scannedSchoolId: scannedSchoolId,
                      scanTime: scanTime,
                    );
                  }
                });
              },
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "النتيجة: $barcodeResult",
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _resetScan,
                    icon: const Icon(
                      Icons.refresh,
                      color: Colors.white,
                      size: 24,
                    ),
                    label: const Text(
                      "إعادة المسح",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
