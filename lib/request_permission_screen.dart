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
                icon: Icons.edit,
              ),
              CustomLabel(text: 'التاريخ'),
              InkWell(
                onTap: () async {
                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
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
                  final TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (pickedTime != null) {
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
                        final stage = "ثالث ثانوي";
                        final schoolClass = "3";
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
                  color: Colors.black,
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
  final IconData? icon;

  CustomTextField({
    required this.controller,
    required this.hintText,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: TextField(
        controller: controller,
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: icon != null ? Icon(icon, color: Colors.indigo) : null,
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
  final Color color;

  const CustomButtonAuth({
    super.key,
    this.onPressed,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      height: 50,
      minWidth: 200,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      color: color,
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
