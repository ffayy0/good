import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // لإدارة المصادقة
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/custom_text_field.dart';
import 'widgets/custom_button_auth.dart'
    show CustomButtonAuth; // لإدارة Firestore

class AuthorizationScreen extends StatefulWidget {
  final String guardianId; // معرف ولي الأمر المسجل
  const AuthorizationScreen({Key? key, required this.guardianId})
    : super(key: key);

  @override
  _AuthorizationScreenState createState() => _AuthorizationScreenState();
}

class _AuthorizationScreenState extends State<AuthorizationScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController idController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  List<Map<String, dynamic>> allStudents = []; // جميع الطلاب المتاحين
  List<Map<String, dynamic>> selectedStudents = []; // الطلاب المختارين

  @override
  void initState() {
    super.initState();
    _fetchAvailableStudents(widget.guardianId);
  }

  // دالة لجلب جميع الطلاب المرتبطين بوالي الأمر
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

  // دالة لإضافة الطالب إلى القائمة المختارة
  void _addStudent(Map<String, dynamic> student) {
    setState(() {
      if (!selectedStudents.contains(student)) {
        selectedStudents.add(student);
      }
    });
  }

  // دالة لإزالة الطالب من القائمة المختارة
  void _removeStudent(Map<String, dynamic> student) {
    setState(() {
      selectedStudents.remove(student);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text('التوكيل', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // العودة إلى الصفحة السابقة
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40), // يبعد الحقول عن بداية الصفحة
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
              controller: passwordController,
              icon: Icons.lock,
              hintText: 'كلمة المرور',
              iconColor: Colors.blue,

              obscureText: true,
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
            const SizedBox(height: 40), // يبعد الزر عن الحقول
            Center(
              child: SizedBox(
                width: 200, // جعل الزر بالوسط
                child: CustomButtonAuth(
                  title: 'تسجيل',
                  onPressed: () async {
                    if (await _validateFields(context)) {
                      try {
                        // إنشاء حساب جديد باستخدام Firebase Authentication
                        final UserCredential userCredential = await FirebaseAuth
                            .instance
                            .createUserWithEmailAndPassword(
                              email:
                                  "${idController.text}@example.com", // استخدام رقم الموكل كبريد إلكتروني
                              password: passwordController.text,
                            );
                        // استخراج معرف Firebase (uid) ليكون هو agentId
                        final String agentId = userCredential.user!.uid;

                        // حفظ بيانات الحساب في Firestore
                        await FirebaseFirestore.instance
                            .collection('Authorizations')
                            .doc(agentId)
                            .set({
                              'name': nameController.text,
                              'id': idController.text,
                              'password': passwordController.text,
                              'guardianId': widget.guardianId, // معرف ولي الأمر
                            });

                        // حفظ بيانات الطلاب المختارين مع حساب الوكيل
                        for (var student in selectedStudents) {
                          await FirebaseFirestore.instance
                              .collection('AgentStudents')
                              .add({
                                'agentId': agentId, // معرف الوكيل (uid)
                                'studentId': student["id"], // معرف الطالب
                                'studentName': student["name"], // اسم الطالب
                                'stage': student["stage"], // المرحلة
                                'schoolClass': student["schoolClass"], // الصف
                              });
                        }

                        // عرض رسالة نجاح
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("تم تسجيل الحساب بنجاح")),
                        );

                        // إعادة تهيئة الحقول
                        _clearFields();
                      } catch (e) {
                        // عرض رسالة خطأ
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("حدث خطأ أثناء التسجيل: $e")),
                        );
                      }
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // دالة للتحقق من أن الـ ID غير مستخدم مسبقًا
  Future<bool> _isIdAvailable(String id) async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('Authorizations')
              .where('id', isEqualTo: id)
              .get();
      return querySnapshot.docs.isEmpty;
    } catch (e) {
      print("حدث خطأ أثناء التحقق من الـ ID: $e");
      return false;
    }
  }

  // دالة للتحقق من صحة الحقول
  Future<bool> _validateFields(BuildContext context) async {
    final name = nameController.text.trim();
    final id = idController.text.trim();
    final password = passwordController.text.trim();

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

    final passwordRegex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d]{8,20}$',
    );
    if (!passwordRegex.hasMatch(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "كلمة المرور يجب أن تحتوي على أحرف كبيرة وصغيرة وأرقام",
          ),
        ),
      );
      return false;
    }

    return true;
  }

  // دالة لإعادة تهيئة الحقول
  void _clearFields() {
    nameController.clear();
    idController.clear();
    passwordController.clear();
    selectedStudents.clear();
  }
}
