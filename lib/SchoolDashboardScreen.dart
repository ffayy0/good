import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SchoolDashboardScreen extends StatefulWidget {
  const SchoolDashboardScreen({Key? key}) : super(key: key);

  @override
  _SchoolDashboardScreenState createState() => _SchoolDashboardScreenState();
}

class _SchoolDashboardScreenState extends State<SchoolDashboardScreen> {
  final String schoolId = FirebaseAuth.instance.currentUser!.uid;
  TimeOfDay? _selectedTime;
  String? _formattedTime;

  @override
  void initState() {
    super.initState();
    _loadAttendanceTime();
  }

  Future<void> _loadAttendanceTime() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('schools')
            .doc(schoolId)
            .get();
    if (doc.exists && doc.data()!.containsKey('attendanceStartTime')) {
      String timeStr = doc['attendanceStartTime'];
      List<String> parts = timeStr.split(":");
      if (parts.length == 2) {
        setState(() {
          _selectedTime = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
          _formattedTime = timeStr;
        });
      }
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay(hour: 7, minute: 30),
    );

    if (picked != null) {
      String formatted =
          "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      setState(() {
        _selectedTime = picked;
        _formattedTime = formatted;
      });
    }
  }

  Future<void> _saveAttendanceTime() async {
    if (_formattedTime == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('يرجى اختيار وقت أولاً')));
      return;
    }

    await FirebaseFirestore.instance.collection('schools').doc(schoolId).update(
      {'attendanceStartTime': _formattedTime},
    );

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('تم حفظ وقت بداية الحضور بنجاح')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('لوحة المدرسة'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            ListTile(
              title: Text(
                _formattedTime != null
                    ? "وقت البداية المحدد: $_formattedTime"
                    : "لم يتم تحديد وقت بعد",
                style: TextStyle(fontSize: 18),
              ),
              trailing: Icon(Icons.access_time),
              onTap: _pickTime,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveAttendanceTime,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text('حفظ الوقت'),
            ),
          ],
        ),
      ),
    );
  }
}
