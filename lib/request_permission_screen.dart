import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';

class RequestPermissionScreen extends StatefulWidget {
  final String studentId;
  final String studentName;

  const RequestPermissionScreen({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  _RequestPermissionScreenState createState() =>
      _RequestPermissionScreenState();
}

class _RequestPermissionScreenState extends State<RequestPermissionScreen> {
  final TextEditingController reasonController = TextEditingController();
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  PlatformFile? pickedFile;
  String? uploadedFileUrl;

  Future<void> _pickAndUploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          pickedFile = result.files.first;
        });
        final storageRef = FirebaseStorage.instance.ref().child(
          'excuse_files/${pickedFile!.name}',
        );
        final uploadTask = storageRef.putData(pickedFile!.bytes!);
        final snapshot = await uploadTask.whenComplete(() {});
        final downloadUrl = await snapshot.ref.getDownloadURL();
        setState(() {
          uploadedFileUrl = downloadUrl;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء اختيار أو تحميل الملف: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text('طلب الاستئذان', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 50),
              CustomLabel(text: 'السبب'),
              CustomTextField(
                controller: reasonController,
                hintText: 'اكتب السبب هنا',
              ),
              CustomLabel(text: 'التاريخ'),
              InkWell(
                onTap: () async {
                  final now = DateTime.now();
                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: now,
                    firstDate: now, // يمنع اختيار تواريخ سابقة
                    lastDate: DateTime(2100),
                    builder: (BuildContext context, Widget? child) {
                      return Theme(
                        data: ThemeData.light().copyWith(
                          colorScheme: ColorScheme.light(
                            primary: const Color.fromARGB(255, 11, 40, 66),
                            onPrimary: const Color.fromARGB(255, 221, 227, 230),
                            surface: const Color.fromARGB(255, 230, 232, 234),
                            onSurface: Colors.black,
                          ),
                          dialogBackgroundColor: Colors.white,
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (pickedDate != null) {
                    setState(() {
                      selectedDate = pickedDate;
                    });
                  }
                },
                child: AbsorbPointer(
                  child: CustomTextField(
                    controller: TextEditingController(
                      text:
                          selectedDate != null
                              ? "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}"
                              : 'اختر التاريخ',
                    ),
                    hintText: 'اختر التاريخ',
                  ),
                ),
              ),
              CustomLabel(text: 'الوقت'),
              InkWell(
                onTap: () async {
                  final now = DateTime.now();
                  final TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                    builder: (BuildContext context, Widget? child) {
                      return Theme(
                        data: ThemeData.light().copyWith(
                          colorScheme: ColorScheme.light(
                            primary: const Color.fromARGB(255, 17, 34, 49),
                            onPrimary: const Color.fromARGB(255, 229, 232, 235),
                            surface: const Color.fromARGB(255, 232, 234, 236),
                            onSurface: Colors.black,
                          ),
                          dialogBackgroundColor: Colors.white,
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (pickedTime != null) {
                    // التحقق من أن الوقت المختار ليس قبل الوقت الحالي
                    final selectedDateTime = DateTime(
                      selectedDate?.year ?? now.year,
                      selectedDate?.month ?? now.month,
                      selectedDate?.day ?? now.day,
                      pickedTime.hour,
                      pickedTime.minute,
                    );
                    if (selectedDateTime.isBefore(now)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "لا يمكنك اختيار وقت قبل الوقت الحالي.",
                          ),
                        ),
                      );
                      return;
                    }
                    setState(() {
                      selectedTime = pickedTime;
                    });
                  }
                },
                child: AbsorbPointer(
                  child: CustomTextField(
                    controller: TextEditingController(
                      text:
                          selectedTime != null
                              ? _formatTime(selectedTime!)
                              : 'اختر الوقت',
                    ),
                    hintText: 'اختر الوقت',
                  ),
                ),
              ),
              if (selectedTime != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      "الوقت المختار: ${_formatTime(selectedTime!)}",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              CustomLabel(text: 'إرفاق ملف PDF (اختياري)'),
              InkWell(
                onTap: _pickAndUploadFile,
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      pickedFile != null
                          ? "ملف مرفوع: ${pickedFile!.name}"
                          : "اضغط لاختيار ملف PDF",
                      style: TextStyle(fontSize: 16, color: Colors.blue),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: CustomButtonAuth(
                  title: 'إرسال',
                  onPressed: () async {
                    if (_validateFields()) {
                      try {
                        final stage =
                            "ثالث ابتدائى"; // استبدل هذه القيمة بالقيمة الفعلية
                        final schoolClass =
                            "3"; // استبدل هذه القيمة بالقيمة الفعلية
                        final grade = "$stage/$schoolClass";
                        await FirebaseFirestore.instance.collection('excuses').add({
                          'studentId': widget.studentId,
                          'studentName': widget.studentName,
                          'schoolClass': schoolClass,
                          'reason': reasonController.text.trim(),
                          'date':
                              selectedDate != null
                                  ? "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}"
                                  : '',
                          'time':
                              selectedTime != null
                                  ? _formatTime(selectedTime!)
                                  : '',
                          'attachedFileUrl': uploadedFileUrl ?? '',
                          'timestamp': DateTime.now(),
                          'grade': grade,
                          'status': 'pending',
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("تم إرسال الطلب بنجاح!")),
                        );
                        _clearFields();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("حدث خطأ أثناء إرسال الطلب: $e"),
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  bool _validateFields() {
    if (reasonController.text.isEmpty ||
        selectedDate == null ||
        selectedTime == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('يرجى ملء جميع الحقول')));
      return false;
    }
    return true;
  }

  void _clearFields() {
    reasonController.clear();
    setState(() {
      selectedDate = null;
      selectedTime = null;
      pickedFile = null;
      uploadedFileUrl = null;
    });
  }
}

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;

  CustomTextField({required this.controller, required this.hintText});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: TextField(
        controller: controller,
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          hintText: hintText,
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
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
    return MaterialButton(
      height: 50,
      minWidth: 200,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      color: const Color.fromARGB(255, 1, 113, 189),
      textColor: Colors.white,
      onPressed: onPressed,
      child: Text(title, style: TextStyle(fontSize: 20)),
    );
  }
}

class CustomLabel extends StatelessWidget {
  final String text;

  CustomLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }
}
