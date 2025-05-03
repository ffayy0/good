import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mut6/widgets/custom_button_auth.dart';
import 'package:mut6/widgets/custom_text_field.dart';

class TeachersListScreen extends StatefulWidget {
  @override
  _TeachersListScreenState createState() => _TeachersListScreenState();
}

class _TeachersListScreenState extends State<TeachersListScreen> {
  Map<String, bool> selectedTeachers = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text("المعلمين", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('teachers')
                .where('schoolId', isEqualTo: "mbRn2ksjlMNlTNztNXoMYcJxAco1")
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("حدث خطأ ما"));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("لا يوجد معلمين"));
          }
          final teachers = snapshot.data!.docs;
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(20),
                  itemCount: teachers.length,
                  itemBuilder: (context, index) {
                    var teacher = teachers[index];
                    var data = teacher.data() as Map<String, dynamic>;
                    String teacherId = teacher.id;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            data['name'] ?? 'بدون اسم',
                            style: TextStyle(fontSize: 18),
                          ),
                          SizedBox(width: 10),
                          Checkbox(
                            value: selectedTeachers[teacherId] ?? false,
                            onChanged: (val) {
                              setState(() {
                                selectedTeachers[teacherId] = val!;
                              });
                            },
                            activeColor: Colors.blue,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: CustomButtonAuth(
                        title: "حذف",
                        onPressed: _deleteSelectedTeachers,
                        color: Colors.blue,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: CustomButtonAuth(
                        title: "تعديل",
                        onPressed: _editSelectedTeacher,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _editSelectedTeacher() async {
    List<String> selectedIds =
        selectedTeachers.keys
            .where((id) => selectedTeachers[id] == true)
            .toList();
    if (selectedIds.length != 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("يرجى اختيار معلم واحد فقط للتعديل")),
      );
      return;
    }
    String selectedId = selectedIds.first;
    DocumentSnapshot doc =
        await FirebaseFirestore.instance
            .collection('teachers')
            .doc(selectedId)
            .get();
    if (!doc.exists) return;
    Map<String, dynamic> teacherData = doc.data() as Map<String, dynamic>;

    // إنشاء Controllers للحقول
    TextEditingController nameController = TextEditingController(
      text: teacherData['name'] ?? "",
    );
    TextEditingController idController = TextEditingController(
      text: selectedId,
    ); // ID المعلم
    TextEditingController phoneController = TextEditingController(
      text: teacherData['phone'] ?? "",
    );
    TextEditingController emailController = TextEditingController(
      text: teacherData['email'] ?? "",
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Center(child: Text("تعديل بيانات المعلم")),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: nameController,
                  icon: Icons.person,
                  hintText: "اسم المعلم",
                  iconColor: Colors.blue,
                ),
                CustomTextField(
                  controller: idController,
                  icon: Icons.badge,
                  hintText: "رقم المعلم",
                  iconColor: Colors.blue,
                  enabled: false, // جعل الحقل غير قابل للتعديل
                ),
                CustomTextField(
                  controller: phoneController,
                  icon: Icons.phone,
                  hintText: "رقم الجوال",
                  iconColor: Colors.blue,
                ),
                CustomTextField(
                  controller: emailController,
                  icon: Icons.email,
                  hintText: "البريد الإلكتروني",
                  iconColor: Colors.blue,
                ),
              ],
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: CustomButtonAuth(
                    title: "إلغاء",
                    onPressed: () => Navigator.pop(context),
                    color: Colors.grey,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: CustomButtonAuth(
                    title: "حفظ",
                    onPressed: () async {
                      String name = nameController.text.trim();
                      String phone = phoneController.text.trim();
                      String email = emailController.text.trim();

                      // التحقق من صحة البيانات
                      if (name.isEmpty || phone.isEmpty || email.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("جميع الحقول مطلوبة")),
                        );
                        return;
                      }
                      if (!phone.startsWith("05") || phone.length != 10) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("رقم الهاتف غير صحيح")),
                        );
                        return;
                      }
                      final emailRegex = RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      );
                      if (!emailRegex.hasMatch(email)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("صيغة البريد الإلكتروني غير صحيحة"),
                          ),
                        );
                        return;
                      }
                      bool phoneAvailable = await _isPhoneAvailable(
                        phone,
                        selectedId,
                      );
                      if (!phoneAvailable) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("رقم الجوال مستخدم بالفعل")),
                        );
                        return;
                      }
                      bool emailAvailable = await _isEmailAvailable(
                        email,
                        selectedId,
                      );
                      if (!emailAvailable) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("البريد الإلكتروني مستخدم بالفعل"),
                          ),
                        );
                        return;
                      }

                      // تحديث البيانات في Firestore
                      await FirebaseFirestore.instance
                          .collection('teachers')
                          .doc(selectedId)
                          .update({
                            'name': name,
                            'phone': phone,
                            'email': email,
                          });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("تم التعديل بنجاح")),
                      );
                    },
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _deleteSelectedTeachers() async {
    List<String> selectedIds =
        selectedTeachers.keys
            .where((id) => selectedTeachers[id] == true)
            .toList();
    if (selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("يرجى اختيار معلم واحد على الأقل")),
      );
      return;
    }
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text("تأكيد الحذف"),
            content: Text("هل أنت متأكد من حذف المعلمين المحددين؟"),
            actions: [
              TextButton(
                child: Text(
                  "إلغاء",
                  style: TextStyle(
                    color: const Color.fromARGB(255, 14, 125, 216),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: Text(
                  "حذف",
                  style: TextStyle(
                    color: const Color.fromARGB(255, 14, 125, 216),
                  ),
                ),
                onPressed: () async {
                  for (String id in selectedIds) {
                    await FirebaseFirestore.instance
                        .collection('teachers')
                        .doc(id)
                        .delete();
                  }
                  setState(() => selectedTeachers.clear());
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("تم حذف المعلمين بنجاح")),
                  );
                },
              ),
            ],
          ),
    );
  }

  Future<bool> _isPhoneAvailable(String phone, String currentId) async {
    final snap =
        await FirebaseFirestore.instance
            .collection('teachers')
            .where('phone', isEqualTo: phone)
            .get();
    return snap.docs.isEmpty ||
        (snap.docs.length == 1 && snap.docs.first.id == currentId);
  }

  Future<bool> _isEmailAvailable(String email, String currentId) async {
    final snap =
        await FirebaseFirestore.instance
            .collection('teachers')
            .where('email', isEqualTo: email)
            .get();
    return snap.docs.isEmpty ||
        (snap.docs.length == 1 && snap.docs.first.id == currentId);
  }
}
