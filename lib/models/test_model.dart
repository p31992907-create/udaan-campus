import 'package:cloud_firestore/cloud_firestore.dart';

class TestModel {
  final String testId;
  final String title;
  final String subject;
  final String classId;
  final String section;
  final int maxMarks;
  final DateTime date;
  final String createdBy;
  final String teacherName;
  final DateTime createdAt;
  final bool isFinalExam;

  TestModel({
    required this.testId,
    required this.title,
    required this.subject,
    required this.classId,
    required this.section,
    required this.maxMarks,
    required this.date,
    required this.createdBy,
    required this.teacherName,
    required this.createdAt,
    this.isFinalExam = false,
  });

  factory TestModel.fromJson(Map<String, dynamic> json) {
    return TestModel(
      testId: json['testId'] ?? '',
      title: json['title'] ?? '',
      subject: json['subject'] ?? '',
      classId: json['classId'] ?? '',
      section: json['section'] ?? '',
      maxMarks: (json['maxMarks'] ?? 0) is int ? json['maxMarks'] as int : (json['maxMarks'] as num).toInt(),
      date: (json['date'] as Timestamp).toDate(),
      createdBy: json['createdBy'] ?? '',
      teacherName: json['teacherName'] ?? '',
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      isFinalExam: json['isFinalExam'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'testId': testId,
      'title': title,
      'subject': subject,
      'classId': classId,
      'section': section,
      'maxMarks': maxMarks,
      'date': Timestamp.fromDate(date),
      'createdBy': createdBy,
      'teacherName': teacherName,
      'createdAt': Timestamp.fromDate(createdAt),
      'isFinalExam': isFinalExam,
    };
  }
}
