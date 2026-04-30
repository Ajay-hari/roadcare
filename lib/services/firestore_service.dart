import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> saveUser(String uid, Map<String, dynamic> data) async {
    await _db.collection("users").doc(uid).set(data);
  }

  Future<void> saveProvider(String uid, Map<String, dynamic> data) async {
    await _db.collection("providers").doc(uid).set(data);
  }

  Future<void> createRequest(Map<String, dynamic> data) async {
    await _db.collection("requests").add(data);
  }

  Stream<QuerySnapshot> getUserRequests(String uid) {
    return _db.collection("requests").where("userId", isEqualTo: uid).snapshots();
  }

  Stream<QuerySnapshot> getProviderRequests() {
    return _db.collection("requests").where("status", isEqualTo: "pending").snapshots();
  }
}
