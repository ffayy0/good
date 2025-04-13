import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'dart:typed_data';

class FileUploadWidget extends StatefulWidget {
  final String title;
  final Function(String?, List<List<dynamic>>?) onConfirm;

  const FileUploadWidget({
    super.key,
    required this.title,
    required this.onConfirm,
  });

  @override
  _FileUploadWidgetState createState() => _FileUploadWidgetState();
}

class _FileUploadWidgetState extends State<FileUploadWidget> {
  String? selectedFileName;
  List<List<dynamic>>? fileData;

  // دالة لاختيار ملف Excel
  Future<void> pickFile() async {
    // تأكد من أن المستخدم يختار فقط ملفات .xlsx
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.single;

      if (file.bytes != null) {
        final Uint8List fileBytes = file.bytes!;

        setState(() {
          selectedFileName = file.name;
        });

        // محاولة معالجة الملف
        try {
          final excel = Excel.decodeBytes(fileBytes);
          List<List<dynamic>> rows = [];

          for (final sheetName in excel.tables.keys) {
            final sheet = excel.tables[sheetName];
            if (sheet != null) {
              for (var row in sheet.rows) {
                rows.add(row.map((cell) => cell?.value).toList());
              }
            }
          }

          if (rows.isEmpty) {
            print("❌ الملف فارغ أو لا يحتوي على بيانات.");
          } else {
            setState(() {
              fileData = rows;
            });
            print("تم تحميل الملف بنجاح");
          }
        } catch (e) {
          print("خطأ أثناء قراءة الملف: $e");
        }
      }
    } else {
      // في حال لم يتم اختيار أي ملف
      print("❌ لم يتم اختيار أي ملف");
    }
  }

  // تأكيد التحميل
  void confirmUpload(BuildContext context) {
    if (selectedFileName != null && fileData != null) {
      widget.onConfirm(selectedFileName, fileData);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("تم رفع الملف بنجاح: $selectedFileName")),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("يرجى اختيار ملف أولاً")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: pickFile,
          child: Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                selectedFileName ?? "اختر ملف Excel (.xlsx)",
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color.fromARGB(255, 1, 113, 189),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          onPressed: () => confirmUpload(context),
          child: const Text(
            "تأكيد",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
