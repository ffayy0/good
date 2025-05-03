import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mut6/AgentChildrenScreen.dart';
import 'package:mut6/widgets/custom_button.dart';
import 'package:mut6/widgets/guardian_custom_drawer.dart';

class AgentScreen extends StatefulWidget {
  final String agentId;
  final String guardianId;

  const AgentScreen({
    super.key,
    required this.agentId,
    required this.guardianId,
  });

  @override
  State<AgentScreen> createState() => _AgentScreenState();
}

class _AgentScreenState extends State<AgentScreen> {
  final TextEditingController schoolIdController = TextEditingController();
  String? errorMessage;

  Future<bool> _isSchoolIdValid(String schoolId) async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(schoolId)
              .get();
      return doc.exists;
    } catch (e) {
      print("❌ خطأ أثناء التحقق من schoolId: $e");
      return false;
    }
  }

  void _checkSchoolIdAndProceed() async {
    String enteredId = schoolIdController.text.trim();

    if (enteredId.isEmpty) {
      setState(() {
        errorMessage = "يرجى إدخال معرف المدرسة";
      });
      return;
    }

    bool isValid = await _isSchoolIdValid(enteredId);
    if (!isValid) {
      setState(() {
        errorMessage = "معرف المدرسة غير صحيح أو غير موجود";
      });
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AgentChildrenScreen(
              agentId: widget.agentId,
              guardianId: widget.guardianId,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.green,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "الوكيل",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Builder(
            builder:
                (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () {
                    Scaffold.of(context).openEndDrawer();
                  },
                ),
          ),
        ],
      ),
      endDrawer: GuardianCustomDrawer(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          children: [
            Image.network(
              'https://i.postimg.cc/DwnKf079/321e9c9d-4d67-4112-a513-d368fc26b0c0.jpg',
              width: 200,
              height: 189,
            ),
            const SizedBox(height: 30),
            TextField(
              controller: schoolIdController,
              decoration: InputDecoration(
                labelText: "أدخل معرف المدرسة",
                border: OutlineInputBorder(),
                errorText: errorMessage,
              ),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 20),
            CustomButton(title: "تأكيد", onPressed: _checkSchoolIdAndProceed),
          ],
        ),
      ),
    );
  }
}
