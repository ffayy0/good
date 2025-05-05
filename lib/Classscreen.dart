import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'select_class_screen.dart'; // استيراد صفحة اختيار الصف

class ClassScreen extends StatefulWidget {
  final String schoolId; // ✅ تعريف معلمة schoolId
  ClassScreen({required this.schoolId}); // ✅ قبول schoolId كمعلمة

  @override
  _ClassScreenState createState() => _ClassScreenState();
}

class _ClassScreenState extends State<ClassScreen> {
  String? schoolStage; // المرحلة المختارة من Firestore
  bool isLoading = true; // حالة التحميل

  @override
  void initState() {
    super.initState();
    _fetchSchoolData(); // جلب بيانات المدرسة باستخدام schoolId
  }

  // دالة لجلب بيانات المدرسة من Firestore باستخدام schoolId
  Future<void> _fetchSchoolData() async {
    try {
      print("Fetching school data with School ID: ${widget.schoolId}");
      DocumentSnapshot doc =
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(widget.schoolId)
              .get();
      if (!doc.exists) {
        print("❌ الوثيقة غير موجودة في Firestore.");
        throw Exception("لم يتم العثور على بيانات المدرسة");
      }
      final data = doc.data() as Map<String, dynamic>;
      if (!data.containsKey('stage')) {
        print("❌ الحقل 'stage' غير موجود في الوثيقة.");
        throw Exception("بيانات المدرسة غير مكتملة");
      }
      setState(() {
        schoolStage = data['stage'];
        isLoading = false;
      });
      print("✅ تم جلب المرحلة بنجاح: $schoolStage");
    } catch (e) {
      print("❌ خطأ أثناء جلب بيانات المدرسة: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("حدث خطأ أثناء جلب بيانات المدرسة")),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

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
      body:
          isLoading
              ? Center(child: CircularProgressIndicator()) // عرض مؤشر التحميل
              : schoolStage == null
              ? Center(child: Text("لم يتم العثور على بيانات المدرسة"))
              : Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // بناء الأزرار بناءً على المرحلة
                    ..._buildGradeButtons(),
                  ],
                ),
              ),
    );
  }

  // دالة لإنشاء أزرار الصفوف بناءً على المرحلة
  List<Widget> _buildGradeButtons() {
    final gradesMap = {
      'ابتدائي': [
        'أولى ابتدائي',
        'ثاني ابتدائي',
        'ثالث ابتدائي',
        'رابع ابتدائي',
        'خامس ابتدائي',
        'سادس ابتدائي',
      ],
      'متوسط': ['أولى متوسط', 'ثاني متوسط', 'ثالث متوسط'],
      'ثانوي': ['أولى ثانوي', 'ثاني ثانوي', 'ثالث ثانوي'],
    };
    final grades = gradesMap[schoolStage] ?? [];
    return grades.map((grade) {
      return Column(
        children: [
          CustomButton(
            title: grade,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SelectClassScreen(stage: grade),
                ),
              );
            },
          ),
          SizedBox(height: 20), // المسافة بين الأزرار
        ],
      );
    }).toList();
  }
}

// زر مخصص لعرض المراحل
class CustomButton extends StatelessWidget {
  final String title;
  final VoidCallback onPressed;

  const CustomButton({required this.title, required this.onPressed});

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
