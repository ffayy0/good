import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController schoolNameController = TextEditingController();
  final TextEditingController schoolLocationController =
      TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController emailController = TextEditingController();
  bool _isLoading = false;

  // المرحلة
  String? selectedStage;
  final List<String> schoolStages = ['ابتدائي', 'متوسط', 'ثانوي'];
  // بيانات المرسل
  final String senderEmail = "8ffaay01@gmail.com"; // ✉ بريد المرسل
  final String senderPassword = "vljn jaxv hukr qbct"; // 🔑 كلمة مرور التطبيق

  Future<LatLng?> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('خدمة الموقع غير مفعلة')));
      return null;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم رفض صلاحية الموقع')));
        return null;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('صلاحية الموقع مرفوضة نهائيًا')),
      );
      return null;
    }
    final position = await Geolocator.getCurrentPosition();
    return LatLng(position.latitude, position.longitude);
  }

  // ✅ دالة إرسال البريد الإلكتروني
  Future<void> sendConfirmationEmail(
    String recipientEmail,
    String schoolName,
  ) async {
    final smtpServer = gmail(senderEmail, senderPassword);

    final message =
        Message()
          ..from = Address(senderEmail, "Mutabie App")
          ..recipients.add(recipientEmail)
          ..subject = "تأكيد إنشاء حساب المدرسة"
          ..text =
              "مرحبًا،\n\n"
              "تهانينا! تم إنشاء حساب المدرسة '$schoolName' بنجاح.\n\n"
              "يمكنك الآن تسجيل الدخول واستخدام النظام.\n\n"
              "تحياتنا، فريق متابع.";

    try {
      await send(message, smtpServer);
      print("📩 تم إرسال البريد الإلكتروني بنجاح إلى $recipientEmail");
    } catch (e) {
      print("❌ خطأ في إرسال البريد: $e");
    }
  }

  Future<void> registerSchool() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();
    final schoolName = schoolNameController.text.trim();
    final schoolLocation = schoolLocationController.text.trim();

    // التحقق من الاسم
    if (schoolName.isEmpty ||
        schoolName.length < 3 ||
        !RegExp(r'^[\u0600-\u06FFa-zA-Z\s]+$').hasMatch(schoolName)) {
      _showErrorDialog('يرجى إدخال اسم مدرسة صحيح (٣ أحرف أو أكثر).');
      return;
    }

    // التحقق من الإيميل
    if (email.isEmpty ||
        !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$').hasMatch(email)) {
      _showErrorDialog('يرجى إدخال بريد إلكتروني صحيح.');
      return;
    }

    if (selectedStage == null) {
      _showErrorDialog('يرجى اختيار مرحلة المدرسة.');
      return;
    }

    if (schoolLocation.isEmpty) {
      _showErrorDialog('يرجى إدخال موقع المدرسة.');
      return;
    }
    if (password.isEmpty || password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('كلمة المرور يجب أن تكون بطول 6 أحرف أو أكثر')),
      );
      return;
    }
    // التحقق من كلمة المرور

    if (password != confirmPassword) {
      _showErrorDialog('كلمات المرور غير متطابقة.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      double? latitude;
      double? longitude;

      try {
        List<String> coordinates = schoolLocation.split(',');
        if (coordinates.length == 2) {
          latitude = double.tryParse(coordinates[0].trim());
          longitude = double.tryParse(coordinates[1].trim());
        }
      } catch (e) {
        print('⚠️ خطأ في تحليل schoolLocation إلى إحداثيات: $e');
      }

      await FirebaseFirestore.instance
          .collection('schools')
          .doc(userCredential.user!.uid)
          .set({
            'schoolName': schoolName,
            'schoolLocation': schoolLocation,
            'latitude': latitude,
            'longitude': longitude,
            'email': email,
            'stage': selectedStage,
            'createdAt': DateTime.now(),
          });

      // ✅ إرسال البريد الإلكتروني بعد إنشاء الحساب
      await sendConfirmationEmail(email, schoolName);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إنشاء الحساب وتخزين البيانات بنجاح!')),
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String errorMessage = '';
      if (e.code == 'email-already-in-use') {
        errorMessage = 'البريد الإلكتروني مستخدم بالفعل.';
      } else {
        errorMessage = 'حدث خطأ أثناء إنشاء الحساب.';
      }
      _showErrorDialog(errorMessage);
    } catch (e) {
      _showErrorDialog('حدث خطأ غير متوقع: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: const Text(
              'خطأ',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
              textAlign: TextAlign.center,
            ),
            content: Text(message, textAlign: TextAlign.center),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('حسناً'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text('تسجيل مدرسة', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.network(
                'https://i.postimg.cc/DwnKf079/321e9c9d-4d67-4112-a513-d368fc26b0c0.jpg',
                width: 200,
                height: 150,
              ),
              const SizedBox(height: 20),
              const Text(
                'تسجيل حساب مدرسة',
                style: TextStyle(fontSize: 20, color: Colors.black),
              ),
              const SizedBox(height: 30),
              _buildDropdownField(
                label: 'مرحلة المدرسة',
                icon: Icons.class_,
                value: selectedStage,
                items: schoolStages,
                onChanged: (value) {
                  setState(() {
                    selectedStage = value;
                  });
                },
              ),
              const SizedBox(height: 15),
              _buildInputField(
                schoolNameController,
                'اسم المدرسة',
                Icons.school,
              ),
              const SizedBox(height: 15),
              GestureDetector(
                onTap: () async {
                  final LatLng? currentLocation = await _getCurrentLocation();
                  if (currentLocation != null) {
                    setState(() {
                      schoolLocationController.text =
                          '${currentLocation.latitude}, ${currentLocation.longitude}';
                    });
                  }
                },
                child: AbsorbPointer(
                  child: _buildInputField(
                    schoolLocationController,
                    'اضغط للحصول على موقع المدرسة',
                    Icons.location_on,
                    helperText: 'سيتم جلب موقعك الحالي تلقائيًا',
                  ),
                ),
              ),
              const SizedBox(height: 15),
              _buildInputField(
                emailController,
                'البريد الإلكتروني',
                Icons.email,
              ),
              const SizedBox(height: 15),
              _buildInputField(
                passwordController,
                'كلمة المرور',
                Icons.lock,
                obscureText: true,
              ),
              const SizedBox(height: 15),
              _buildInputField(
                confirmPasswordController,
                'تأكيد كلمة المرور',
                Icons.lock_outline,
                obscureText: true,
              ),
              const SizedBox(height: 30),
              _buildActionButton('تسجيل', registerSchool),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool obscureText = false,
    String? helperText,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color.fromARGB(255, 1, 113, 189)),
        hintText: hint,
        helperText: helperText,
        filled: true,
        fillColor: Colors.grey[300],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 1, 113, 189),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child:
            _isLoading
                ? const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                )
                : Text(
                  label,
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color.fromARGB(255, 1, 113, 189)),
        labelText: label,
        filled: true,
        fillColor: Colors.grey[300],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      items:
          items
              .map(
                (String item) =>
                    DropdownMenuItem<String>(value: item, child: Text(item)),
              )
              .toList(),
      onChanged: onChanged,
    );
  }
}
