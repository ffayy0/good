import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:mut6/StudentCardScreen.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

class StudentBarcodeScreen extends StatefulWidget {
  @override
  _StudentBarcodeScreenState createState() => _StudentBarcodeScreenState();
}

class _StudentBarcodeScreenState extends State<StudentBarcodeScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _guardianIdController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // القوائم الخاصة بالمرحلة الدراسية والصف
  final List<String> _stages = ['أولى ابتدائى', 'ثاني ابتدائى', 'ثالث ابتدائى'];
  final List<String> _classes = ['1', '2', '3', '4', '5', '6'];

  String? _selectedStage; // المرحلة الدراسية المختارة
  String? _selectedClass; // الصف الدراسي المختار
  String? _qrData; // بيانات QR

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // الألوان المستخدمة في التصميم
  final Color _iconColor = const Color(
    0xFF007AFF,
  ); // أزرق مشابه للون iOS الافتراضي
  final Color _buttonColor = const Color(0xFF007AFF); // نفس اللون الأزرق للزر
  final Color _textFieldFillColor =
      Colors.grey[200]!; // اللون الرمادي الفاتح للخلفية
  final Color _textColor = Colors.black; // اللون الأسود للنصوص داخل المربعات

  Future<void> _generateQR() async {
    String name = _nameController.text.trim();
    String id = _idController.text.trim();
    String guardianId = _guardianIdController.text.trim();
    String phone = _phoneController.text.trim();

    // التحقق من صحة الاسم ليكون ثلاثي
    if (name.split(' ').length < 3) {
      _showSnackBar('الاسم يجب أن يتكون من ثلاثة أجزاء على الأقل');
      return;
    }

    // التحقق من طول رقم الهوية ليكون 10 أرقام
    if (id.length != 10) {
      _showSnackBar('رقم الهوية يجب أن يكون 10 أرقام');
      return;
    }

    // التحقق من طول رقم الجوال ليكون 10 أرقام
    if (phone.length != 10) {
      _showSnackBar('رقم الجوال يجب أن يكون 10 أرقام');
      return;
    }

    // التحقق من أن جميع الحقول مملوءة
    if ([_selectedStage, _selectedClass].contains(null)) {
      _showSnackBar('رجاءً عَبِّ البيانات كاملة');
      return;
    }

    // التحقق من عدم وجود طالب بنفس الرقم
    bool isDuplicate = await _isStudentDuplicate(id);
    if (isDuplicate) {
      _showSnackBar('هذا الطالب مسجل مسبقًا');
      return;
    }

    // جلب البريد الإلكتروني لولي الأمر
    String? emailFromDb = await _getGuardianEmail(guardianId);
    if (emailFromDb == null) {
      _showSnackBar('لم يتم العثور على البريد الإلكتروني لولي الأمر');
      return;
    }

    try {
      // حفظ بيانات الطالب في Firestore
      await _firestore.collection('students').doc(id).set({
        'name': name,
        'id': id,
        'stage': _selectedStage,
        'schoolClass': _selectedClass,
        'guardianId': guardianId,
        'guardianEmail': emailFromDb,
        'phone': phone,
        'role': 'students',
        'schoolId': FirebaseAuth.instance.currentUser!.uid,
      });

      // إنشاء بيانات QR
      _qrData =
          'Name: $name\nID: $id\nStage: $_selectedStage\nClass: $_selectedClass\nGuardian ID: $guardianId\nPhone: $phone';

      // إرسال بطاقة الطالب عبر البريد الإلكتروني
      await _sendStudentCardEmail(
        emailFromDb,
        name,
        id,
        _selectedStage!,
        _selectedClass!,
        guardianId,
        phone,
      );

      // التنقل إلى صفحة عرض بطاقة الطالب
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
                guardianPhone: phone,
              ),
        ),
      );
    } catch (e) {
      print("❌ خطأ: $e");
      _showSnackBar('حدث خطأ أثناء حفظ البيانات');
    }
  }

  // التحقق من تكرار الطالب
  Future<bool> _isStudentDuplicate(String id) async {
    final doc = await _firestore.collection('students').doc(id).get();
    return doc.exists;
  }

  // جلب البريد الإلكتروني لولي الأمر
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

  // إرسال بطاقة الطالب عبر البريد الإلكتروني
  Future<void> _sendStudentCardEmail(
    String email,
    String name,
    String id,
    String stage,
    String schoolClass,
    String guardianId,
    String phone,
  ) async {
    final smtpServer = gmail('8ffaay01@gmail.com', 'vljn jaxv hukr qbct');
    final pdf = pw.Document();

    // تحميل الخط الجديد (Cairo)
    final customFont = await rootBundle.load(
      "assets/fonts/Cairo-VariableFont_slnt,wght.ttf",
    );
    final ttf = pw.Font.ttf(customFont.buffer.asByteData());

    // تحميل الشعار
    final logoData = await rootBundle.load('assets/images/logo.png');
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

    // إنشاء ملف PDF
    pdf.addPage(
      pw.Page(
        build:
            (context) => pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Center(
                child: pw.Container(
                  decoration: pw.BoxDecoration(
                    borderRadius: pw.BorderRadius.circular(16),
                    color: PdfColor.fromInt(0xFFFFFFFF), // خلفية بيضاء
                    border: pw.Border.all(
                      color: PdfColor.fromInt(0xFF0171BD), // اللون الأزرق
                      width: 2,
                    ),
                  ),
                  padding: pw.EdgeInsets.all(20),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // إضافة الشعار
                      pw.Center(
                        child: pw.Image(logoImage, width: 100, height: 50),
                      ),
                      pw.SizedBox(height: 16),

                      // العنوان الرئيسي
                      pw.Center(
                        child: pw.Text(
                          'بطاقة الطالب',
                          style: pw.TextStyle(
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                            font: ttf,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 16),

                      // معلومات الطالب
                      pw.Text("الاسم: $name", style: pw.TextStyle(font: ttf)),
                      pw.Text(
                        "رقم الهوية: $id",
                        style: pw.TextStyle(font: ttf),
                      ),
                      pw.Text(
                        "المرحلة: $stage",
                        style: pw.TextStyle(font: ttf),
                      ),
                      pw.Text(
                        "الصف: $schoolClass",
                        style: pw.TextStyle(font: ttf),
                      ),
                      pw.Text(
                        "رقم ولي الأمر: $guardianId",
                        style: pw.TextStyle(font: ttf),
                      ),
                      pw.Text(
                        "رقم الهاتف: $phone",
                        style: pw.TextStyle(font: ttf),
                      ),
                      pw.SizedBox(height: 20),

                      // رمز QR
                      pw.Text("رمز QR:", style: pw.TextStyle(font: ttf)),
                      pw.BarcodeWidget(
                        barcode: pw.Barcode.qrCode(),
                        data: _qrData!,
                        width: 100,
                        height: 100,
                      ),
                    ],
                  ),
                ),
              ),
            ),
      ),
    );

    // حفظ الملف مؤقتًا
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/student_card.pdf');
    await file.writeAsBytes(await pdf.save());

    // إعداد رسالة البريد الإلكتروني
    final message =
        Message()
          ..from = Address('8ffaay01@gmail.com', 'Student App')
          ..recipients.add(email)
          ..subject = 'بطاقة الطالب الخاصة بك'
          ..html = '''
        <html dir="rtl">
          <body>
            <p>مرحبًا $name،</p>
            <p>مرفقة بطاقة الطالب الخاصة بك.</p>
            <p>رقم هاتفك: $phone</p>
            <p>تحياتنا،</p>
            <p>فريق التطبيق</p>
          </body>
        </html>
      '''
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

  // عرض رسالة تنبيه
  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة طالب', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF4CAF50),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // حقل اسم الطالب
              _buildTextField(_nameController, "اسم الطالب", Icons.person),
              const SizedBox(height: 10),

              // حقل رقم الهوية
              _buildTextField(
                _idController,
                "رقم الهوية",
                Icons.credit_card,
                isNumber: true,
              ),
              const SizedBox(height: 10),

              // قائمة اختيار المرحلة الدراسية
              _buildDropdown(),
              const SizedBox(height: 10),

              // قائمة اختيار الصف الدراسي
              _buildClassSelector(),
              const SizedBox(height: 10),

              // حقل رقم ولي الأمر
              _buildTextField(
                _guardianIdController,
                "رقم ولي الأمر",
                Icons.person_outline,
                isNumber: true,
              ),
              const SizedBox(height: 10),

              // حقل رقم الهاتف
              _buildTextField(
                _phoneController,
                "رقم الهاتف",
                Icons.phone,
                isNumber: true,
              ),
              const SizedBox(height: 20),

              // زر إنشاء بطاقة الطالب
              ElevatedButton(
                onPressed: _generateQR,
                child: const Text(
                  'إنشاء بطاقة الطالب',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _buttonColor,
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 30,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // دالة لإنشاء حقل نصي
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
        labelStyle: TextStyle(color: _textColor), // لون النص الأسود
        border: OutlineInputBorder(),
        prefixIcon: Icon(icon, color: _iconColor), // أيقونة باللون الأزرق
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: _iconColor), // حدود عند التركيز
        ),
        filled: true,
        fillColor: _textFieldFillColor, // خلفية الحقل (رمادي فاتح)
      ),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: TextStyle(
        color: _textColor, // لون النص الأساسي داخل الحقل (أسود)
      ),
    );
  }

  // دالة لإنشاء قائمة اختيار المرحلة الدراسية
  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'المرحلة الدراسية',
        labelStyle: TextStyle(color: _textColor), // لون النص الأسود
        border: OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: _iconColor), // حدود عند التركيز
        ),
      ),
      value: _selectedStage,
      items:
          _stages
              .map(
                (stage) => DropdownMenuItem(value: stage, child: Text(stage)),
              )
              .toList(),
      onChanged: (value) {
        setState(() {
          _selectedStage = value;
          _selectedClass = null; // إعادة تعيين الصف عند تغيير المرحلة
        });
      },
    );
  }

  // دالة لإنشاء قائمة اختيار الصف الدراسي
  Widget _buildClassSelector() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'اختر الصف',
        labelStyle: TextStyle(color: _textColor), // لون النص الأسود
        border: OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: _iconColor), // حدود عند التركيز
        ),
      ),
      value: _selectedClass,
      items:
          _classes
              .map(
                (className) =>
                    DropdownMenuItem(value: className, child: Text(className)),
              )
              .toList(),
      onChanged: (value) {
        setState(() {
          _selectedClass = value;
        });
      },
    );
  }
}
