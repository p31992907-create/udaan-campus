import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:udaan_campus/services/attendance_service.dart';
import 'package:udaan_campus/services/auth_provider.dart';
import 'package:udaan_campus/models/user_role.dart';
import 'package:udaan_campus/features/school/attendance/mark_attendance_screen.dart';
import 'package:udaan_campus/utils/utils.dart';

class SelectClassAttendanceScreen extends StatefulWidget {
  const SelectClassAttendanceScreen({super.key});

  @override
  State<SelectClassAttendanceScreen> createState() => _SelectClassAttendanceScreenState();
}

class _SelectClassAttendanceScreenState extends State<SelectClassAttendanceScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  List<String> _classSectionOptions = [];
  String? _selectedClassSection;
  DateTime _selectedDate = DateTime.now();
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAssignedClassSections());
  }

  Future<void> _loadAssignedClassSections() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    if (user == null) {
      setState(() {
        _error = 'Unable to load user assignment.';
        _loading = false;
      });
      return;
    }

      try {
      if (UserRole.isTeacher(user.role)) {
        final assigned = user.assignedClassSections ?? [];
        setState(() {
          _classSectionOptions = assigned;
          if (assigned.length == 1) {
            _selectedClassSection = assigned.first;
          }
          _loading = false;
        });
      } else if (UserRole.isAtLeastManager(user.role)) {
        final assigned = await _attendanceService.getAssignedClassSections(
          userUid: user.uid,
          role: user.role,
        );
        setState(() {
          _classSectionOptions = assigned;
          _loading = false;
        });
      } else {
        setState(() {
          _classSectionOptions = user.assignedClassSections ?? [];
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Unable to load class assignments. Please try again.';
        _loading = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  void _proceedToMarkAttendance() {
    if (_selectedClassSection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a class and section.')),
      );
      return;
    }

    final parts = _selectedClassSection!.split('-');
    if (parts.length != 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid class section configuration.')),
      );
      return;
    }

    final classId = parts[0].trim();
    final section = parts[1].trim();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MarkAttendanceScreen(
          classId: classId,
          className: classId,
          section: section,
          selectedDate: _selectedDate,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Class Attendance')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Select Class', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedClassSection,
                        items: _classSectionOptions
                            .map((option) => DropdownMenuItem(value: option, child: Text(option.toUpperCase())))
                            .toList(),
                        onChanged: (value) => setState(() => _selectedClassSection = value),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text('Select Date', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: _selectDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(border: OutlineInputBorder()),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(DateTimeUtils.formatDate(_selectedDate)),
                              const Icon(Icons.calendar_today),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: _proceedToMarkAttendance,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text('Load Students'),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
