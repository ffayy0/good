import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:mut6/students_execuses.dart';

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
                      final className = student['schoolClass'] ?? "غير محدد";

                      return StreamBuilder<QuerySnapshot>(
                        stream:
                            FirebaseFirestore.instance
                                .collection('attendance')
                                .where('studentId', isEqualTo: studentId)
                                .orderBy('timestamp', descending: true)
                                .snapshots(),
                        builder: (context, attendanceSnapshot) {
                          if (!attendanceSnapshot.hasData ||
                              attendanceSnapshot.data!.docs.isEmpty) {
                            return const SizedBox();
                          }
                          return Column(
                            children:
                                attendanceSnapshot.data!.docs.map((doc) {
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                                  final status = data['status'] ?? "غير معروف";
                                  final timestamp =
                                      data['timestamp'] as Timestamp?;
                                  final formattedTime =
                                      timestamp != null
                                          ? DateFormat(
                                            'yyyy-MM-dd HH:mm',
                                            'en',
                                          ).format(timestamp.toDate())
                                          : "غير محدد";

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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text("المرحلة: $stage"),
                                          Text("الصف: $className"),
                                          Text("وقت التسجيل: $formattedTime"),
                                        ],
                                      ),
                                      trailing: GestureDetector(
                                        onTap: () async {
                                          final excuseSnapshot =
                                              await FirebaseFirestore.instance
                                                  .collection('student_excuses')
                                                  .where(
                                                    'studentId',
                                                    isEqualTo: studentId,
                                                  )
                                                  .where(
                                                    'date',
                                                    isEqualTo: DateFormat(
                                                      'yyyy-MM-dd',
                                                      'en', // نستخدم اللغة الإنجليزية هنا أيضًا
                                                    ).format(DateTime.now()),
                                                  )
                                                  .get();

                                          if (excuseSnapshot.docs.isNotEmpty) {
                                            final excuseData =
                                                excuseSnapshot.docs.first
                                                    .data();
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (
                                                      context,
                                                    ) => ExcuseDetailsScreen(
                                                      studentName: name,
                                                      reason:
                                                          excuseData['reason'],
                                                      date: excuseData['date'],
                                                      fileUrl:
                                                          excuseData['fileUrl'] ??
                                                          "",
                                                      className: className,
                                                    ),
                                              ),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  "لا يوجد عذر لهذا الطالب",
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                        child: Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: statusColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
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
