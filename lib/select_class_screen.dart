import 'package:flutter/material.dart';
import 'students_list_screen.dart'; // استيراد صفحة عرض الطلاب

class SelectClassScreen extends StatelessWidget {
  final String stage;

  SelectClassScreen({required this.stage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(stage, style: TextStyle(color: Colors.white, fontSize: 20)),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (index) {
            final classNumber = index + 1; // أرقام الفصول من 1 إلى 6
            final buttonText =
                '$stage/$classNumber'; // النص المطلوب (مثل "أولى ثانوي/1")
            return Column(
              children: [
                CustomButtonAuth(
                  title: buttonText,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => StudentsListScreen(
                              stage: stage,
                              schoolClass:
                                  '$classNumber', // تمرير رقم الفصل فقط للصفحة التالية
                            ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 30), // المسافة بين الأزرار
              ],
            );
          }),
        ),
      ),
    );
  }
}

class CustomButtonAuth extends StatelessWidget {
  final void Function()? onPressed;
  final String title;

  const CustomButtonAuth({super.key, this.onPressed, required this.title});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 270,
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
