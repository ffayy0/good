import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'students_execuses.dart';

class ClassAttendanceWithDate extends StatefulWidget {
  final String schoolId;

  const ClassAttendanceWithDate({super.key, required this.schoolId});

  @override
  State<ClassAttendanceWithDate> createState() =>
      _ClassAttendanceWithDateState();
}

class _ClassAttendanceWithDateState extends State<ClassAttendanceWithDate> {
  String? selectedStage;
  String? selectedClass;
  DateTime selectedDate = DateTime.now();
  List<String> stages = [];
  List<String> classes = [];
  List<Map<String, dynamic>> allStudents = [];
  Map<String, Map<String, dynamic>> attendanceMap = {};

  @override
  void initState() {
    super.initState();
    _loadStageAndClassOptions();
  }

  Future<void> _loadStageAndClassOptions() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('students')
            .where('schoolId', isEqualTo: widget.schoolId)
            .get();

    final stageSet = <String>{};
    final classSet = <String>{};
    for (var doc in snapshot.docs) {
      stageSet.add(doc['stage']);
      classSet.add(doc['schoolClass']);
    }

    setState(() {
      stages = stageSet.toList()..sort();
      classes = classSet.toList()..sort();
    });
  }

  Future<void> _loadStudentsAndAttendance() async {
    if (selectedStage == null || selectedClass == null) return;

    final studentSnapshot =
        await FirebaseFirestore.instance
            .collection('students')
            .where('schoolId', isEqualTo: widget.schoolId)
            .where('stage', isEqualTo: selectedStage)
            .where('schoolClass', isEqualTo: selectedClass)
            .get();

    final students = studentSnapshot.docs.map((doc) => doc.data()).toList();
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);

    final attendanceSnapshot =
        await FirebaseFirestore.instance
            .collection('attendance_records')
            .where('schoolId', isEqualTo: widget.schoolId)
            .where('stage', isEqualTo: selectedStage)
            .where('schoolClass', isEqualTo: selectedClass)
            .get();

    final Map<String, Map<String, dynamic>> tempMap = {};
    for (var doc in attendanceSnapshot.docs) {
      final data = doc.data();
      final ts = (data['timestamp'] as Timestamp?)?.toDate();
      if (ts == null) continue;
      final tsDate = DateFormat('yyyy-MM-dd').format(ts);
      if (tsDate == dateStr) {
        tempMap[data['studentId']] = {
          'status': data['status'],
          'time': DateFormat('HH:mm').format(ts),
        };
      }
    }

    setState(() {
      allStudents = students;
      attendanceMap = tempMap;
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedDateStr = DateFormat('yyyy-MM-dd').format(selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('حضور الطلاب', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // ✅ تقويم TableCalendar
                TableCalendar(
                  locale: 'ar_SA',
                  firstDay: DateTime(2023),
                  lastDay: DateTime.now(),
                  focusedDay: selectedDate,
                  calendarFormat: CalendarFormat.month,
                  selectedDayPredicate: (day) => isSameDay(selectedDate, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      selectedDate = selectedDay;
                    });
                    _loadStudentsAndAttendance();
                  },
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                  calendarStyle: const CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedStage,
                  decoration: const InputDecoration(labelText: 'اختر المرحلة'),
                  items:
                      stages
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedStage = val;
                      selectedClass = null;
                      allStudents.clear();
                      attendanceMap.clear();
                    });
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedClass,
                  decoration: const InputDecoration(labelText: 'اختر الصف'),
                  items:
                      classes
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text('صف $c'),
                            ),
                          )
                          .toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedClass = val;
                    });
                    _loadStudentsAndAttendance();
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child:
                allStudents.isEmpty
                    ? const Center(child: Text("اختر المرحلة والصف والتاريخ"))
                    : ListView.builder(
                      itemCount: allStudents.length,
                      itemBuilder: (context, index) {
                        final student = allStudents[index];
                        final record = attendanceMap[student['id']];
                        final status = record?['status'] ?? 'غياب';
                        final time = record?['time'];
                        Color color;
                        IconData icon;

                        switch (status) {
                          case 'حضور':
                            color = Colors.green;
                            icon = Icons.check_circle;
                            break;
                          case 'تأخير':
                            color = Colors.orange;
                            icon = Icons.access_time;
                            break;
                          default:
                            color = Colors.red;
                            icon = Icons.cancel;
                        }

                        return ListTile(
                          title: Text(student['name']),
                          subtitle: Text(
                            'الحالة: $status${time != null ? " - $time" : ""}',
                          ),
                          leading: GestureDetector(
                            onTap: () async {
                              final excuseSnapshot =
                                  await FirebaseFirestore.instance
                                      .collection('student_excuses')
                                      .where(
                                        'studentId',
                                        isEqualTo: student['id'],
                                      )
                                      .where('date', isEqualTo: selectedDateStr)
                                      .get();

                              if (excuseSnapshot.docs.isNotEmpty) {
                                final excuseData =
                                    excuseSnapshot.docs.first.data();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => ExcuseDetailsScreen(
                                          studentName: student['name'],
                                          reason: excuseData['reason'],
                                          date: excuseData['date'],
                                          fileUrl: excuseData['fileUrl'] ?? "",
                                          className:
                                              selectedClass ?? "غير محدد",
                                        ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("لا يوجد عذر لهذا الطالب"),
                                  ),
                                );
                              }
                            },
                            child: Icon(icon, color: color),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
