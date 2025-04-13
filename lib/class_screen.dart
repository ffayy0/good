// class_screen.dart
import 'package:flutter/material.dart';
import 'select_class_screen.dart'; // استيراد صفحة اختيار الكلاس

class ClassScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text("المرحلة الدراسية", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // العودة إلى الصفحة السابقة
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomButton(
              title: "أولى ثانوي",
              onPressed: () {
                // الانتقال إلى صفحة اختيار الكلاس مع تمرير اسم المرحلة
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => SelectClassScreen(stage: "أولى ثانوي"),
                  ),
                );
              },
            ),
            SizedBox(height: 40), // المسافة بين الأزرار
            CustomButton(
              title: "ثاني ثانوي",
              onPressed: () {
                // الانتقال إلى صفحة اختيار الكلاس مع تمرير اسم المرحلة
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => SelectClassScreen(stage: "ثاني ثانوي"),
                  ),
                );
              },
            ),
            SizedBox(height: 40), // المسافة بين الأزرار
            CustomButton(
              title: "ثالث ثانوي",
              onPressed: () {
                // الانتقال إلى صفحة اختيار الكلاس مع تمرير اسم المرحلة
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => SelectClassScreen(stage: "ثالث ثانوي"),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class CustomButton extends StatelessWidget {
  final String title;
  final VoidCallback? onPressed;

  const CustomButton({required this.title, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300, // عرض الزر
      child: MaterialButton(
        height: 60,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        color: const Color.fromARGB(255, 1, 113, 189),
        textColor: Colors.white,
        onPressed: onPressed,
        child: Text(title, style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
