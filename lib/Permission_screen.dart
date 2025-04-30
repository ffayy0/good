import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mut6/exit_permits_screen.dart'
    show RequestDetailsScreen; // تأكد من المسار الصحيح

class PermissionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text(
          "طلبات الاستئذان",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('exitPermits')
                  .where(
                    'status',
                    isNull: true,
                  ) // عرض الطلبات التي لا تحتوي على الحقل status أو تحتوي على null
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError || !snapshot.hasData) {
              return const Center(child: Text("حدث خطأ أثناء جلب البيانات"));
            } else {
              final requests = snapshot.data!.docs;
              if (requests.isEmpty) {
                return const Center(child: Text("لا توجد طلبات استئذان"));
              }
              return ListView.builder(
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final request = requests[index];
                  final data = request.data() as Map<String, dynamic>;

                  final studentName = data['studentName'] ?? 'غير محدد';
                  final grade = data['grade'] ?? 'غير محدد';
                  final schoolId = data['schoolId'] ?? 'غير محدد';
                  final stage =
                      grade != 'غير محدد'
                          ? grade.toString().split('/').first
                          : '';
                  final schoolClass =
                      grade != 'غير محدد'
                          ? grade.toString().split('/').last
                          : '';

                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => RequestDetailsScreen(
                                request: request,
                                studentName: studentName,
                                grade: grade,
                                stage: stage,
                                schoolClass: schoolClass,
                                schoolId: schoolId,
                              ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        studentName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}
