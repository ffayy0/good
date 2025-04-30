import 'package:flutter/material.dart';

class ExcuseDetailsScreen extends StatelessWidget {
  const ExcuseDetailsScreen({super.key});

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
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "الطالبة: مريم محمد الحربي",
                    style: TextStyle(fontSize: 18),
                  ),
                  Text("الصف: 5/3", style: TextStyle(fontSize: 18)),
                  Text(
                    "اليوم: الأربعاء التاريخ: 23/8",
                    style: TextStyle(fontSize: 18),
                  ),
                  Text(
                    "السبب: لديها موعد في المستشفى",
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            MaterialButton(
              onPressed: () {},
              color: Colors.grey[300],
              textColor: Color.fromARGB(255, 1, 113, 189),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              height: 50,
              minWidth: double.infinity,
              child: Text("عرض الملف المرفق"),
            ),
            Spacer(), // يدفع الأزرار إلى الأسفل
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MaterialButton(
                  onPressed: () {},
                  color: Color.fromARGB(255, 1, 113, 189),
                  textColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  height: 50,
                  minWidth: 200,
                  child: Text("رفض"),
                ),
                MaterialButton(
                  onPressed: () {},
                  color: Color.fromARGB(255, 1, 113, 189),
                  textColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  height: 50,
                  minWidth: 200,
                  child: Text("قبول"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
