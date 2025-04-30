import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
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

  String? selectedStage;
  final List<String> schoolStages = ['ابتدائي', 'متوسط', 'ثانوي'];

  final String senderEmail = "8ffaay01@gmail.com";
  final String senderPassword = "vljn jaxv hukr qbct";

  Future<LatLng?> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnackBar('خدمة الموقع غير مفعلة');
      return null;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackBar('تم رفض صلاحية الموقع');
        return null;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      _showSnackBar('صلاحية الموقع مرفوضة نهائيًا');
      return null;
    }
    final position = await Geolocator.getCurrentPosition();
    return LatLng(position.latitude, position.longitude);
  }

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
              "مرحبًا،\n\nتهانينا! تم إنشاء حساب المدرسة '$schoolName' بنجاح.\n\nيمكنك الآن تسجيل الدخول واستخدام النظام.\n\nتحياتنا، فريق متابع.";

    try {
      await send(message, smtpServer);
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

    if (schoolName.isEmpty || schoolName.length < 3) {
      _showSnackBar('اسم المدرسة يجب أن يكون ٣ أحرف أو أكثر.');
      return;
    }

    if (email.isEmpty ||
        !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$').hasMatch(email)) {
      _showSnackBar('يرجى إدخال بريد إلكتروني صحيح.');
      return;
    }

    var emailExists =
        await FirebaseFirestore.instance
            .collection('schools')
            .where('email', isEqualTo: email)
            .get();
    if (emailExists.docs.isNotEmpty) {
      _showSnackBar('البريد الإلكتروني مستخدم بالفعل.');
      return;
    }

    if (selectedStage == null) {
      _showSnackBar('يرجى اختيار مرحلة المدرسة.');
      return;
    }

    if (schoolLocation.isEmpty) {
      _showSnackBar('يرجى إدخال موقع المدرسة.');
      return;
    }
    String passwordPattern = r'^(?=.*[a-zA-Z0-9!@#\$&\.]).{6,}$';
    RegExp regExp = RegExp(passwordPattern);
    if (password.isEmpty || !regExp.hasMatch(password)) {
      _showSnackBar(
        'كلمة المرور يجب أن تحتوي على حروف أو أرقام أو رموز وطول لا يقل عن ٦ أحرف.',
      );
      return;
    }

    if (password != confirmPassword) {
      _showSnackBar('كلمة المرور وتأكيدها غير متطابقين.');
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
            'attendanceStartTime': '07:30',
          });

      await sendConfirmationEmail(email, schoolName);

      _showSnackBar('تم إنشاء الحساب بنجاح!');
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        _showSnackBar('البريد الإلكتروني مستخدم بالفعل.');
      } else {
        _showSnackBar('حدث خطأ أثناء إنشاء الحساب.');
      }
    } catch (e) {
      _showSnackBar('حدث خطأ غير متوقع.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.grey[800],
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
