import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get users => _db.collection('users');
  CollectionReference<Map<String, dynamic>> get students => _db.collection('students');
  CollectionReference<Map<String, dynamic>> get classes => _db.collection('classes');
  CollectionReference<Map<String, dynamic>> get attendance => _db.collection('attendance');
  CollectionReference<Map<String, dynamic>> get homework => _db.collection('homework');
  CollectionReference<Map<String, dynamic>> get tests => _db.collection('tests');
  CollectionReference<Map<String, dynamic>> get testResults => _db.collection('test_results');
  CollectionReference<Map<String, dynamic>> get callingLogs => _db.collection('calling_logs');
  CollectionReference<Map<String, dynamic>> get notifications => _db.collection('notifications');
  CollectionReference<Map<String, dynamic>> get auditLogs => _db.collection('audit_logs');

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamUserProfile(String uid) {
    return users.doc(uid).snapshots();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserProfile(String uid) {
    return users.doc(uid).get();
  }
}
