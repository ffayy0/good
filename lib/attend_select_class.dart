import 'package:flutter/material.dart';
import 'package:mut6/attendence_names.dart';
import 'widgets/custom_button_auth.dart';

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
          onPressed: () => Navigator.pop(context),
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
                '$stage/$classNumber'; // النص المطلوب (مثل "ثاني ثانوي/3")
            return Column(
              children: [
                CustomButtonAuth(
                  title: buttonText,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => AttendenceNames(
                              stage: stage,
                              classNumber: classNumber,
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
