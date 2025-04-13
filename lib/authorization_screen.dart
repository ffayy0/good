import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // لإدارة المصادقة
import 'package:cloud_firestore/cloud_firestore.dart'; // لإدارة Firestore

class AuthorizationScreen extends StatelessWidget {
  final String studentId; // معرف الطالب
  final TextEditingController nameController = TextEditingController();
  final TextEditingController idController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  AuthorizationScreen({super.key, required this.studentId});

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
              hintText: 'اسم الموكل',
            ),
            CustomTextField(
              controller: idController,
              icon: Icons.badge,
              hintText: 'رقم الموكل',
            ),
            CustomTextField(
              controller: passwordController,
              icon: Icons.lock,
              hintText: 'كلمة المرور',
              obscureText: true,
            ),
            const SizedBox(height: 40), // يبعد الزر عن الحقول
            Center(
              child: SizedBox(
                width: 200, // جعل الزر بالوسط
                child: CustomButtonAuth(
                  title: 'تسجيل',
                  onPressed: () async {
                    if (_validateFields(context)) {
                      try {
                        // إنشاء حساب جديد باستخدام Firebase Authentication
                        final UserCredential userCredential = await FirebaseAuth
                            .instance
                            .createUserWithEmailAndPassword(
                              email:
                                  "${idController.text}@example.com", // استخدام رقم الموكل كبريد إلكتروني
                              password: passwordController.text,
                            );

                        // حفظ بيانات الحساب في Firestore
                        await FirebaseFirestore.instance
                            .collection('Authorizations')
                            .doc(
                              userCredential.user!.uid,
                            ) // استخدام معرف المستخدم كمفتاح
                            .set({
                              'name': nameController.text,
                              'id': idController.text,
                              'password':
                                  passwordController
                                      .text, // يمكنك تخزين كلمة المرور بشكل مشفر إذا كنت تحتاج الأمان العالي
                              'studentId': studentId,
                            });

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

  // دالة للتحقق من صحة الحقول
  bool _validateFields(BuildContext context) {
    final name = nameController.text.trim();
    final id = idController.text.trim();
    final password = passwordController.text.trim();

    // التحقق من اسم الموكل
    if (name.isEmpty || !name.contains(" ")) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("يرجى إدخال اسم ثنائي صالح")));
      return false;
    }

    // التحقق من رقم الموكل
    if (id.isEmpty ||
        int.tryParse(id) == null ||
        id.length < 8 ||
        id.length > 15) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("يرجى إدخال رقم موكل صالح (8-15 رقمًا)")),
      );
      return false;
    }

    // التحقق من كلمة المرور
    final passwordRegex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d]{8,20}$',
    );
    if (!passwordRegex.hasMatch(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "كلمة المرور يجب أن تحتوي على أحرف كبيرة وصغيرة وأرقام، وطولها بين 8 و20 حرفًا",
          ),
        ),
      );
      return false;
    }

    // إذا مررت جميع الفحوصات
    return true;
  }

  // دالة لإعادة تهيئة الحقول
  void _clearFields() {
    nameController.clear();
    idController.clear();
    passwordController.clear();
  }
}

// ودجة مخصصة لحقل النص
class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final IconData icon;
  final String hintText;
  final bool obscureText;

  CustomTextField({
    required this.controller,
    required this.icon,
    required this.hintText,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12), // مسافة بين الحقول
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.indigo),
          hintText: hintText,
          filled: true,
          fillColor: Colors.grey[200], // خلفية رمادية للحقل فقط
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

// ودجة مخصصة للزر
class CustomButtonAuth extends StatelessWidget {
  final void Function()? onPressed;
  final String title;

  const CustomButtonAuth({super.key, this.onPressed, required this.title});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170, // عرض الزر
      child: MaterialButton(
        height: 45,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        color: const Color.fromARGB(255, 1, 113, 189),
        textColor: Colors.white,
        onPressed: onPressed,
        child: Text(title, style: TextStyle(fontSize: 18)),
      ),
    );
  }
}