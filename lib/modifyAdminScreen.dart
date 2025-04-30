import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mut6/widgets/custom_button_auth.dart';
import 'package:mut6/widgets/custom_text_field.dart';

class AdminListScreen extends StatefulWidget {
  const AdminListScreen({super.key});

  @override
  _AdminListScreenState createState() => _AdminListScreenState();
}

class _AdminListScreenState extends State<AdminListScreen> {
  Map<String, bool> selectedAdmins = {}; // الإداريين المحددين

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text("الإداريين", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('admins')
                .where(
                  'schoolId',
                  isEqualTo: FirebaseAuth.instance.currentUser!.uid,
                )
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("لا يوجد إداريين"));
          }

          final admins = snapshot.data!.docs;
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(20),
                  itemCount: admins.length,
                  itemBuilder: (context, index) {
                    var admin = admins[index];
                    var adminData = admin.data() as Map<String, dynamic>;
                    String adminId = admin.id;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            adminData['name'],
                            style: TextStyle(fontSize: 18),
                            textDirection: TextDirection.rtl,
                          ),
                          SizedBox(width: 10),
                          Checkbox(
                            value: selectedAdmins[adminId] ?? false,
                            onChanged: (bool? value) {
                              setState(() {
                                if (selectedAdmins.containsKey(adminId) &&
                                    !value!) {
                                  selectedAdmins.remove(adminId);
                                } else {
                                  selectedAdmins[adminId] = value!;
                                }
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
                        onPressed: () {
                          _showDeleteDialog();
                        },
                        color: const Color.fromRGBO(33, 150, 243, 1),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: CustomButtonAuth(
                        title: "تعديل",
                        onPressed: () {
                          _editSelectedAdmin();
                        },
                        color: const Color.fromRGBO(33, 150, 243, 1),
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

  void _editSelectedAdmin() async {
    List<String> selectedIds =
        selectedAdmins.keys.where((id) => selectedAdmins[id] == true).toList();

    if (selectedIds.isEmpty || selectedIds.length > 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("يرجى اختيار إداري واحد فقط للتعديل")),
      );
      return;
    }

    String selectedId = selectedIds.first;

    try {
      DocumentSnapshot doc =
          await FirebaseFirestore.instance
              .collection('admins')
              .doc(selectedId)
              .get();

      if (doc.exists) {
        Map<String, dynamic> adminData = doc.data() as Map<String, dynamic>;
        _showEditDialog(context, selectedId, adminData);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("حدث خطأ أثناء تحميل البيانات")));
    }
  }

  Future<bool> _isPhoneAvailable(String phone, String currentAdminId) async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('admins')
              .where('phone', isEqualTo: phone)
              .get();

      return querySnapshot.docs.isEmpty ||
          (querySnapshot.docs.length == 1 &&
              querySnapshot.docs.first.id == currentAdminId);
    } catch (e) {
      print("❌ خطأ أثناء التحقق من رقم الهاتف: $e");
      return false;
    }
  }

  Future<bool> _isEmailAvailable(String email, String currentAdminId) async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('admins')
              .where('email', isEqualTo: email)
              .get();

      return querySnapshot.docs.isEmpty ||
          (querySnapshot.docs.length == 1 &&
              querySnapshot.docs.first.id == currentAdminId);
    } catch (e) {
      print("❌ خطأ أثناء التحقق من البريد الإلكتروني: $e");
      return false;
    }
  }

  void _showEditDialog(
    BuildContext context,
    String adminId,
    Map<String, dynamic> adminData,
  ) {
    TextEditingController nameController = TextEditingController(
      text: adminData['name'],
    );
    TextEditingController idController = TextEditingController(
      text: adminData['id'],
    );
    TextEditingController phoneController = TextEditingController(
      text: adminData['phone'],
    );
    TextEditingController emailController = TextEditingController(
      text: adminData['email'],
    ); // خانة البريد الإلكتروني

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Center(
            child: Text(
              "تعديل بيانات الإداري",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: nameController,
                icon: Icons.person,
                hintText: "اسم الإداري",
                iconColor: Colors.blue,
              ),
              CustomTextField(
                controller: idController,
                icon: Icons.badge,
                hintText: "رقم الإداري",
                iconColor: Colors.blue,
                enabled: false, // جعل الحقل غير قابل للتعديل
              ),
              CustomTextField(
                controller: phoneController,
                icon: Icons.phone,
                hintText: "رقم الهاتف",
                iconColor: Colors.blue,
              ),
              CustomTextField(
                controller: emailController,
                icon: Icons.email,
                hintText: "البريد الإلكتروني",
                iconColor: Colors.blue,
              ), // خانة البريد الإلكتروني
            ],
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: CustomButtonAuth(
                    title: "إلغاء",
                    onPressed: () => Navigator.pop(context),
                    color: const Color.fromRGBO(33, 150, 243, 1),
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

                      // التحقق من أن جميع الحقول مملوءة
                      if (name.isEmpty || phone.isEmpty || email.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("جميع الحقول مطلوبة لإكمال العملية"),
                          ),
                        );
                        return;
                      }

                      // التحقق من صيغة رقم الهاتف
                      if (!phone.startsWith('05') || phone.length != 10) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "رقم الهاتف يجب أن يبدأ بـ '05' ويتكون من 10 أرقام",
                            ),
                          ),
                        );
                        return;
                      }

                      // التحقق من صيغة البريد الإلكتروني
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

                      // التحقق من أن رقم الهاتف غير مستخدم مسبقًا
                      bool isPhoneAvailable = await _isPhoneAvailable(
                        phoneController.text.trim(),
                        adminId,
                      );
                      if (!isPhoneAvailable) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("رقم الهاتف هذا مستخدم مسبقًا"),
                          ),
                        );
                        return;
                      }

                      // التحقق من أن البريد الإلكتروني غير مستخدم مسبقًا
                      bool isEmailAvailable = await _isEmailAvailable(
                        emailController.text.trim(),
                        adminId,
                      );
                      if (!isEmailAvailable) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "البريد الإلكتروني هذا مستخدم مسبقًا",
                            ),
                          ),
                        );
                        return;
                      }

                      // تحديث البيانات في Firestore
                      await FirebaseFirestore.instance
                          .collection('admins')
                          .doc(adminId)
                          .update({
                            'name': nameController.text.trim(),
                            'phone': phoneController.text.trim(),
                            'email': emailController.text.trim(),
                          });

                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("تم تعديل البيانات بنجاح")),
                      );
                    },
                    color: const Color.fromRGBO(33, 150, 243, 1),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog() {
    List<String> selectedIds =
        selectedAdmins.keys.where((id) => selectedAdmins[id] == true).toList();

    if (selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("يرجى اختيار إداري واحد على الأقل للحذف")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Center(
            child: Text(
              "تأكيد العملية",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: CustomButtonAuth(
                    title: "إلغاء",
                    onPressed: () => Navigator.pop(context),
                    color: const Color.fromRGBO(33, 150, 243, 1),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: CustomButtonAuth(
                    title: "حذف",
                    onPressed: () async {
                      for (String id in selectedIds) {
                        await FirebaseFirestore.instance
                            .collection('admins')
                            .doc(id)
                            .delete();
                      }

                      setState(() {
                        selectedAdmins.clear();
                      });

                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("تم حذف الإداريين بنجاح")),
                      );
                    },
                    color: const Color.fromRGBO(33, 150, 243, 1),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
