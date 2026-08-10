import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:udaan_campus/models/attendance_report_model.dart';
import 'package:udaan_campus/services/attendance_service.dart';
import 'package:udaan_campus/services/auth_provider.dart';
import 'package:udaan_campus/utils/utils.dart';

class ClassAttendanceReportScreen extends StatefulWidget {
  const ClassAttendanceReportScreen({super.key});

  @override
  State<ClassAttendanceReportScreen> createState() => _ClassAttendanceReportScreenState();
}

class _ClassAttendanceReportScreenState extends State<ClassAttendanceReportScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  bool _loading = true;
  String? _selectedClassSection;
  List<String> _classSectionOptions = [];
  bool _searching = false;
  String? _error;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  List<AttendanceReportModel> _reports = [];

  @override
  void initState() {
    super.initState();
    _loadAllowedClasses();
  }

  Future<void> _loadAllowedClasses() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    if (user == null) {
      setState(() {
        _error = 'Unable to load user info.';
        _loading = false;
      });
      return;
    }
    try {
      final options = await _attendanceService.getAssignedClassSections(
        userUid: user.uid,
        role: user.role,
      );
      setState(() {
        _classSectionOptions = options;
        if (options.length == 1) {
          _selectedClassSection = options.first;
        }
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Unable to load class options.';
        _loading = false;
      });
    }
  }

  Future<void> _selectDateRange() async {
    final picker = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picker != null) {
      setState(() {
        _startDate = picker.start;
        _endDate = picker.end;
      });
    }
  }

  Future<void> _loadReport() async {
    if (_selectedClassSection == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select class and section.')));
      return;
    }
    final parts = _selectedClassSection!.split('-');
    if (parts.length != 2) {
      setState(() {
        _error = 'Invalid class/section value.';
      });
      return;
    }
    setState(() {
      _searching = true;
      _error = null;
      _reports = [];
    });
    try {
      final classId = parts[0];
      final section = parts[1];
      final history = await _attendanceService.getClassAttendanceHistory(
        classId: classId,
        section: section,
        startDate: _startDate,
        endDate: _endDate,
      );
      final rows = <String, Map<String, int>>{};
      for (final record in history) {
        final entry = rows.putIfAbsent(record.studentId, () => {'present': 0, 'absent': 0, 'late': 0, 'half_day': 0, 'leave': 0});
        entry[record.status] = (entry[record.status] ?? 0) + 1;
      }
      final reports = rows.entries.map((entry) {
        final counts = entry.value;
        final present = counts['present'] ?? 0;
        final absent = counts['absent'] ?? 0;
        final late = counts['late'] ?? 0;
        final halfDay = counts['half_day'] ?? 0;
        final leave = counts['leave'] ?? 0;
        return AttendanceReportModel.fromCounts(
          studentId: entry.key,
          studentName: entry.key,
          present: present,
          absent: absent,
          late: late,
          halfDay: halfDay,
          leave: leave,
        );
      }).toList();
      setState(() {
        _reports = reports;
        _searching = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Unable to load report data.';
        _searching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Class Attendance Report')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _selectedClassSection,
                    items: _classSectionOptions
                        .map((option) => DropdownMenuItem(value: option, child: Text(option.toUpperCase())))
                        .toList(),
                    onChanged: (value) => setState(() => _selectedClassSection = value),
                    decoration: const InputDecoration(labelText: 'Class - Section', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _selectDateRange,
                    child: InputDecorator(
                      decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Date Range'),
                      child: Text('${DateTimeUtils.formatDate(_startDate)} - ${DateTimeUtils.formatDate(_endDate)}'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _searching ? null : _loadReport, child: const Text('Load Report')),
                  const SizedBox(height: 12),
                  if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
                  if (_searching) const Expanded(child: Center(child: CircularProgressIndicator())),
                  if (!_searching && _reports.isNotEmpty) Expanded(child: _buildReportList()),
                  if (!_searching && _reports.isEmpty && _error == null)
                    const Expanded(child: Center(child: Text('No report data available.'))),
                ],
              ),
      ),
    );
  }

  Widget _buildReportList() {
    return ListView.separated(
      itemCount: _reports.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final report = _reports[index];
        return ListTile(
          title: Text(report.studentName),
          subtitle: Text('Present: ${report.present}, Absent: ${report.absent}, Late: ${report.late}, Half Day: ${report.halfDay}, Leave: ${report.leave}'),
          trailing: Text('${report.attendancePercentage.toStringAsFixed(1)}%'),
        );
      },
    );
  }
}
