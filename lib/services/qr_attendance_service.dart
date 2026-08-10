import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:udaan_campus/models/attendance_model.dart';
import 'package:udaan_campus/models/qr_scan_result_model.dart';
import 'package:udaan_campus/models/student.dart';
import 'package:udaan_campus/models/user_role.dart';
import 'package:udaan_campus/services/attendance_service.dart';
import 'package:udaan_campus/services/audit_service.dart';
import 'package:udaan_campus/models/audit_log_model.dart';
import 'package:udaan_campus/services/qr_service.dart';

class QrAttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AttendanceService _attendanceService = AttendanceService();
  final QrService _qrService = QrService();
  final AuditService _auditService = AuditService();

  CollectionReference<Map<String, dynamic>> get users => _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get attendanceCollection => _firestore.collection('attendance');

  Future<void> _verifyTeacherAuthorization({
    required String teacherUid,
    required String teacherRole,
    required String classId,
    required String section,
  }) async {
    if (UserRole.isAtLeastManager(teacherRole)) {
      return;
    }

    final snapshot = await users.doc(teacherUid).get();
    if (!snapshot.exists || snapshot.data() == null) {
      throw StateError('Teacher profile not found.');
    }

    final data = snapshot.data()!;
    final assignments = data['assignedClassSections'] as List<dynamic>?;
    final target = '$classId-$section';
    if (assignments == null || !assignments.contains(target)) {
      throw StateError('Unauthorized teacher for $target.');
    }
  }

  Future<QrScanResultModel> scanAndMarkAttendance({
    required String qrToken,
    required String teacherUid,
    required String teacherRole,
    required String classId,
    required String className,
    required String section,
    required DateTime date,
  }) async {
    final token = qrToken.trim();
    if (token.isEmpty) {
      return QrScanResultModel(status: QrScanStatus.invalidToken, message: 'Invalid QR code format.');
    }

    final student = await _qrService.getStudentByQrToken(token);
    if (student == null) {
      return QrScanResultModel(status: QrScanStatus.invalidToken, message: 'Student QR not found or inactive.');
    }

    if (!student.active) {
      return QrScanResultModel(status: QrScanStatus.studentInactive, message: 'Student is not active.');
    }

    if (student.classId != classId) {
      final message = student.section != null
          ? 'This student belongs to Class ${student.classId}-${student.section}, not Class $classId-$section.'
          : 'This student does not belong to the selected class.';
      return QrScanResultModel(status: QrScanStatus.wrongClass, message: message, student: student);
    }

    if (student.section != section) {
      return QrScanResultModel(
        status: QrScanStatus.wrongSection,
        message: 'This student belongs to Class $classId-${student.section}, not Class $classId-$section.',
        student: student,
      );
    }

    try {
      await _verifyTeacherAuthorization(
        teacherUid: teacherUid,
        teacherRole: teacherRole,
        classId: classId,
        section: section,
      );
    } catch (e) {
      return QrScanResultModel(status: QrScanStatus.unauthorizedTeacher, message: e.toString(), student: student);
    }

    final existingAttendance = await _attendanceService.getAttendanceByStudentAndDate(
      studentId: student.id,
      date: date,
    );

    if (existingAttendance != null) {
      return QrScanResultModel(
        status: QrScanStatus.duplicateAttendance,
        message: 'Attendance already marked for this student.',
        student: student,
        attendance: existingAttendance,
      );
    }

    final attendanceId = _attendanceService.attendanceDocId(student.id, date);
    final record = AttendanceModel(
      attendanceId: attendanceId,
      studentId: student.id,
      classId: classId,
      className: className,
      section: section,
      date: DateTime(date.year, date.month, date.day),
      status: 'present',
      markedBy: teacherUid,
      markedByRole: teacherRole,
      method: 'qr',
      remarks: null,
      timestamp: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await attendanceCollection.doc(attendanceId).set({
      ...record.toJson(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'timestamp': FieldValue.serverTimestamp(),
    });

    final auditId = _auditService.buildAuditId('qr_attendance', student.id, DateTime.now());
    await _auditService.createAuditLog(
      AuditLogModel(
        auditId: auditId,
        action: 'QR_ATTENDANCE_CREATED',
        targetType: 'attendance',
        targetId: attendanceId,
        performedBy: teacherUid,
        performedByRole: teacherRole,
        oldValue: null,
        newValue: {
          'studentId': student.id,
          'classId': classId,
          'section': section,
          'status': 'present',
          'method': 'qr',
        },
        timestamp: DateTime.now(),
      ),
    );

    return QrScanResultModel(
      status: QrScanStatus.success,
      message: 'Attendance marked present.',
      student: student,
      attendance: record,
    );
  }

  Future<void> markRemainingAbsent({
    required String classId,
    required String className,
    required String section,
    required DateTime date,
    required String markedBy,
    required String markedByRole,
    required List<Student> students,
    required Set<String> alreadyMarkedStudentIds,
  }) async {
    final records = students
        .where((student) => !alreadyMarkedStudentIds.contains(student.id))
        .map((student) {
          final attendanceId = _attendanceService.attendanceDocId(student.id, date);
          return AttendanceModel(
            attendanceId: attendanceId,
            studentId: student.id,
            classId: classId,
            className: className,
            section: section,
            date: DateTime(date.year, date.month, date.day),
            status: 'absent',
            markedBy: markedBy,
            markedByRole: markedByRole,
            method: 'manual',
            remarks: 'Marked absent after QR attendance completion',
            timestamp: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        })
        .toList();

    if (records.isEmpty) return;
    await _attendanceService.saveBulkAttendance(records: records);

    final auditId = _auditService.buildAuditId('qr_attendance_complete', classId, DateTime.now());
    await _auditService.createAuditLog(
      AuditLogModel(
        auditId: auditId,
        action: 'QR_ATTENDANCE_COMPLETED',
        targetType: 'attendance',
        targetId: classId,
        performedBy: markedBy,
        performedByRole: markedByRole,
        oldValue: null,
        newValue: {
          'markedAbsentCount': records.length,
          'date': date.toIso8601String(),
        },
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<List<AttendanceModel>> getQrAttendanceHistory({
    String? classId,
    String? section,
    DateTime? startDate,
    DateTime? endDate,
    String? studentId,
    String? teacherId,
  }) async {
    Query<Map<String, dynamic>> query = attendanceCollection.where('method', isEqualTo: 'qr');
    if (classId != null && classId.isNotEmpty) {
      query = query.where('classId', isEqualTo: classId);
    }
    if (section != null && section.isNotEmpty) {
      query = query.where('section', isEqualTo: section);
    }
    if (studentId != null && studentId.isNotEmpty) {
      query = query.where('studentId', isEqualTo: studentId);
    }
    if (teacherId != null && teacherId.isNotEmpty) {
      query = query.where('markedBy', isEqualTo: teacherId);
    }
    if (startDate != null) {
      query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(startDate.year, startDate.month, startDate.day)));
    }
    if (endDate != null) {
      query = query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(DateTime(endDate.year, endDate.month, endDate.day)));
    }
    query = query.orderBy('date', descending: true);
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => AttendanceModel.fromJson(doc.data())).toList();
  }
}
