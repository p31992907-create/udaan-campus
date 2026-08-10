import 'package:cloud_firestore/cloud_firestore.dart';

class CallingLogModel {
  final String callId;
  final String studentId;
  final String studentName;
  final String classId;
  final String className;
  final String section;
  final DateTime attendanceDate;
  final String parentPhone;
  final String? parentName;
  final String calledByUid;
  final String calledByName;
  final String calledByRole;
  final String callOutcome;
  final String? responseNotes;
  final bool followUpRequired;
  final String? followUpNotes;
  final DateTime? followUpDate;
  final String? voiceNoteUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  CallingLogModel({
    required this.callId,
    required this.studentId,
    required this.studentName,
    required this.classId,
    required this.className,
    required this.section,
    required this.attendanceDate,
    required this.parentPhone,
    this.parentName,
    required this.calledByUid,
    required this.calledByName,
    required this.calledByRole,
    required this.callOutcome,
    this.responseNotes,
    required this.followUpRequired,
    this.followUpNotes,
    this.followUpDate,
    this.voiceNoteUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CallingLogModel.fromJson(Map<String, dynamic> json) {
    return CallingLogModel(
      callId: json['callId'] ?? '',
      studentId: json['studentId'] ?? '',
      studentName: json['studentName'] ?? '',
      classId: json['classId'] ?? '',
      className: json['className'] ?? '',
      section: json['section'] ?? '',
      attendanceDate: (json['attendanceDate'] as Timestamp).toDate(),
      parentPhone: json['parentPhone'] ?? '',
      parentName: json['parentName'] as String?,
      calledByUid: json['calledByUid'] ?? '',
      calledByName: json['calledByName'] ?? '',
      calledByRole: json['calledByRole'] ?? '',
      callOutcome: json['callOutcome'] ?? 'unknown',
      responseNotes: json['responseNotes'] as String?,
      followUpRequired: json['followUpRequired'] as bool? ?? false,
      followUpNotes: json['followUpNotes'] as String?,
      followUpDate: json['followUpDate'] != null ? (json['followUpDate'] as Timestamp).toDate() : null,
      voiceNoteUrl: json['voiceNoteUrl'] as String?,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'callId': callId,
      'studentId': studentId,
      'studentName': studentName,
      'classId': classId,
      'className': className,
      'section': section,
      'attendanceDate': Timestamp.fromDate(attendanceDate),
      'parentPhone': parentPhone,
      'parentName': parentName,
      'calledByUid': calledByUid,
      'calledByName': calledByName,
      'calledByRole': calledByRole,
      'callOutcome': callOutcome,
      'responseNotes': responseNotes,
      'followUpRequired': followUpRequired,
      'followUpNotes': followUpNotes,
      'followUpDate': followUpDate != null ? Timestamp.fromDate(followUpDate!) : null,
      'voiceNoteUrl': voiceNoteUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static String buildCallId(String studentId, DateTime timestamp) {
    return '${studentId}_${timestamp.millisecondsSinceEpoch}';
  }
}
