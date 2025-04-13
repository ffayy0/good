import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

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

  Future<LatLng?> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خدمة الموقع غير مفعلة')));
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تم رفض صلاحية الموقع')));
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('صلاحية الموقع مرفوضة نهائيًا')));
      return null;
    }

    final position = await Geolocator.getCurrentPosition();
    return LatLng(position.latitude, position.longitude);
  }

  Future<void> registerSchool() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();
    final schoolName = schoolNameController.text.trim();
    final schoolLocation = schoolLocationController.text.trim();

    if (selectedStage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار مرحلة المدرسة')),
      );
      return;
    }

    if (schoolName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('يرجى إدخال اسم المدرسة')));
      return;
    }

    if (schoolLocation.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('يرجى إدخال موقع المدرسة')));
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('يرجى إدخال بريد إلكتروني صالح')));
      return;
    }

    String passwordPattern =
        r'^(?=.*[A-Z])(?=.*[a-z])(?=.*[0-9])(?=.*[!@#\$&]).{8,}$';
    RegExp regExp = RegExp(passwordPattern);
    if (password.isEmpty || !regExp.hasMatch(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'كلمة المرور يجب أن تحتوي على أحرف كبيرة وصغيرة وأرقام ورموز، وأن تكون بطول 8 أحرف على الأقل',
          ),
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('كلمات المرور غير متطابقة')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      double? latitude;
      double? longitude;

      try {
        List<Location> locations = await locationFromAddress(schoolLocation);
        if (locations.isNotEmpty) {
          latitude = locations.first.latitude;
          longitude = locations.first.longitude;
        }
      } catch (e) {
        print('خطأ في تحويل العنوان إلى إحداثيات: $e');
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إنشاء الحساب وتخزين البيانات بنجاح!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطأ أثناء إنشاء الحساب: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 1, 113, 189),
        title: const Text('تسجيل مدرسة'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
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
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),

              // القائمة المنسدلة لاختيار المرحلة
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
          items.map((String item) {
            return DropdownMenuItem<String>(value: item, child: Text(item));
          }).toList(),
      onChanged: onChanged,
    );
  }
}
