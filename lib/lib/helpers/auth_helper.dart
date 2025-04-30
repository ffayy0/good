import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

String currentUserSchoolId = '';
String currentUserRole = '';
String currentUserId = '';

Future<void> fetchAndSetCurrentUserSchoolIdByCustomId(String customId) async {
  try {
    print('🔍 بدء البحث عن المستخدم برقم الهوية: $customId');

    List<String> collectionsToCheck = [
      'admins',
      'teachers',
      'parents',
      'Authorizations',
    ];

    for (String collection in collectionsToCheck) {
      print('📂 البحث داخل الكولكشن: $collection');

      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance
              .collection(collection)
              .where('id', isEqualTo: customId)
              .limit(1)
              .get();

      print('📋 عدد النتائج في $collection: ${querySnapshot.docs.length}');

      if (querySnapshot.docs.isNotEmpty) {
        Map<String, dynamic> userData =
            querySnapshot.docs.first.data() as Map<String, dynamic>;

        currentUserSchoolId = userData['schoolId'] ?? '';

        currentUserRole = collection;

        currentUserId = customId;

        print('✅ تم العثور على المستخدم!');

        print('🏫 schoolId: $currentUserSchoolId');

        print('🧑‍💼 Role: $currentUserRole');

        print('🆔 User ID: $currentUserId');

        return;
      }
    }

    print('❌ لم يتم العثور على schoolId للمستخدم الحالي.');
  } catch (e) {
    print('❌ خطأ أثناء جلب schoolId: $e');
  }
}
