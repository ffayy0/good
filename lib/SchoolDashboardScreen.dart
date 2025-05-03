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
      backgroundColor: Colors.white, // ✅ الخلفية كلها بيضاء
      appBar: AppBar(
        title: Text(
          'موعد الحضور ',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        backgroundColor: Colors.green,
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white, // ✅ جعل الخلفية بيضاء تمامًا
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    // لوجو المدرسة من الرابط
                    Image.network(
                      'https://i.postimg.cc/DwnKf079/321e9c9d-4d67-4112-a513-d368fc26b0c0.jpg',
                      width: 100,
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: 10),
                    Text(
                      "وقت تسجيل الحضور",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 10),
                    GestureDetector(
                      onTap: _pickTime,
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.green, width: 1.5),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                        ),
                        child: Center(
                          child: Text(
                            _formattedTime != null
                                ? "الوقت المحدد: $_formattedTime"
                                : "اضغط لاختيار الوقت",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _saveAttendanceTime,
              icon: Icon(Icons.save, color: Colors.white),
              label: Text("حفظ الوقت", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
