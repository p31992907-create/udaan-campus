import 'package:cloud_firestore/cloud_firestore.dart';

class StudentQrModel {
  final String studentId;
  final String? qrToken;
  final int qrVersion;
  final bool qrActive;
  final DateTime? qrCreatedAt;
  final DateTime? qrUpdatedAt;
  final String? qrRegeneratedBy;

  StudentQrModel({
    required this.studentId,
    this.qrToken,
    required this.qrVersion,
    required this.qrActive,
    this.qrCreatedAt,
    this.qrUpdatedAt,
    this.qrRegeneratedBy,
  });

  factory StudentQrModel.fromJson(Map<String, dynamic> json) {
    return StudentQrModel(
      studentId: json['studentId'] ?? '',
      qrToken: json['qrToken'] as String?,
      qrVersion: json['qrVersion'] is int
          ? json['qrVersion'] as int
          : int.tryParse(json['qrVersion']?.toString() ?? '') ?? 0,
      qrActive: json['active'] is bool ? json['active'] as bool : false,
      qrCreatedAt: json['createdAt'] is Timestamp ? (json['createdAt'] as Timestamp).toDate() : null,
      qrUpdatedAt: json['updatedAt'] is Timestamp ? (json['updatedAt'] as Timestamp).toDate() : null,
      qrRegeneratedBy: json['updatedBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'qrToken': qrToken,
      'qrVersion': qrVersion,
      'active': qrActive,
      'createdAt': qrCreatedAt != null ? Timestamp.fromDate(qrCreatedAt!) : null,
      'updatedAt': qrUpdatedAt != null ? Timestamp.fromDate(qrUpdatedAt!) : null,
      'updatedBy': qrRegeneratedBy,
    };
  }
}
