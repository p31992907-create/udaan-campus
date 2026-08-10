import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:udaan_campus/models/attendance_report_model.dart';
import 'package:udaan_campus/services/attendance_service.dart';
import 'package:udaan_campus/services/auth_provider.dart';
import 'package:udaan_campus/utils/utils.dart';

class MonthlyAttendanceScreen extends StatefulWidget {
  const MonthlyAttendanceScreen({super.key});

  @override
  State<MonthlyAttendanceScreen> createState() => _MonthlyAttendanceScreenState();
}

class _MonthlyAttendanceScreenState extends State<MonthlyAttendanceScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  bool _loading = true;
  String? _selectedClassSection;
  List<String> _classSectionOptions = [];
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  bool _searching = false;
  String? _error;
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
        _error = 'Unable to load allowed classes.';
        _loading = false;
      });
    }
  }

  Future<void> _loadMonthlyReport() async {
    if (_selectedClassSection == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select class and section.')));
      return;
    }
    final parts = _selectedClassSection!.split('-');
    if (parts.length != 2) {
      setState(() {
        _error = 'Invalid class/section entry.';
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
      final reports = await _attendanceService.getMonthlyAttendanceReport(
        classId: classId,
        section: section,
        month: _selectedMonth,
        year: _selectedYear,
      );
      setState(() {
        _reports = reports;
        _searching = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Unable to load monthly report.';
        _searching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Monthly Attendance')),
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
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _selectedMonth,
                          items: List.generate(12, (index) => index + 1)
                              .map((month) => DropdownMenuItem(value: month, child: Text(DateTimeUtils.formatDate(DateTime(0, month)).split(' ')[1])))
                              .toList(),
                          onChanged: (value) => setState(() => _selectedMonth = value ?? _selectedMonth),
                          decoration: const InputDecoration(labelText: 'Month', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _selectedYear,
                          items: List.generate(5, (index) => DateTime.now().year - index)
                              .map((year) => DropdownMenuItem(value: year, child: Text(year.toString())))
                              .toList(),
                          onChanged: (value) => setState(() => _selectedYear = value ?? _selectedYear),
                          decoration: const InputDecoration(labelText: 'Year', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _searching ? null : _loadMonthlyReport, child: const Text('Load Monthly Report')),
                  const SizedBox(height: 12),
                  if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
                  if (_searching) const Expanded(child: Center(child: CircularProgressIndicator())),
                  if (!_searching && _reports.isNotEmpty) Expanded(child: _buildReportList()),
                  if (!_searching && _reports.isEmpty && _error == null)
                    const Expanded(child: Center(child: Text('No monthly attendance data.'))),
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
