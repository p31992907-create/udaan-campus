import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:udaan_campus/models/homework_model.dart';

class HomeworkSubmissionModel {
  final String submissionId;
  final String homeworkId;
  final String studentId;
  final String studentName;
  final String classId;
  final String section;
  final DateTime submittedAt;
  final String? textResponse;
  final List<HomeworkAttachment> attachments;
  final String status;
  final String? teacherRemark;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final bool parentVisibleFeedback;
  final DateTime createdAt;
  final DateTime updatedAt;

  HomeworkSubmissionModel({
    required this.submissionId,
    required this.homeworkId,
    required this.studentId,
    required this.studentName,
    required this.classId,
    required this.section,
    required this.submittedAt,
    this.textResponse,
    required this.attachments,
    required this.status,
    this.teacherRemark,
    this.reviewedBy,
    this.reviewedAt,
    this.parentVisibleFeedback = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HomeworkSubmissionModel.fromJson(Map<String, dynamic> json) {
    final attachments = json['attachments'] != null
        ? List<Map<String, dynamic>>.from(json['attachments'] as List<dynamic>)
            .map((item) => HomeworkAttachment.fromJson(item))
            .toList()
        : <HomeworkAttachment>[];

    return HomeworkSubmissionModel(
      submissionId: json['submissionId'] ?? '',
      homeworkId: json['homeworkId'] ?? '',
      studentId: json['studentId'] ?? '',
      studentName: json['studentName'] ?? '',
      classId: json['classId'] ?? '',
      section: json['section'] ?? '',
      submittedAt: json['submittedAt'] != null
          ? (json['submittedAt'] as Timestamp).toDate()
          : DateTime.now(),
      textResponse: json['textResponse'] as String?,
      attachments: attachments,
      status: json['status'] ?? 'SUBMITTED',
      teacherRemark: json['teacherRemark'] as String?,
      reviewedBy: json['reviewedBy'] as String?,
      reviewedAt: json['reviewedAt'] != null
          ? (json['reviewedAt'] as Timestamp).toDate()
          : null,
      parentVisibleFeedback: json['parentVisibleFeedback'] != null
          ? json['parentVisibleFeedback'] as bool
          : true,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'submissionId': submissionId,
      'homeworkId': homeworkId,
      'studentId': studentId,
      'studentName': studentName,
      'classId': classId,
      'section': section,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'textResponse': textResponse,
      'attachments': attachments.map((attachment) => attachment.toJson()).toList(),
      'status': status,
      'teacherRemark': teacherRemark,
      'reviewedBy': reviewedBy,
      if (reviewedAt != null) 'reviewedAt': Timestamp.fromDate(reviewedAt!),
      'parentVisibleFeedback': parentVisibleFeedback,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  HomeworkSubmissionModel copyWith({
    String? submissionId,
    String? homeworkId,
    String? studentId,
    String? studentName,
    String? classId,
    String? section,
    DateTime? submittedAt,
    String? textResponse,
    List<HomeworkAttachment>? attachments,
    String? status,
    String? teacherRemark,
    String? reviewedBy,
    DateTime? reviewedAt,
    bool? parentVisibleFeedback,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HomeworkSubmissionModel(
      submissionId: submissionId ?? this.submissionId,
      homeworkId: homeworkId ?? this.homeworkId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      classId: classId ?? this.classId,
      section: section ?? this.section,
      submittedAt: submittedAt ?? this.submittedAt,
      textResponse: textResponse ?? this.textResponse,
      attachments: attachments ?? this.attachments,
      status: status ?? this.status,
      teacherRemark: teacherRemark ?? this.teacherRemark,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      parentVisibleFeedback: parentVisibleFeedback ?? this.parentVisibleFeedback,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
