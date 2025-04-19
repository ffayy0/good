import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mut6/StudentCardScreen.dart';

class StudentSearchScreen extends StatefulWidget {
  @override
  _StudentSearchScreenState createState() => _StudentSearchScreenState();
}

class _StudentSearchScreenState extends State<StudentSearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _searchStudent() async {
    String studentId = _searchController.text.trim();

    if (studentId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('يرجى إدخال رقم الهوية')));
      return;
    }

    try {
      final studentDoc =
          await _firestore.collection('students').doc(studentId).get();

      if (studentDoc.exists) {
        final studentData = studentDoc.data()!;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => StudentCardScreen(
                  name: studentData['name'],
                  id: studentData['id'],
                  stage: studentData['stage'],
                  schoolClass: studentData['schoolClass'],
                  guardianId: studentData['guardianId'],
                  guardianEmail: studentData['guardianEmail'],
                  guardianPhone:
                      studentData['phone'] ?? '', // قد يكون الهاتف غير متوفر
                  qrData:
                      'Name: ${studentData['name']}\nID: ${studentData['id']}\nStage: ${studentData['stage']}\nClass: ${studentData['schoolClass']}\nGuardian ID: ${studentData['guardianId']}\nEmail: ${studentData['guardianEmail']}',
                ),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('لم يتم العثور على الطالب')));
      }
    } catch (e) {
      print("❌ خطأ أثناء البحث عن الطالب: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء البحث')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('بحث عن الطالب'),
        backgroundColor: Color.fromARGB(255, 1, 113, 189),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'رقم الهوية',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _searchStudent,
              child: Text('بحث'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 1, 113, 189),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
