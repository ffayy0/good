import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// المتغيرات العامة
String currentUserSchoolId = '';
String currentUserRole = '';
String currentUserId = '';

// دالة تحميل schoolId والدور
Future<void> fetchAndSetCurrentUserSchoolIdByCustomId(String customId) async {
  try {
    List<String> collectionsToCheck = [
      'admins',
      'teachers',
      'parents',
      'Authorizations',
    ];

    for (String collection in collectionsToCheck) {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance
              .collection(collection)
              .where('id', isEqualTo: customId)
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        Map<String, dynamic> userData =
            querySnapshot.docs.first.data() as Map<String, dynamic>;
        currentUserSchoolId = userData['schoolId'] ?? '';
        currentUserRole = collection;
        currentUserId = customId; // تخزين رقم الهوية المستخدم
        print(
          '✅ School ID loaded: $currentUserSchoolId, Role: $currentUserRole',
        );
        return;
      }
    }

    print('❌ لم يتم العثور على schoolId للمستخدم الحالي.');
  } catch (e) {
    print('❌ خطأ أثناء جلب schoolId: $e');
  }
}
