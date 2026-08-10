import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceModel {
  final String attendanceId;
  final String studentId;
  final String classId;
  final String className;
  final String section;
  final DateTime date;
  final String status;
  final String markedBy;
  final String markedByRole;
  final String method;
  final String? remarks;
  final DateTime timestamp;
  final DateTime createdAt;
  final DateTime updatedAt;

  AttendanceModel({
    required this.attendanceId,
    required this.studentId,
    required this.classId,
    required this.className,
    required this.section,
    required this.date,
    required this.status,
    required this.markedBy,
    required this.markedByRole,
    required this.method,
    this.remarks,
    required this.timestamp,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      attendanceId: json['attendanceId'] ?? '',
      studentId: json['studentId'] ?? '',
      classId: json['classId'] ?? '',
      className: json['className'] ?? '',
      section: json['section'] ?? '',
      date: (json['date'] as Timestamp).toDate(),
      status: json['status'] ?? 'present',
      markedBy: json['markedBy'] ?? '',
      markedByRole: json['markedByRole'] ?? '',
      method: json['method'] ?? 'manual',
      remarks: json['remarks'] as String?,
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'attendanceId': attendanceId,
      'studentId': studentId,
      'classId': classId,
      'className': className,
      'section': section,
      'date': Timestamp.fromDate(date),
      'status': status,
      'markedBy': markedBy,
      'markedByRole': markedByRole,
      'method': method,
      'remarks': remarks,
      'timestamp': Timestamp.fromDate(timestamp),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
