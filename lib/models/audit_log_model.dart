import 'package:cloud_firestore/cloud_firestore.dart';

class AuditLogModel {
  final String auditId;
  final String action;
  final String targetType;
  final String targetId;
  final String performedBy;
  final String performedByRole;
  final Map<String, dynamic>? oldValue;
  final Map<String, dynamic>? newValue;
  final DateTime timestamp;

  AuditLogModel({
    required this.auditId,
    required this.action,
    required this.targetType,
    required this.targetId,
    required this.performedBy,
    required this.performedByRole,
    this.oldValue,
    this.newValue,
    required this.timestamp,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      auditId: json['auditId'] ?? '',
      action: json['action'] ?? '',
      targetType: json['targetType'] ?? '',
      targetId: json['targetId'] ?? '',
      performedBy: json['performedBy'] ?? '',
      performedByRole: json['performedByRole'] ?? '',
      oldValue: json['oldValue'] != null
          ? Map<String, dynamic>.from(json['oldValue'] as Map)
          : null,
      newValue: json['newValue'] != null
          ? Map<String, dynamic>.from(json['newValue'] as Map)
          : null,
      timestamp: (json['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'auditId': auditId,
      'action': action,
      'targetType': targetType,
      'targetId': targetId,
      'performedBy': performedBy,
      'performedByRole': performedByRole,
      'oldValue': oldValue,
      'newValue': newValue,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
