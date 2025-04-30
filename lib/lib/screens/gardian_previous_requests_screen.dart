import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PreviousRequestsScreen extends StatefulWidget {
  @override
  _PreviousRequestsScreenState createState() => _PreviousRequestsScreenState();
}

class _PreviousRequestsScreenState extends State<PreviousRequestsScreen> {
  DateTime? fromDate; // تاريخ البداية
  DateTime? toDate; // تاريخ النهاية
  Stream<List<Map<String, dynamic>>>? _filteredStream; // التدفق المفلتر

  // دالة اختيار التاريخ
  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isFromDate) {
          fromDate = picked;
        } else {
          toDate = picked;
        }
      });
    }
  }

  // تطبيق الفلتر
  void _applyFilter() {
    if (fromDate == null || toDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("يرجى اختيار نطاق التاريخ كاملًا.")),
      );
      return;
    }
    setState(() {
      _filteredStream = _fetchFilteredRequests(fromDate!, toDate!);
    });
  }

  // جلب الطلبات المفلترة من Firestore
  Stream<List<Map<String, dynamic>>> _fetchFilteredRequests(
    DateTime fromDate,
    DateTime toDate,
  ) async* {
    // جلب الطلبات من الجدولين: exitpermits و pickup_call
    final exitPermitsSnapshot =
        await FirebaseFirestore.instance
            .collection('exitPermits')
            .where(
              'timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate),
            )
            .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(toDate))
            .get();

    final pickupCallsSnapshot =
        await FirebaseFirestore.instance
            .collection('pikup_call')
            .where(
              'timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate),
            )
            .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(toDate))
            .get();

    // تحويل البيانات إلى قائمة موحدة
    List<Map<String, dynamic>> allRequests = [];

    for (var doc in exitPermitsSnapshot.docs) {
      allRequests.add({
        'type': 'طلب استئذان',
        'studentName': doc['studentName'] ?? 'غير معروف',
        'grade': doc['grade'] ?? 'غير محدد',
        'status': doc['status'] ?? 'غير معروف',
        'timestamp':
            (doc['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      });
    }

    for (var doc in pickupCallsSnapshot.docs) {
      allRequests.add({
        'type': 'طلب نداء',
        'studentName': doc['studentName'] ?? 'غير معروف',
        'grade': 'غير محدد',
        'status': doc['status'] ?? 'غير معروف',
        'timestamp':
            (doc['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      });
    }

    // ترتيب الطلبات حسب التاريخ
    allRequests.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

    // إرجاع القائمة كتدفق
    yield allRequests;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        centerTitle: true,
        title: Text("الطلبات السابقة", style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // صف اختيار التاريخ
            Row(
              children: [
                Expanded(
                  child: _buildDateSelector(
                    "من",
                    fromDate,
                    () => _selectDate(context, true),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _buildDateSelector(
                    "إلى",
                    toDate,
                    () => _selectDate(context, false),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            // زر التصفية
            Align(
              alignment: Alignment.center,
              child: ElevatedButton.icon(
                onPressed: _applyFilter,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                icon: Icon(Icons.filter_alt, color: Colors.white),
                label: Text("تصفية", style: TextStyle(color: Colors.white)),
              ),
            ),
            SizedBox(height: 20),
            // قائمة الطلبات
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream:
                    _filteredStream ??
                    _fetchFilteredRequests(
                      DateTime(2000),
                      DateTime(2100),
                    ), // عرض جميع الطلبات افتراضيًا
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text("حدث خطأ: ${snapshot.error}"));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  final requests = snapshot.data!;
                  if (requests.isEmpty) {
                    return Center(child: Text("لا توجد طلبات."));
                  }
                  return ListView.builder(
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      final data = requests[index];
                      return _buildRequestTile(data);
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

  // ويدجت اختيار التاريخ
  Widget _buildDateSelector(String label, DateTime? date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          date != null ? DateFormat('yyyy-MM-dd').format(date) : label,
          style: TextStyle(fontSize: 16, color: Colors.black87),
        ),
      ),
    );
  }

  // ويدجت عرض الطلب
  Widget _buildRequestTile(Map<String, dynamic> data) {
    final studentName = data['studentName'];
    final grade = data['grade'];
    final status = data['status'];
    final timestamp = data['timestamp'];
    final formattedTimestamp = DateFormat(
      'yyyy-MM-dd – HH:mm',
    ).format(timestamp);

    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${data['type']}",
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text("الطالب: $studentName", style: TextStyle(fontSize: 15)),
            SizedBox(height: 4),
            Text("الصف: $grade", style: TextStyle(fontSize: 15)),
            SizedBox(height: 4),
            Text(
              "الحالة: $status",
              style: TextStyle(fontSize: 15, color: _getStatusColor(status)),
            ),
            SizedBox(height: 4),
            Text(
              "التاريخ: $formattedTimestamp",
              style: TextStyle(fontSize: 15, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  // تحديد لون الحالة بناءً على قيمتها
  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
