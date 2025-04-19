import 'package:flutter/material.dart';

class AttachedExcuses extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        centerTitle: true,
        title: Text("الأعذار المرفقة", style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CustomButton(title: "مريم محمد الحربي", onPressed: () {}),
            CustomButton(title: "نجود خالد الحربي", onPressed: () {}),
            CustomButton(title: "ساره محمد العمري", onPressed: () {}),
            Spacer(),
          ],
        ),
      ),
    );
  }
}

class CustomButton extends StatelessWidget {
  final String title;
  final VoidCallback onPressed;

  const CustomButton({Key? key, required this.title, required this.onPressed})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: MaterialButton(
        height: 50,
        minWidth: double.infinity,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        color: Colors.grey[300],
        textColor: Colors.black,
        onPressed: onPressed,
        child: Text(title, style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
