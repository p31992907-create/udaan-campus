import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:udaan_campus/models/student.dart';
import 'package:udaan_campus/models/test_result_model.dart';
import 'package:udaan_campus/models/user_role.dart';
import 'package:udaan_campus/services/attendance_service.dart';
import 'package:udaan_campus/services/auth_provider.dart';
import 'package:udaan_campus/services/exam_service.dart';

class ExamResultsScreen extends StatefulWidget {
  const ExamResultsScreen({super.key});

  @override
  State<ExamResultsScreen> createState() => _ExamResultsScreenState();
}

class _ExamResultsScreenState extends State<ExamResultsScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  final ExamService _examService = ExamService();

  bool _loading = true;
  bool _loadingResults = false;
  String? _error;
  String? _selectedClassSection;
  String? _selectedStudentId;
  List<String> _classSectionOptions = [];
  List<Student> _students = [];
  List<TestResultModel> _results = [];
  Student? _selectedStudent;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeScreen());
  }

  Future<void> _initializeScreen() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    if (user == null) {
      setState(() {
        _error = 'Unable to identify user.';
        _loading = false;
      });
      return;
    }

    try {
      if (user.role == UserRole.student) {
        final student = await _attendanceService.getStudentByEmail(user.email);
        if (student != null) {
          _selectedStudentId = student.id;
          _selectedStudent = student;
          _selectedClassSection = '${student.classId}-${student.section}';
          await _loadResults(student.id);
        }
      } else if (user.role == UserRole.parent) {
        final childIds = user.linkedChildren ?? [];
        if (childIds.isNotEmpty) {
          final children = await _attendanceService.getStudentsByIds(childIds);
          if (children.isNotEmpty) {
            _students = children;
            _selectedStudent = children.first;
            _selectedStudentId = children.first.id;
            _selectedClassSection = '${children.first.classId}-${children.first.section}';
            await _loadResults(children.first.id);
          }
        }
      } else {
        final options = await _attendanceService.getAssignedClassSections(
          userUid: user.uid,
          role: user.role,
        );
        _classSectionOptions = options;
        if (options.isNotEmpty) {
          _selectedClassSection = options.first;
          await _loadStudentsForSection(options.first);
        }
      }
    } catch (e) {
      _error = 'Unable to load academic progress.';
    }

    setState(() {
      _loading = false;
    });
  }

  Future<void> _loadStudentsForSection(String classSection) async {
    final parts = classSection.split('-');
    if (parts.length != 2) return;
    final classId = parts[0];
    final section = parts[1];
    final students = await _attendanceService.getStudentsForClassSection(
      classId: classId,
      section: section,
    );
    setState(() {
      _students = students;
      if (students.isNotEmpty) {
        _selectedStudent = students.first;
        _selectedStudentId = students.first.id;
      }
    });
    if (_selectedStudentId != null) {
      await _loadResults(_selectedStudentId!);
    }
  }

  Future<void> _loadResults(String studentId) async {
    setState(() {
      _loadingResults = true;
      _error = null;
    });
    try {
      final results = await _examService.fetchResultsForStudent(studentId);
      setState(() {
        _results = results;
      });
    } catch (e) {
      setState(() {
        _error = 'Unable to load results for selected student.';
      });
    } finally {
      setState(() {
        _loadingResults = false;
      });
    }
  }

  Widget _buildStudentSelector() {
    if (_students.isEmpty) {
      return const SizedBox.shrink();
    }
    return DropdownButtonFormField<String>(
      initialValue: _selectedStudentId,
      items: _students
          .map((student) => DropdownMenuItem(
                value: student.id,
                child: Text(student.name),
              ))
          .toList(),
      onChanged: (value) async {
        if (value == null) return;
        final selected = _students.firstWhere((student) => student.id == value);
        setState(() {
          _selectedStudentId = value;
          _selectedStudent = selected;
        });
        await _loadResults(value);
      },
      decoration: const InputDecoration(
        labelText: 'Select Student',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildClassSectionSelector() {
    if (_classSectionOptions.isEmpty) {
      return const SizedBox.shrink();
    }
    return DropdownButtonFormField<String>(
      initialValue: _selectedClassSection,
      items: _classSectionOptions
          .map((option) => DropdownMenuItem(
                value: option,
                child: Text(option.toUpperCase()),
              ))
          .toList(),
      onChanged: (value) async {
        if (value == null) return;
        setState(() {
          _selectedClassSection = value;
          _students = [];
          _selectedStudentId = null;
          _selectedStudent = null;
          _results = [];
        });
        await _loadStudentsForSection(value);
      },
      decoration: const InputDecoration(
        labelText: 'Class & Section',
        border: OutlineInputBorder(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Academic Progress')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null) ...[
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 12),
                  ],
                  if (_classSectionOptions.isNotEmpty) ...[
                    _buildClassSectionSelector(),
                    const SizedBox(height: 12),
                  ],
                  if (_students.isNotEmpty) ...[
                    _buildStudentSelector(),
                    const SizedBox(height: 16),
                  ],
                  if (_selectedStudent != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_selectedStudent!.name, style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 4),
                            Text('Class: ${_selectedStudent!.classId}-${_selectedStudent!.section}'),
                            Text('Roll No: ${_selectedStudent!.rollNumber}'),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Expanded(child: _buildResultsSection()),
                ],
              ),
      ),
    );
  }

  Widget _buildResultsSection() {
    if (_loadingResults) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_results.isEmpty) {
      return const Center(child: Text('No results available yet.'));
    }
    final average = _results.map((r) => r.marksObtained).fold<double>(0.0, (sum, value) => sum + value) / _results.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Average Score: ${average.toStringAsFixed(1)} / ${_results.first.maxMarks}', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: _results.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final result = _results[index];
              return ListTile(
                title: Text(result.testTitle),
                subtitle: Text('${result.subject} • ${result.grade} • ${result.remarks ?? 'No remarks'}'),
                trailing: Text('${result.marksObtained}/${result.maxMarks}'),
              );
            },
          ),
        ),
      ],
    );
  }
}
