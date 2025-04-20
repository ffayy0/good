import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // استيراد مكتبة intl

class RequestsListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'طلبات النداء',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        centerTitle: true,
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
            return Center(child: Text('خطأ: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('لا توجد طلبات حالياً.'));
          }

          final requests = snapshot.data!.docs;

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index].data() as Map<String, dynamic>;
              final studentName = request['studentName'];
              final studentId = request['studentId'];
              final timestamp = request['timestamp'] as Timestamp;
              final status = request['status'];
              final location = request['location'];

              // تنسيق التاريخ والوقت باستخدام DateFormat
              final formattedDate = DateFormat(
                'yyyy-MM-dd hh:mm a',
              ).format(timestamp.toDate());

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(
                    studentName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('معرف الطالب: $studentId'),
                      Text('التاريخ: $formattedDate'),
                      Text('الحالة: $status'),
                      Text('الموقع: $location'),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      // حذف الطلب من Firestore
                      FirebaseFirestore.instance
                          .collection('pikup_call')
                          .doc(requests[index].id)
                          .delete();
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // يمكنك إضافة زر لتصفية الطلبات أو تحديث القائمة
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
