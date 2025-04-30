import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ✅ مضاف
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

  final List<String> _stages = [
    'أولى ابتدائي',
    'ثاني ابتدائي',
    'ثالث ابتدائي',
    'رابع ابتدائي',
    'خامس ابتدائي',
    'سادس ابتدائي',
  ];
  final List<String> _classes = ['1', '2', '3', '4', '5', '6'];

  String? _selectedStage;
  String? _selectedClass;
  String? _qrData;
  String? _schoolId; // ✅ مضاف

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Color _iconColor = const Color(0xFF007AFF);
  final Color _buttonColor = const Color(0xFF007AFF);
  final Color _textFieldFillColor = Colors.grey[200]!;
  final Color _textColor = Colors.black;

  @override
  void initState() {
    super.initState();
    _loadSchoolId(); // ✅ تحميل schoolId من SharedPreferences
  }

  Future<void> _loadSchoolId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _schoolId = prefs.getString('schoolId');
    });
  }

  Future<void> _generateQR() async {
    String name = _nameController.text.trim();
    String id = _idController.text.trim();
    String guardianId = _guardianIdController.text.trim();
    String phone = _phoneController.text.trim();

    if (name.split(' ').length < 3) {
      _showSnackBar('الاسم يجب أن يتكون من ثلاثة أجزاء على الأقل');
      return;
    }
    if (!RegExp(r'^\d{10}$').hasMatch(id)) {
      _showSnackBar('رقم الهوية يجب أن يتكون من ١٠ أرقام فقط');
      return;
    }
    if (phone.length != 10) {
      _showSnackBar('رقم الجوال يجب أن يكون 10 أرقام');
      return;
    }
    if ([_selectedStage, _selectedClass].contains(null)) {
      _showSnackBar('رجاءً عَبِّ البيانات كاملة');
      return;
    }

    if (_schoolId == null) {
      _showSnackBar('لا يمكن إضافة الطالب: لم يتم العثور على معرف المدرسة');
      return;
    }

    bool isDuplicate = await _isStudentDuplicate(id);
    if (isDuplicate) {
      _showSnackBar('هذا الطالب مسجل مسبقًا');
      return;
    }

    String? emailFromDb = await _getGuardianEmail(guardianId);
    if (emailFromDb == null) {
      _showSnackBar('لا يوجد حساب لولي الأمر');
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
        'phone': phone,
        'schoolId': _schoolId, // ✅ استخدام SharedPreferences هنا
      });

      _qrData =
          'Name: $name\nID: $id\nStage: $_selectedStage\nClass: $_selectedClass\nGuardian ID: $guardianId\nPhone: $phone';

      await _sendStudentCardEmail(
        emailFromDb,
        name,
        id,
        _selectedStage!,
        _selectedClass!,
        guardianId,
        phone,
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
                guardianPhone: phone,
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
    String phone,
  ) async {
    final smtpServer = gmail('8ffaay01@gmail.com', 'vljn jaxv hukr qbct');
    final pdf = pw.Document();

    final customFont = await rootBundle.load(
      "assets/fonts/Cairo-VariableFont_slnt,wght.ttf",
    );
    final ttf = pw.Font.ttf(customFont.buffer.asByteData());

    final logoData = await rootBundle.load('assets/images/logo.png');
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

    pdf.addPage(
      pw.Page(
        build:
            (context) => pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Center(
                child: pw.Container(
                  decoration: pw.BoxDecoration(
                    borderRadius: pw.BorderRadius.circular(16),
                    color: PdfColor.fromInt(0xFFFFFFFF),
                    border: pw.Border.all(
                      color: PdfColor.fromInt(0xFF0171BD),
                      width: 2,
                    ),
                  ),
                  padding: pw.EdgeInsets.all(20),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Center(
                        child: pw.Image(logoImage, width: 100, height: 50),
                      ),
                      pw.SizedBox(height: 16),
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
                        "رقم هوية ولي الأمر: $guardianId",
                        style: pw.TextStyle(font: ttf),
                      ),
                      pw.Text(
                        "رقم الهاتف: $phone",
                        style: pw.TextStyle(font: ttf),
                      ),
                      pw.SizedBox(height: 20),
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

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/student_card.pdf');
    await file.writeAsBytes(await pdf.save());

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

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    if (_schoolId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
              _buildTextField(_nameController, "اسم الطالب", Icons.person),
              const SizedBox(height: 10),
              _buildTextField(
                _idController,
                "رقم الهوية",
                Icons.credit_card,
                isNumber: true,
              ),
              const SizedBox(height: 10),
              _buildDropdown(),
              const SizedBox(height: 10),
              _buildClassSelector(),
              const SizedBox(height: 10),
              _buildTextField(
                _guardianIdController,
                "رقم هوية ولي الأمر",
                Icons.person_outline,
                isNumber: true,
              ),
              const SizedBox(height: 10),
              _buildTextField(
                _phoneController,
                "رقم الهاتف",
                Icons.phone,
                isNumber: true,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _generateQR,
                child: const Text(
                  'اضافة الطالب',
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
        labelStyle: TextStyle(color: _textColor),
        border: OutlineInputBorder(),
        prefixIcon: Icon(icon, color: _iconColor),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: _iconColor),
        ),
        filled: true,
        fillColor: _textFieldFillColor,
      ),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: _textColor),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'المرحلة الدراسية',
        labelStyle: TextStyle(color: _textColor),
        border: OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: _iconColor),
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
          _selectedClass = null;
        });
      },
    );
  }

  Widget _buildClassSelector() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'اختر الصف',
        labelStyle: TextStyle(color: _textColor),
        border: OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: _iconColor),
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
