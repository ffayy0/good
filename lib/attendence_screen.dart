import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mut6/excuse_upload_screen.dart';

class GuardianAttendanceScreen extends StatefulWidget {
  final String guardianId;
  final String studentId;
  final String studentName;

  const GuardianAttendanceScreen({
    super.key,
    required this.guardianId,
    required this.studentId,
    required this.studentName,
    required String childName,
  });

  @override
  State<GuardianAttendanceScreen> createState() =>
      _GuardianAttendanceScreenState();
}

class _GuardianAttendanceScreenState extends State<GuardianAttendanceScreen> {
  DateTime selectedDate = DateTime.now();
  Map<String, dynamic>? attendanceData;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ar_SA');
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);

    final snapshot =
        await FirebaseFirestore.instance
            .collection('attendance_records')
            .where('studentId', isEqualTo: widget.studentId)
            .get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final ts = (data['timestamp'] as Timestamp?)?.toDate();
      if (ts != null && DateFormat('yyyy-MM-dd').format(ts) == dateStr) {
        setState(() {
          attendanceData = {
            'status': data['status'],
            'time': DateFormat('HH:mm').format(ts),
          };
        });
        return;
      }
    }

    setState(() {
      attendanceData = null;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      locale: const Locale('ar', 'SA'),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
      await _loadAttendance();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);

    String status = attendanceData?['status'] ?? 'غياب';
    String? time = attendanceData?['time'];

    IconData icon;
    Color color;
    switch (status) {
      case 'حضور':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'تأخير':
        icon = Icons.access_time;
        color = Colors.orange;
        break;
      default:
        icon = Icons.cancel;
        color = Colors.red;
    }

    // متغيرات اليوم والتاريخ لتمريرها إلى صفحة الأعذار
    final day = DateFormat('EEEE', 'ar_SA').format(selectedDate);
    final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text(
          "حضور ${widget.studentName}",
          style: TextStyle(
            color: Colors.white, // لون النص في العنوان أبيض
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white), // سهم الرجوع أبيض
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickDate,
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.blue),
                  const SizedBox(width: 10),
                  Text(
                    "التاريخ المختار: $dateStr",
                    style: TextStyle(
                      fontSize: 17, // تم زيادة حجم خط التاريخ
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // ✅ Card قابل للنقر فقط إذا كانت الحالة "غياب" أو "تأخير"
            GestureDetector(
              onTap:
                  (status == 'غياب' || status == 'تأخير')
                      ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => ExcuseUploadScreen(
                                  day: day,
                                  date: formattedDate,
                                  status: status,
                                  guardianId: widget.guardianId,
                                  studentId: widget.studentId,
                                ),
                          ),
                        );
                      }
                      : null,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 24,
                  ), // زيادة الحشوة قليلاً
                  child: ListTile(
                    title: Text(
                      "الحالة: $status",
                      style: TextStyle(fontSize: 18), // زيادة حجم النص قليلاً
                    ),
                    subtitle:
                        time != null
                            ? Text(
                              "الوقت: $time",
                              style: TextStyle(fontSize: 16),
                            )
                            : null,
                    leading: Icon(icon, color: color, size: 40),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
