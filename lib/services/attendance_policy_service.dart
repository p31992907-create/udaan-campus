import 'package:udaan_campus/models/attendance_summary_model.dart';

class AttendancePolicyService {
  static const presentWeight = 1.0;
  static const lateWeight = 0.5;
  static const halfDayWeight = 0.5;
  static const leaveWeight = 0.0;

  static double calculateAttendancePercentage({
    required int present,
    required int late,
    required int halfDay,
    required int leave,
  }) {
    final totalApplicable = present + late + halfDay + leave;
    if (totalApplicable == 0) return 0.0;

    final earned =
        present * presentWeight + late * lateWeight + halfDay * halfDayWeight + leave * leaveWeight;

    return (earned / (totalApplicable * presentWeight)) * 100;
  }

  static AttendanceSummaryModel buildSummary(List<String> statuses) {
    return AttendanceSummaryModel.fromStatuses(statuses);
  }
}
