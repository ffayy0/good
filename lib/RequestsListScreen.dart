import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CallScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('شاشة النداء'),
        backgroundColor: Colors.green,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('pikup_call')
                .orderBy('timestamp', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("خطأ: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("لا توجد طلبات حالية."));
          }

          final requests = snapshot.data!.docs;

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              final data = request.data() as Map<String, dynamic>;
              final studentName = data['studentName'];
              final studentId = data['studentId'];
              final timestamp = data['timestamp'] as Timestamp;
              final status = data['status'];

              // تنسيق التاريخ والوقت
              final formattedDate = DateFormat(
                'yyyy-MM-dd hh:mm a',
              ).format(timestamp.toDate());

              // تحديد اللون بناءً على الحالة
              Color statusColor;
              switch (status) {
                case 'جديد':
                  statusColor = Colors.green;
                  break;
                case 'منتهي':
                  statusColor = Colors.grey;
                  break;
                default:
                  statusColor = Colors.red; // حالة غير متوقعة
              }

              // التحقق من مرور 5 دقائق
              final currentTime = DateTime.now();
              final elapsedTime =
                  currentTime.difference(timestamp.toDate()).inMinutes;

              if (elapsedTime >= 5 && status == 'جديد') {
                // تحديث الحالة إلى "منتهي" إذا مر 5 دقائق
                FirebaseFirestore.instance
                    .collection('pikup_call')
                    .doc(request.id)
                    .update({'status': 'منتهي'});
              }

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(studentName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("معرف الطالب: $studentId"),
                      Text("التاريخ: $formattedDate"),
                      Text("الحالة: $status"),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // عرض اللون بناءً على الحالة
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'update') {
                            // تحديث الحالة إلى "منتهي"
                            await FirebaseFirestore.instance
                                .collection('pikup_call')
                                .doc(request.id)
                                .update({'status': 'منتهي'});
                          } else if (value == 'delete') {
                            // حذف الطلب
                            await FirebaseFirestore.instance
                                .collection('pikup_call')
                                .doc(request.id)
                                .delete();
                          }
                        },
                        itemBuilder:
                            (context) => [
                              const PopupMenuItem<String>(
                                value: 'update',
                                child: Text('تحديث الحالة إلى "منتهي"'),
                              ),
                              const PopupMenuItem<String>(
                                value: 'delete',
                                child: Text('حذف الطلب'),
                              ),
                            ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // تحديث القائمة يدويًا
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("جارٍ تحديث القائمة...")),
          );
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
