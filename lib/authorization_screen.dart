import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/custom_text_field.dart';
import 'widgets/custom_button_auth.dart';

class AuthorizationScreen extends StatefulWidget {
  final String guardianId; // معرف ولي الأمر المسجل

  const AuthorizationScreen({super.key, required this.guardianId});

  @override
  _AuthorizationScreenState createState() => _AuthorizationScreenState();
}

class _AuthorizationScreenState extends State<AuthorizationScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController idController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  List<Map<String, dynamic>> allStudents = []; // جميع الطلاب المتاحين
  List<Map<String, dynamic>> selectedStudents = []; // الطلاب المختارين
  String? _schoolId; // معرف المدرسة للولي الأمر

  @override
  void initState() {
    super.initState();
    _fetchSchoolId(); // جلب schoolId عند بداية الشاشة
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

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("كلمة المرور يجب أن تكون 6 أحرف أو أكثر.")),
      );
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
    passwordController.clear();
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
            const SizedBox(height: 30),
            Center(
              child: SizedBox(
                width: 200,
                child: CustomButtonAuth(
                  title: 'تسجيل',
                  onPressed: () async {
                    if (await _validateFields(context)) {
                      try {
                        final UserCredential userCredential = await FirebaseAuth
                            .instance
                            .createUserWithEmailAndPassword(
                              email: "${idController.text}@example.com",
                              password: passwordController.text,
                            );

                        final String agentId = userCredential.user!.uid;

                        await FirebaseFirestore.instance
                            .collection('Authorizations')
                            .doc(agentId)
                            .set({
                              'name': nameController.text,
                              'id': idController.text,
                              'password': passwordController.text,
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

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("تم تسجيل الحساب بنجاح")),
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
