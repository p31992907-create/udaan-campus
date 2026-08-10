import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:udaan_campus/models/attendance_model.dart';
import 'package:udaan_campus/models/attendance_summary_model.dart';
import 'package:udaan_campus/services/attendance_service.dart';
import 'package:udaan_campus/services/auth_provider.dart';
import 'package:udaan_campus/utils/utils.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  String? _selectedClassSection;
  List<String> _classSectionOptions = [];
  bool _loading = true;
  bool _searching = false;
  String? _error;
  List<AttendanceModel> _records = [];

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
        _error = 'Unable to load user information.';
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
        _error = 'Unable to load class list.';
        _loading = false;
      });
    }
  }

  Future<void> _searchHistory() async {
    if (_selectedClassSection == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select class and section first.')));
      return;
    }

    setState(() {
      _searching = true;
      _error = null;
      _records = [];
    });

    final parts = _selectedClassSection!.split('-');
    if (parts.length != 2) {
      setState(() {
        _error = 'Invalid class/section entry.';
        _searching = false;
      });
      return;
    }

    try {
      final classId = parts[0];
      final section = parts[1];
      final records = await _attendanceService.getClassAttendanceHistory(
        classId: classId,
        section: section,
        startDate: _startDate,
        endDate: _endDate,
      );
      setState(() {
        _records = records;
        _searching = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Unable to load attendance history.';
        _searching = false;
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

  AttendanceSummaryModel _summary() {
    final statuses = _records.map((e) => e.status).toList();
    return AttendanceSummaryModel.fromStatuses(statuses);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Class Attendance History')),
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
                  ElevatedButton(onPressed: _searching ? null : _searchHistory, child: const Text('Search Attendance')),
                  const SizedBox(height: 12),
                  if (_searching) const Center(child: CircularProgressIndicator()),
                  if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
                  if (!_searching && _records.isNotEmpty) ...[
                    _buildSummaryCard(_summary()),
                    const SizedBox(height: 12),
                    Expanded(child: _buildRecordList()),
                  ],
                  if (!_searching && _records.isEmpty && _error == null)
                    const Expanded(child: Center(child: Text('No attendance found for selected filters.'))),
                ],
              ),
      ),
    );
  }

  Widget _buildSummaryCard(AttendanceSummaryModel summary) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _summaryItem('Total', summary.totalStudents.toString()),
            _summaryItem('Present', summary.present.toString()),
            _summaryItem('Absent', summary.absent.toString()),
            _summaryItem('Late', summary.late.toString()),
            _summaryItem('Half Day', summary.halfDay.toString()),
            _summaryItem('Leave', summary.leave.toString()),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildRecordList() {
    return ListView.separated(
      itemCount: _records.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final record = _records[index];
        return ListTile(
          title: Text(record.studentId),
          subtitle: Text('${DateTimeUtils.formatDate(record.date)} • ${record.status.toUpperCase()}'),
          trailing: Text(record.markedByRole.toUpperCase()),
        );
      },
    );
  }
}
