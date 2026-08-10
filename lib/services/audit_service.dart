import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:udaan_campus/models/audit_log_model.dart';

class AuditService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get auditLogs =>
      _firestore.collection('audit_logs');

  Future<void> createAuditLog(AuditLogModel auditLog) async {
    await auditLogs.doc(auditLog.auditId).set(auditLog.toJson());
  }

  String buildAuditId(String targetType, String targetId, DateTime timestamp) {
    final key = timestamp.toUtc().millisecondsSinceEpoch;
    return '${targetType}_${targetId}_$key';
  }
}
