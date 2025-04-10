import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseServices {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> getAdminSettings(String serviceCenterId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('admin_settings')
          .doc(serviceCenterId)
          .get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
    } catch (e) {
      print("Error fetching admin settings: $e");
    }
    return null;
  }
}
