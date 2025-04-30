import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final IconData icon;
  final String hintText;
  final bool obscureText; // خيار لإخفاء النص (مثل كلمات المرور)
  final TextStyle? textStyle; // نمط النص
  final Color? fillColor; // لون الخلفية
  final Color? iconColor; // لون الأيقونة
  final bool enabled; // معلمة جديدة لتحديد إذا كان الحقل قابلاً للتعديل

  const CustomTextField({
    super.key,
    required this.controller,
    required this.icon,
    required this.hintText,
    this.obscureText = false, // القيمة الافتراضية هي false
    this.textStyle, // بدون قيمة افتراضية
    this.fillColor, // بدون قيمة افتراضية
    this.iconColor, // بدون قيمة افتراضية
    this.enabled =
        true, // القيمة الافتراضية هي true (الحقل قابل للتعديل بشكل افتراضي)
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText, // استخدام الخيار لإخفاء النص
      enabled: enabled, // تمرير المعلمة إلى TextField
      style: textStyle, // تطبيق نمط النص إذا تم توفيره
      decoration: InputDecoration(
        prefixIcon: Icon(
          icon,
          color: iconColor ?? Colors.indigo,
        ), // لون الأيقونة
        hintText: hintText,
        hintStyle: textStyle, // تطبيق نفس نمط النص على النص التوضيحي
        filled: true,
        fillColor: fillColor ?? Colors.grey[200], // لون الخلفية
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
