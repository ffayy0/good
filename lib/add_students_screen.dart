import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:mut6/StudentCardScreen.dart';
import 'package:mut6/select_class_screen.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

// إضافة الكود الخاص بالزر

class StudentBarcodeScreen extends StatefulWidget {
  @override
  _StudentBarcodeScreenState createState() => _StudentBarcodeScreenState();
}

class _StudentBarcodeScreenState extends State<StudentBarcodeScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _guardianIdController = TextEditingController();

  final List<String> _stages = ['أولى ثانوي', 'ثاني ثانوي', 'ثالث ثانوي'];

  String? _selectedStage;
  String? _selectedClass;
  String? _qrData;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // تحديد اللون الأزرق الفاتح المستخدم في الزر
  final Color _buttonColor = Color(0xFF0171BD); // الأزرق الفاتح

  final Color _textFieldFillColor =
      Colors.grey[200]!; // اللون الرمادي الفاتح للخلفية
  final Color _textColor =
      Colors.blue; // تغيير اللون إلى الأزرق للنصوص داخل المربعات

  Future<void> _generateQR() async {
    String name = _nameController.text.trim();
    String id = _idController.text.trim();
    String guardianId = _guardianIdController.text.trim();

    if ([name, id, guardianId, _selectedStage, _selectedClass].contains(null) ||
        [name, id, guardianId].any((e) => e.isEmpty)) {
      _showSnackBar('رجاءً عَبِّ البيانات كاملة');
      return;
    }

    // تحقق من التكرار
    bool isDuplicate = await _isStudentDuplicate(id);
    if (isDuplicate) {
      _showSnackBar('هذا الطالب مسجل مسبقًا');
      return;
    }

    String? emailFromDb = await _getGuardianEmail(guardianId);
    if (emailFromDb == null) {
      _showSnackBar('لم يتم العثور على البريد الإلكتروني لولي الأمر');
      return;
    }

    try {
      await _firestore.collection('students').doc(id).set({
        'name': name,
        'id': id,
        'stage': _selectedStage,
        'schoolClass': _selectedClass,
        'guardianId': guardianId,
        'guardianEmail': emailFromDb,
      });

      _qrData =
          'Name: $name\nID: $id\nStage: $_selectedStage\nClass: $_selectedClass\nGuardian ID: $guardianId\nEmail: $emailFromDb';

      await _sendStudentCardEmail(
        emailFromDb,
        name,
        id,
        _selectedStage!,
        _selectedClass!,
        guardianId,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => StudentCardScreen(
                name: name,
                id: id,
                stage: _selectedStage!,
                schoolClass: _selectedClass!,
                guardianId: guardianId,
                qrData: _qrData!,
                guardianEmail: emailFromDb,
              ),
        ),
      );
    } catch (e) {
      print("❌ خطأ: $e");
      _showSnackBar('حدث خطأ أثناء حفظ البيانات');
    }
  }

  Future<bool> _isStudentDuplicate(String id) async {
    final doc = await _firestore.collection('students').doc(id).get();
    return doc.exists;
  }

  Future<String?> _getGuardianEmail(String guardianId) async {
    try {
      final query =
          await _firestore
              .collection('parents')
              .where('id', isEqualTo: guardianId)
              .get();
      if (query.docs.isNotEmpty) {
        return query.docs.first['email'];
      }
    } catch (e) {
      print("❌ خطأ في جلب البريد الإلكتروني: $e");
    }
    return null;
  }

  Future<void> _sendStudentCardEmail(
    String email,
    String name,
    String id,
    String stage,
    String schoolClass,
    String guardianId,
  ) async {
    final smtpServer = gmail('8ffaay01@gmail.com', 'vljn jaxv hukr qbct');
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build:
            (context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'بطاقة الطالب',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Text("الاسم: $name"),
                pw.Text("رقم الهوية: $id"),
                pw.Text("المرحلة: $stage"),
                pw.Text("الصف: $schoolClass"),
                pw.Text("رقم ولي الأمر: $guardianId"),
                pw.SizedBox(height: 20),
                pw.Text("رمز QR:"),
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data:
                      'Name: $name\nID: $id\nStage: $stage\nClass: $schoolClass\nGuardian ID: $guardianId',
                  width: 100,
                  height: 100,
                ),
              ],
            ),
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/student_card.pdf');
    await file.writeAsBytes(await pdf.save());

    final message =
        Message()
          ..from = Address('8ffaay01@gmail.com', 'Student App')
          ..recipients.add(email)
          ..subject = 'بطاقة الطالب الخاصة بك'
          ..text =
              'مرحبًا $name،\n\nمرفقة بطاقة الطالب الخاصة بك.\n\nتحياتنا،\nفريق التطبيق'
          ..attachments = [
            FileAttachment(file)
              ..location = Location.inline
              ..cid = '<student_card>',
          ];

    try {
      await send(message, smtpServer);
      _showSnackBar('تم إرسال البريد الإلكتروني بنجاح');
    } catch (e) {
      print("❌ فشل إرسال الإيميل: $e");
      _showSnackBar('فشل إرسال البريد الإلكتروني');
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _selectClass() async {
    if (_selectedStage == null) {
      _showSnackBar('اختر المرحلة الدراسية أولاً');
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SelectClassScreen(stage: _selectedStage!),
      ),
    );

    if (result != null && result is String) {
      setState(() {
        _selectedClass = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('إضافة طالب', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF4CAF50),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildTextField(_nameController, "اسم الطالب", Icons.person),
              SizedBox(height: 10),
              _buildTextField(
                _idController,
                "رقم الهوية",
                Icons.credit_card,
                isNumber: true,
              ),
              SizedBox(height: 10),
              _buildDropdown(),
              SizedBox(height: 10),
              _buildClassSelector(),
              SizedBox(height: 10),
              _buildTextField(
                _guardianIdController,
                "رقم ولي الأمر",
                Icons.person_outline,
                isNumber: true,
              ),
              SizedBox(height: 20),
              // استخدم الزر المخصص من CustomButtonAuth
              CustomButtonAuth(
                title: 'إنشاء بطاقة الطالب',
                onPressed: _generateQR,
                // هنا نستخدم نفس درجة اللون الأزرق
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Color(0xFF4CAF50)),
        border: OutlineInputBorder(),
        prefixIcon: Icon(
          icon,
          color: _buttonColor,
        ), // استخدام نفس اللون للأيقونة
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: _buttonColor),
        ),
        hintStyle: TextStyle(color: _textColor), // تغيير النص إلى اللون الأزرق
        filled: true,
        fillColor: _textFieldFillColor,
      ),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'المرحلة الدراسية',
        labelStyle: TextStyle(color: Color(0xFF4CAF50)),
        border: OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: _buttonColor),
        ),
      ),
      value: _selectedStage,
      items:
          _stages
              .map(
                (stage) => DropdownMenuItem(value: stage, child: Text(stage)),
              )
              .toList(),
      onChanged:
          (value) => setState(() {
            _selectedStage = value;
            _selectedClass = null;
          }),
    );
  }

  Widget _buildClassSelector() {
    return InkWell(
      onTap: _selectClass,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'اختر الصف',
          labelStyle: TextStyle(color: Color(0xFF4CAF50)),
          border: OutlineInputBorder(),
        ),
        child: Text(
          _selectedClass ?? 'اضغط لاختيار الصف',
          style: TextStyle(
            color: _selectedClass == null ? Colors.grey : Colors.black,
          ),
        ),
      ),
    );
  }
}
