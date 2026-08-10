class AttendanceSummaryModel {
  final int totalStudents;
  final int present;
  final int absent;
  final int late;
  final int halfDay;
  final int leave;
  final int unmarked;

  AttendanceSummaryModel({
    required this.totalStudents,
    required this.present,
    required this.absent,
    required this.late,
    required this.halfDay,
    required this.leave,
    required this.unmarked,
  });

  factory AttendanceSummaryModel.empty() {
    return AttendanceSummaryModel(
      totalStudents: 0,
      present: 0,
      absent: 0,
      late: 0,
      halfDay: 0,
      leave: 0,
      unmarked: 0,
    );
  }

  AttendanceSummaryModel copyWith({
    int? totalStudents,
    int? present,
    int? absent,
    int? late,
    int? halfDay,
    int? leave,
    int? unmarked,
  }) {
    return AttendanceSummaryModel(
      totalStudents: totalStudents ?? this.totalStudents,
      present: present ?? this.present,
      absent: absent ?? this.absent,
      late: late ?? this.late,
      halfDay: halfDay ?? this.halfDay,
      leave: leave ?? this.leave,
      unmarked: unmarked ?? this.unmarked,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalStudents': totalStudents,
      'present': present,
      'absent': absent,
      'late': late,
      'halfDay': halfDay,
      'leave': leave,
      'unmarked': unmarked,
    };
  }

  static AttendanceSummaryModel fromStatuses(List<String> statuses) {
    final present = statuses.where((s) => s == 'present').length;
    final absent = statuses.where((s) => s == 'absent').length;
    final late = statuses.where((s) => s == 'late').length;
    final halfDay = statuses.where((s) => s == 'half_day').length;
    final leave = statuses.where((s) => s == 'leave').length;
    final total = statuses.length;
    final unmarked = total - (present + absent + late + halfDay + leave);

    return AttendanceSummaryModel(
      totalStudents: total,
      present: present,
      absent: absent,
      late: late,
      halfDay: halfDay,
      leave: leave,
      unmarked: unmarked,
    );
  }
}
