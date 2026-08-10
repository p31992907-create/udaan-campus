import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:udaan_campus/models/calling_log_model.dart';

class CallingLogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get callingLogs => _firestore.collection('calling_logs');

  Future<void> saveCallingLog(CallingLogModel log) async {
    await callingLogs.doc(log.callId).set(log.toJson(), SetOptions(merge: true));
  }

  Future<List<CallingLogModel>> getCallLogsForStudent(String studentId) async {
    final query = await callingLogs
        .where('studentId', isEqualTo: studentId)
        .orderBy('createdAt', descending: true)
        .get();

    return query.docs.map((doc) => CallingLogModel.fromJson(doc.data())).toList();
  }
}
