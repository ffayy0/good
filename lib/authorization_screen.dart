import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../widgets/custom_text_field.dart';
import 'widgets/custom_button_auth.dart';

class AuthorizationScreen extends StatefulWidget {
  final String guardianId;

  const AuthorizationScreen({super.key, required this.guardianId});

  @override
  _AuthorizationScreenState createState() => _AuthorizationScreenState();
}

class _AuthorizationScreenState extends State<AuthorizationScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController idController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  List<Map<String, dynamic>> allStudents = [];
  List<Map<String, dynamic>> selectedStudents = [];
  String? _schoolId;

  @override
  void initState() {
    super.initState();
    _fetchSchoolId();
    _fetchAvailableStudents(widget.guardianId);
  }

  Future<void> _fetchSchoolId() async {
    try {
      final parentQuery =
          await FirebaseFirestore.instance
              .collection('parents')
              .where('id', isEqualTo: widget.guardianId)
              .limit(1)
              .get();

      if (parentQuery.docs.isNotEmpty) {
        setState(() {
          _schoolId = parentQuery.docs.first['schoolId'];
        });
      } else {
        print('❌ لم يتم العثور على ولي الأمر لجلب schoolId.');
      }
    } catch (e) {
      print('❌ خطأ أثناء جلب schoolId: $e');
    }
  }

  Future<void> _fetchAvailableStudents(String guardianId) async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('students')
              .where('guardianId', isEqualTo: guardianId)
              .get();

      setState(() {
        allStudents =
            querySnapshot.docs.map((doc) {
              return {
                "id": doc['id'],
                "name": doc['name'],
                "schoolClass": doc['schoolClass'],
                "stage": doc['stage'],
              };
            }).toList();
      });
    } catch (e) {
      print("❌ خطأ أثناء جلب بيانات الطلاب: $e");
    }
  }

  void _addStudent(Map<String, dynamic> student) {
    setState(() {
      if (!selectedStudents.contains(student)) {
        selectedStudents.add(student);
      }
    });
  }

  void _removeStudent(Map<String, dynamic> student) {
    setState(() {
      selectedStudents.remove(student);
    });
  }

  Future<bool> _isIdAvailable(String id) async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('Authorizations')
              .where('id', isEqualTo: id)
              .get();
      return querySnapshot.docs.isEmpty;
    } catch (e) {
      print("❌ خطأ أثناء التحقق من الـ ID: $e");
      return false;
    }
  }

  String generateRandomPassword({int length = 8}) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    return List.generate(
      length,
      (index) => chars[rand.nextInt(chars.length)],
    ).join();
  }

  Future<void> _sendAuthorizationEmail({
    required String recipientEmail,
    required String agentName,
    required String agentId,
    required String password,
    required String schoolId,
  }) async {
    final smtpServer = gmail("8ffaay01@gmail.com", "urwn frcb fzug ucyz");

    final message =
        Message()
          ..from = Address("8ffaay01@gmail.com", 'متابع')
          ..recipients.add(recipientEmail)
          ..subject = "بيانات الدخول - تطبيق متابع"
          ..html = """
      <html dir="rtl">
        <body style="font-family: Arial;">
          <h3>مرحبًا $agentName،</h3>
          <p>تم تسجيلك كموكل في <strong>تطبيق متابع</strong>.</p>
          <p><strong>رقم الهوية:</strong> $agentId</p>
          <p><strong>الرقم السري:</strong> $password</p>
          <p><strong>معرف المدرسة:</strong> $schoolId</p>
          <p>يرجى الاحتفاظ بهذه المعلومات وعدم مشاركتها.</p>
          <p>تحياتنا،<br>فريق متابع</p>
        </body>
      </html>
      """;

    try {
      await send(message, smtpServer);
      print("✅ تم إرسال البريد بنجاح");
    } catch (e) {
      print("❌ فشل إرسال البريد: $e");
    }
  }

  Future<bool> _validateFields(BuildContext context) async {
    final name = nameController.text.trim();
    final id = idController.text.trim();
    final email = emailController.text.trim();

    if (name.isEmpty || !name.contains(" ")) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("يرجى إدخال اسم ثنائي صالح")));
      return false;
    }

    if (id.isEmpty || int.tryParse(id) == null || id.length < 8) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("يرجى إدخال رقم هوية صالح")));
      return false;
    }

    final isIdAvailable = await _isIdAvailable(id);
    if (!isIdAvailable) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("رقم الموكل هذا مستخدم مسبقًا")));
      return false;
    }

    if (!email.contains('@')) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("يرجى إدخال بريد إلكتروني صالح")));
      return false;
    }

    if (_schoolId == null || _schoolId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("لم يتم تحديد معرف المدرسة. لا يمكن تسجيل الموكل"),
        ),
      );
      return false;
    }

    return true;
  }

  void _clearFields() {
    nameController.clear();
    idController.clear();
    emailController.clear();
    selectedStudents.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text('التوكيل', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            CustomTextField(
              controller: nameController,
              icon: Icons.person,
              hintText: 'اسم الوكيل',
              iconColor: Colors.blue,
            ),
            CustomTextField(
              controller: idController,
              icon: Icons.badge,
              hintText: 'رقم الهوية',
              iconColor: Colors.blue,
            ),
            CustomTextField(
              controller: emailController,
              icon: Icons.email,
              hintText: 'البريد الإلكتروني',
              iconColor: Colors.blue,
            ),
            const SizedBox(height: 20),
            Text(
              "الطلاب المختارون:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: allStudents.length,
                itemBuilder: (context, index) {
                  final student = allStudents[index];
                  bool isSelected = selectedStudents.contains(student);
                  return ListTile(
                    title: Text(student["name"]),
                    subtitle: Text(
                      "المرحلة: ${student["stage"]}, الصف: ${student["schoolClass"]}",
                    ),
                    trailing: Checkbox(
                      value: isSelected,
                      onChanged: (value) {
                        if (value == true) {
                          _addStudent(student);
                        } else {
                          _removeStudent(student);
                        }
                      },
                      activeColor: const Color.fromARGB(255, 1, 113, 189),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: SizedBox(
                width: 200,
                child: CustomButtonAuth(
                  title: 'تسجيل',
                  onPressed: () async {
                    if (await _validateFields(context)) {
                      final randomPassword = generateRandomPassword();
                      try {
                        final UserCredential userCredential = await FirebaseAuth
                            .instance
                            .createUserWithEmailAndPassword(
                              email: "${idController.text}@example.com",
                              password: randomPassword,
                            );

                        final String agentId = userCredential.user!.uid;

                        await FirebaseFirestore.instance
                            .collection('Authorizations')
                            .doc(agentId)
                            .set({
                              'name': nameController.text,
                              'id': idController.text,
                              'email': emailController.text,
                              'password': randomPassword,
                              'guardianId': widget.guardianId,
                              'schoolId': _schoolId ?? '',
                            });

                        for (var student in selectedStudents) {
                          await FirebaseFirestore.instance
                              .collection('AgentStudents')
                              .add({
                                'agentId': agentId,
                                'studentId': student["id"],
                                'studentName': student["name"],
                                'stage': student["stage"],
                                'schoolClass': student["schoolClass"],
                              });
                        }

                        await _sendAuthorizationEmail(
                          recipientEmail: emailController.text,
                          agentName: nameController.text,
                          agentId: idController.text,
                          password: randomPassword,
                          schoolId: _schoolId!,
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "تم تسجيل الحساب وإرسال المعلومات على البريد",
                            ),
                          ),
                        );

                        _clearFields();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("حدث خطأ أثناء التسجيل: $e")),
                        );
                      }
                    }
                  },
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
