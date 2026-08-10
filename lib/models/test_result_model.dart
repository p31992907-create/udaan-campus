import 'package:cloud_firestore/cloud_firestore.dart';

class TestResultModel {
  final String resultId;
  final String testId;
  final String testTitle;
  final String subject;
  final String studentId;
  final String studentName;
  final String classId;
  final String section;
  final double marksObtained;
  final int maxMarks;
  final String grade;
  final String? remarks;
  final DateTime createdAt;
  final String createdBy;

  TestResultModel({
    required this.resultId,
    required this.testId,
    required this.testTitle,
    required this.subject,
    required this.studentId,
    required this.studentName,
    required this.classId,
    required this.section,
    required this.marksObtained,
    required this.maxMarks,
    required this.grade,
    this.remarks,
    required this.createdAt,
    required this.createdBy,
  });

  factory TestResultModel.fromJson(Map<String, dynamic> json) {
    return TestResultModel(
      resultId: json['resultId'] ?? '',
      testId: json['testId'] ?? '',
      testTitle: json['testTitle'] ?? '',
      subject: json['subject'] ?? '',
      studentId: json['studentId'] ?? '',
      studentName: json['studentName'] ?? '',
      classId: json['classId'] ?? '',
      section: json['section'] ?? '',
      marksObtained: (json['marksObtained'] ?? 0).toDouble(),
      maxMarks: (json['maxMarks'] ?? 0) is int ? json['maxMarks'] as int : (json['maxMarks'] as num).toInt(),
      grade: json['grade'] ?? '',
      remarks: json['remarks'] is String ? json['remarks'] as String : null,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      createdBy: json['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'resultId': resultId,
      'testId': testId,
      'testTitle': testTitle,
      'subject': subject,
      'studentId': studentId,
      'studentName': studentName,
      'classId': classId,
      'section': section,
      'marksObtained': marksObtained,
      'maxMarks': maxMarks,
      'grade': grade,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
    };
    if (remarks != null) {
      data['remarks'] = remarks;
    }
    return data;
  }

  static String buildResultId(String testId, String studentId) {
    return '${testId}_$studentId';
  }
}
