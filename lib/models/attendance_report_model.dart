class AttendanceReportModel {
  final String studentId;
  final String studentName;
  final int present;
  final int absent;
  final int late;
  final int halfDay;
  final int leave;
  final double attendancePercentage;

  AttendanceReportModel({
    required this.studentId,
    required this.studentName,
    required this.present,
    required this.absent,
    required this.late,
    required this.halfDay,
    required this.leave,
    required this.attendancePercentage,
  });

  factory AttendanceReportModel.fromCounts({
    required String studentId,
    required String studentName,
    required int present,
    required int absent,
    required int late,
    required int halfDay,
    required int leave,
  }) {
    final total = present + absent + late + halfDay + leave;
    final percentage = total == 0 ? 0.0 : (present / total) * 100;
    return AttendanceReportModel(
      studentId: studentId,
      studentName: studentName,
      present: present,
      absent: absent,
      late: late,
      halfDay: halfDay,
      leave: leave,
      attendancePercentage: percentage,
    );
  }
}
