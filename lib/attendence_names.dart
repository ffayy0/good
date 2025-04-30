import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // لإظهار التاريخ بشكل مرتب

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
                      final studentId = student['id'];

                      return StreamBuilder<DocumentSnapshot>(
                        stream:
                            FirebaseFirestore.instance
                                .collection('attendance')
                                .doc(studentId)
                                .snapshots(),
                        builder: (context, attendanceSnapshot) {
                          String status = "غير معروف";
                          String stage = "";
                          String schoolClass = "";
                          String formattedTime = "غير محدد";

                          if (attendanceSnapshot.hasData &&
                              attendanceSnapshot.data!.exists) {
                            final data =
                                attendanceSnapshot.data!.data()
                                    as Map<String, dynamic>;
                            status = data['status'] ?? "غير معروف";
                            stage = data['stage'] ?? "";
                            schoolClass = data['schoolClass'] ?? "";
                            final timestamp = data['timestamp'] as Timestamp?;
                            if (timestamp != null) {
                              final dateTime = timestamp.toDate();
                              formattedTime = DateFormat(
                                'yyyy-MM-dd HH:mm',
                              ).format(dateTime);
                            }
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

                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              contentPadding: EdgeInsets.all(12),
                              title: Text(
                                name,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.right,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text("المرحلة: $stage"),
                                  Text("الصف: $schoolClass"),
                                  Text("وقت التسجيل: $formattedTime"),
                                ],
                              ),
                              trailing: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              onTap: () async {
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

                                if (newStatus != null) {
                                  await FirebaseFirestore.instance
                                      .collection('attendance')
                                      .doc(studentId)
                                      .set({
                                        'status': newStatus,
                                      }, SetOptions(merge: true));
                                }
                              },
                            ),
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
