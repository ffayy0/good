import 'package:flutter/material.dart';

class CustomButtonAuth extends StatelessWidget {
  // الخصائص
  final String title; // نص الزر
  final VoidCallback onPressed; // الدالة التي تنفذ عند الضغط على الزر
  final Color color; // لون الزر (اختياري)
  final double height; // ارتفاع الزر (اختياري)
  final double minWidth; // العرض الأدنى للزر (اختياري)

  // البناء
  const CustomButtonAuth({
    Key? key,
    required this.title,
    required this.onPressed,
    this.color = const Color.fromARGB(255, 1, 113, 189), // لون افتراضي
    this.height = 60, // ارتفاع افتراضي
    this.minWidth = 260, // عرض أدنى افتراضي
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      height: height, // استخدام الارتفاع المحدد أو الافتراضي
      minWidth: minWidth, // استخدام العرض الأدنى المحدد أو الافتراضي
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25), // زوايا مدورة
      ),
      color: color, // استخدام اللون المحدد أو الافتراضي
      textColor: Colors.white, // لون النص أبيض
      onPressed: onPressed, // تنفيذ الدالة عند الضغط
      child: Text(
        title, // نص الزر
        style: TextStyle(fontSize: 20), // حجم النص
      ),
    );
  }
}
