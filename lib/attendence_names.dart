import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendenceNames extends StatelessWidget {
  final String stage;
  final int classNumber;

  AttendenceNames({required this.stage, required this.classNumber});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        centerTitle: true,
        title: Text(
          "فصل $stage/$classNumber",
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('students')
                        .where('stage', isEqualTo: stage)
                        .where('schoolClass', isEqualTo: '$classNumber')
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text("لا يوجد طلاب في هذا الفصل"));
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final student =
                          snapshot.data!.docs[index].data()
                              as Map<String, dynamic>;
                      final name = student['name'];
                      final studentId = student['id']; // معرف الطالب

                      // جلب حالة الحضور من Firestore باستخدام StreamBuilder
                      return StreamBuilder<DocumentSnapshot>(
                        stream:
                            FirebaseFirestore.instance
                                .collection('attendance')
                                .doc(studentId)
                                .snapshots(),
                        builder: (context, attendanceSnapshot) {
                          String status = "غير معروف";
                          if (attendanceSnapshot.hasData &&
                              attendanceSnapshot.data!.exists) {
                            status =
                                attendanceSnapshot.data!['status'] ??
                                "غير معروف";
                          }

                          Color statusColor;
                          switch (status) {
                            case 'حضور':
                              statusColor = Colors.green;
                              break;
                            case 'غياب':
                              statusColor = Colors.red;
                              break;
                            case 'تأخير':
                              statusColor = Colors.orange;
                              break;
                            default:
                              statusColor = Colors.grey;
                          }

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            textDirection: TextDirection.rtl,
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: TextStyle(fontSize: 18),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              SizedBox(width: 10),
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: () async {
                                  // عرض قائمة الخيارات لتعديل حالة الحضور
                                  final newStatus = await showDialog<String>(
                                    context: context,
                                    builder:
                                        (context) => SimpleDialog(
                                          title: Text("اختر الحالة الجديدة"),
                                          children: [
                                            SimpleDialogOption(
                                              child: Text("حضور"),
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    "حضور",
                                                  ),
                                            ),
                                            SimpleDialogOption(
                                              child: Text("غياب"),
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    "غياب",
                                                  ),
                                            ),
                                            SimpleDialogOption(
                                              child: Text("تأخير"),
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    "تأخير",
                                                  ),
                                            ),
                                          ],
                                        ),
                                  );

                                  // تحديث الحالة في Firestore إذا تم اختيار حالة جديدة
                                  if (newStatus != null) {
                                    await FirebaseFirestore.instance
                                        .collection('attendance')
                                        .doc(studentId)
                                        .set({'status': newStatus});
                                  }
                                },
                                child: Text("تعديل"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color.fromARGB(
                                    255,
                                    1,
                                    113,
                                    189,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
