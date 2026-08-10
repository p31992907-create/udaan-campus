import 'package:cloud_firestore/cloud_firestore.dart';

class HomeworkAttachment {
  final String filePath;
  final String fileName;
  final String fileType;
  final int fileSize;
  final String fileUrl;

  HomeworkAttachment({
    required this.filePath,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    required this.fileUrl,
  });

  factory HomeworkAttachment.fromJson(Map<String, dynamic> json) {
    return HomeworkAttachment(
      filePath: json['filePath'] ?? '',
      fileName: json['fileName'] ?? '',
      fileType: json['fileType'] ?? '',
      fileSize: (json['fileSize'] ?? 0) is int ? json['fileSize'] as int : (json['fileSize'] as num).toInt(),
      fileUrl: json['fileUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'filePath': filePath,
      'fileName': fileName,
      'fileType': fileType,
      'fileSize': fileSize,
      'fileUrl': fileUrl,
    };
  }
}

class HomeworkModel {
  final String homeworkId;
  final String title;
  final String description;
  final String classId;
  final String className;
  final String section;
  final String subjectId;
  final String subjectName;
  final String teacherId;
  final String teacherName;
  final DateTime assignedDate;
  final DateTime dueDate;
  final String priority;
  final String status;
  final String homeworkType;
  final bool allowSubmission;
  final bool allowLateSubmission;
  final List<HomeworkAttachment> attachments;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? publishedAt;

  HomeworkModel({
    required this.homeworkId,
    required this.title,
    required this.description,
    required this.classId,
    required this.className,
    required this.section,
    required this.subjectId,
    required this.subjectName,
    required this.teacherId,
    required this.teacherName,
    required this.assignedDate,
    required this.dueDate,
    required this.priority,
    required this.status,
    required this.homeworkType,
    required this.allowSubmission,
    required this.allowLateSubmission,
    required this.attachments,
    required this.createdAt,
    required this.updatedAt,
    this.publishedAt,
  });

  factory HomeworkModel.fromJson(Map<String, dynamic> json) {
    final attachments = json['attachments'] != null
        ? List<Map<String, dynamic>>.from(json['attachments'] as List<dynamic>)
            .map((item) => HomeworkAttachment.fromJson(item))
            .toList()
        : <HomeworkAttachment>[];

    return HomeworkModel(
      homeworkId: json['homeworkId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      classId: json['classId'] ?? '',
      className: json['className'] ?? json['classId'] ?? '',
      section: json['section'] ?? '',
      subjectId: json['subjectId'] ?? '',
      subjectName: json['subjectName'] ?? '',
      teacherId: json['teacherId'] ?? '',
      teacherName: json['teacherName'] ?? '',
      assignedDate: (json['assignedDate'] as Timestamp).toDate(),
      dueDate: (json['dueDate'] as Timestamp).toDate(),
      priority: json['priority'] ?? 'NORMAL',
      status: json['status'] ?? 'DRAFT',
      homeworkType: json['homeworkType'] ?? 'HOMEWORK',
      allowSubmission: json['allowSubmission'] == true,
      allowLateSubmission: json['allowLateSubmission'] == true,
      attachments: attachments,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      publishedAt: json['publishedAt'] != null
          ? (json['publishedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'homeworkId': homeworkId,
      'title': title,
      'description': description,
      'classId': classId,
      'className': className,
      'section': section,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'assignedDate': Timestamp.fromDate(assignedDate),
      'dueDate': Timestamp.fromDate(dueDate),
      'priority': priority,
      'status': status,
      'homeworkType': homeworkType,
      'allowSubmission': allowSubmission,
      'allowLateSubmission': allowLateSubmission,
      'attachments': attachments.map((attachment) => attachment.toJson()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (publishedAt != null) 'publishedAt': Timestamp.fromDate(publishedAt!),
    };
  }

  HomeworkModel copyWith({
    String? homeworkId,
    String? title,
    String? description,
    String? classId,
    String? className,
    String? section,
    String? subjectId,
    String? subjectName,
    String? teacherId,
    String? teacherName,
    DateTime? assignedDate,
    DateTime? dueDate,
    String? priority,
    String? status,
    String? homeworkType,
    bool? allowSubmission,
    bool? allowLateSubmission,
    List<HomeworkAttachment>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? publishedAt,
  }) {
    return HomeworkModel(
      homeworkId: homeworkId ?? this.homeworkId,
      title: title ?? this.title,
      description: description ?? this.description,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      section: section ?? this.section,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      assignedDate: assignedDate ?? this.assignedDate,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      homeworkType: homeworkType ?? this.homeworkType,
      allowSubmission: allowSubmission ?? this.allowSubmission,
      allowLateSubmission: allowLateSubmission ?? this.allowLateSubmission,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      publishedAt: publishedAt ?? this.publishedAt,
    );
  }
}
