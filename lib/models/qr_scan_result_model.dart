import 'package:udaan_campus/models/attendance_model.dart';
import 'package:udaan_campus/models/student.dart';

enum QrScanStatus {
  success,
  invalidToken,
  tokenInactive,
  studentNotFound,
  studentInactive,
  wrongClass,
  wrongSection,
  unauthorizedTeacher,
  duplicateAttendance,
  existingAttendance,
  error,
}

class QrScanResultModel {
  final QrScanStatus status;
  final String message;
  final Student? student;
  final AttendanceModel? attendance;

  QrScanResultModel({
    required this.status,
    required this.message,
    this.student,
    this.attendance,
  });

  bool get isSuccess => status == QrScanStatus.success;
}
