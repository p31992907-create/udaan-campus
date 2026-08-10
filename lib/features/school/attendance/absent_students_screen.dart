import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:udaan_campus/features/school/attendance/call_response_screen.dart';
import 'package:udaan_campus/models/student.dart';
import 'package:udaan_campus/services/attendance_service.dart';
import 'package:udaan_campus/services/auth_provider.dart';
import 'package:udaan_campus/utils/utils.dart';

class AbsentStudentsScreen extends StatefulWidget {
  const AbsentStudentsScreen({super.key});

  @override
  State<AbsentStudentsScreen> createState() => _AbsentStudentsScreenState();
}

class _AbsentStudentsScreenState extends State<AbsentStudentsScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  String? _selectedClassSection;
  List<String> _classSectionOptions = [];
  DateTime _selectedDate = DateTime.now();
  bool _loading = true;
  bool _searching = false;
  String? _error;
  List<Student> _absentStudents = [];

  @override
  void initState() {
    super.initState();
    _loadClassSections();
  }

  Future<void> _loadClassSections() async {
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
      final sections = await _attendanceService.getAssignedClassSections(
        userUid: user.uid,
        role: user.role,
      );
      setState(() {
        _classSectionOptions = sections;
        if (_classSectionOptions.length == 1) {
          _selectedClassSection = _classSectionOptions.first;
        }
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Unable to load class sections.';
        _loading = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _loadAbsentStudents() async {
    if (_selectedClassSection == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select class and section first.')));
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
      _absentStudents = [];
    });
    try {
      final classId = parts[0];
      final section = parts[1];
      final students = await _attendanceService.getAbsentStudents(
        classId: classId,
        section: section,
        date: _selectedDate,
      );
      setState(() {
        _absentStudents = students;
        _searching = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Unable to load absent student list.';
        _searching = false;
      });
    }
  }

  Future<void> _navigateToCallResponse(Student student) async {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallResponseScreen(student: student, attendanceDate: _selectedDate),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Absent Students')),
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
                    onTap: _selectDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Date'),
                      child: Text(DateTimeUtils.formatDate(_selectedDate)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _searching ? null : _loadAbsentStudents, child: const Text('Load Absent Students')),
                  const SizedBox(height: 12),
                  if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
                  if (_searching) const Expanded(child: Center(child: CircularProgressIndicator())),
                  if (!_searching && _absentStudents.isNotEmpty) Expanded(child: _buildStudentList()),
                  if (!_searching && _absentStudents.isEmpty && _error == null)
                    const Expanded(child: Center(child: Text('No absent students found.'))),
                ],
              ),
      ),
    );
  }

  Widget _buildStudentList() {
    return ListView.separated(
      itemCount: _absentStudents.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final student = _absentStudents[index];
        return ListTile(
          title: Text(student.name),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Father: ${student.parentName ?? 'N/A'}'),
              Text('Parent Mobile: ${student.parentPhone ?? 'N/A'}'),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.call),
            onPressed: student.parentPhone != null ? () => _navigateToCallResponse(student) : null,
          ),
        );
      },
    );
  }
}
