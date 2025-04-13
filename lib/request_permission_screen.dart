import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_time_picker_spinner/flutter_time_picker_spinner.dart'; // العجلة

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

              CustomLabel(text: 'التاريخ/اليوم'),
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
                    icon: Icons.calendar_today, // ✅ أضف هذا السطر
                  ),
                ),
              ),
              CustomLabel(text: 'الوقت'),
              const SizedBox(height: 10),
              Center(
                child: TimePickerSpinner(
                  is24HourMode: false,
                  normalTextStyle: TextStyle(fontSize: 18, color: Colors.grey),
                  highlightedTextStyle: TextStyle(
                    fontSize: 22,
                    color: Colors.black,
                  ),
                  spacing: 40,
                  itemHeight: 60,
                  isForce2Digits: true,
                  onTimeChange: (time) {
                    setState(() {
                      selectedTime = TimeOfDay(
                        hour: time.hour,
                        minute: time.minute,
                      );
                    });
                  },
                ),
              ),
              if (selectedTime != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      "الوقت المختار: ${_formatTime(selectedTime!)}",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              CustomLabel(text: 'إرفاق الملف'),
              InkWell(
                onTap: () async {
                  FilePickerResult? result = await FilePicker.platform
                      .pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['pdf'],
                      );

                  if (result != null) {
                    setState(() {
                      pickedFile = result.files.first;
                    });
                  }
                },
                child: AbsorbPointer(
                  child: CustomTextField(
                    controller: TextEditingController(
                      text: pickedFile?.name ?? '',
                    ),
                    hintText: 'اضغط لاختيار ملف PDF',
                    icon: Icons.picture_as_pdf, // ✅ أضف الأيقونة هنا
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
                        final storageRef = FirebaseStorage.instance.ref().child(
                          'excuses/${pickedFile!.name}',
                        );
                        final uploadTask = storageRef.putData(
                          pickedFile!.bytes!,
                        );
                        final snapshot = await uploadTask.whenComplete(() {});
                        final fileUrl = await snapshot.ref.getDownloadURL();

                        await FirebaseFirestore.instance.collection('excuses').add({
                          'studentId': widget.studentId,
                          'studentName': widget.studentName,
                          'reason': reasonController.text,
                          'date':
                              selectedDate != null
                                  ? "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}"
                                  : '',
                          'time':
                              selectedTime != null
                                  ? "${_formatTime(selectedTime!)}"
                                  : '',
                          'fileUrl': fileUrl,
                          'timestamp': DateTime.now(),
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('تم إرسال الطلب بنجاح')),
                        );

                        _clearFields();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('حدث خطأ أثناء الإرسال: $e')),
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
        selectedTime == null ||
        pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('يرجى ملء جميع الحقول واختيار ملف PDF')),
      );
      return false;
    }
    if (pickedFile!.extension?.toLowerCase() != 'pdf') {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('يرجى اختيار ملف من نوع PDF')));
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
    });
  }
}

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;

  CustomTextField({
    required this.controller,
    required this.hintText,
    required IconData icon,
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

  const CustomButtonAuth({
    super.key,
    this.onPressed,
    required this.title,
    required Color color,
  });

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
