import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:udaan_campus/models/student.dart';
import 'package:udaan_campus/models/test_result_model.dart';
import 'package:udaan_campus/models/user_role.dart';
import 'package:udaan_campus/models/test_model.dart';
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
  int? _selectedPosition;
  bool _positionReady = false;
  bool _savingMarks = false;
  List<TestModel> _availableTests = [];
  final Map<String, TextEditingController> _markControllers = {};
  final Map<String, TextEditingController> _remarkControllers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeScreen());
  }

  @override
  void dispose() {
    for (final controller in _markControllers.values) {
      controller.dispose();
    }
    for (final controller in _remarkControllers.values) {
      controller.dispose();
    }
    super.dispose();
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
        if (student != null &&
            student.classId != null &&
            student.section != null) {
          final classId = student.classId!;
          final section = student.section!;
          _selectedStudentId = student.id;
          _selectedStudent = student;
          _selectedClassSection = '$classId-$section';
          await _loadPositionForClassSection(classId, section);
          await _loadResults(student.id);
        }
      } else if (user.role == UserRole.parent) {
        final childIds = user.linkedChildren ?? [];
        if (childIds.isNotEmpty) {
          final children = await _attendanceService.getStudentsByIds(childIds);
          final child = children.isNotEmpty ? children.first : null;
          if (child != null && child.classId != null && child.section != null) {
            final classId = child.classId!;
            final section = child.section!;
            _students = children;
            _selectedStudent = child;
            _selectedStudentId = child.id;
            _selectedClassSection = '$classId-$section';
            await _loadPositionForClassSection(
              classId,
              section,
            );
            await _loadResults(child.id);
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
    await _loadPositionForClassSection(classId, section);
    if (_selectedStudentId != null) {
      await _loadResults(_selectedStudentId!);
    }
  }

  Future<void> _loadPositionForClassSection(String classId, String section) async {
    final students = await _attendanceService.getStudentsForClassSection(
      classId: classId,
      section: section,
    );
    final finalResults = await _examService.fetchResultsForClassSection(
      classId: classId,
      section: section,
    );
    final resultsByStudent = <String, List<TestResultModel>>{};
    for (final result in finalResults) {
      resultsByStudent.putIfAbsent(result.studentId, () => []).add(result);
    }
    final complete = students.isNotEmpty &&
        students.every((student) => resultsByStudent.containsKey(student.id));
    if (!complete || _selectedStudentId == null) {
      if (mounted) {
        setState(() {
          _positionReady = false;
          _selectedPosition = null;
        });
      }
      return;
    }

    final totals = <String, double>{
      for (final student in students)
        student.id: (resultsByStudent[student.id] ?? []).fold<double>(
              0,
              (sum, result) => sum + (result.maxMarks == 0
                  ? 0
                  : result.marksObtained / result.maxMarks),
            ),
    };
    final orderedIds = totals.keys.toList()
      ..sort((a, b) => totals[b]!.compareTo(totals[a]!));
    final position = orderedIds.indexOf(_selectedStudentId!) + 1;
    if (mounted) {
      setState(() {
        _positionReady = position > 0;
        _selectedPosition = position > 0 ? position : null;
      });
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
      await _loadMarkEntryData(results);
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

  Future<void> _loadMarkEntryData(List<TestResultModel> results) async {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user?.role != UserRole.superManager ||
          _selectedStudent?.classId == null ||
          _selectedStudent?.section == null) {
        return;
      }
      final tests = await _examService.fetchTestsForClassSection(
        classId: _selectedStudent!.classId!,
        section: _selectedStudent!.section!,
      );
      final byTest = {
        for (final result in results) result.testId: result,
      };
      for (final controller in _markControllers.values) {
        controller.dispose();
      }
      for (final controller in _remarkControllers.values) {
        controller.dispose();
      }
      _markControllers.clear();
      _remarkControllers.clear();
      for (final test in tests) {
        final result = byTest[test.testId];
        _markControllers[test.testId] = TextEditingController(
          text: result == null ? '' : _formatMark(result.marksObtained),
        );
        _remarkControllers[test.testId] = TextEditingController(
          text: result?.remarks ?? '',
        );
      }
      if (mounted) {
        setState(() => _availableTests = tests);
      }
    }

  String _formatMark(double value) {
      return value == value.roundToDouble()
          ? value.toInt().toString()
          : value.toString();
    }

  Future<void> _saveSelectedStudentMarks() async {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      final student = _selectedStudent;
    if (user?.role != UserRole.superManager || student == null) return;
      final results = <TestResultModel>[];
      for (final test in _availableTests) {
        final text = _markControllers[test.testId]?.text.trim() ?? '';
        final marks = double.tryParse(text);
        if (marks == null || marks < 0 || marks > test.maxMarks) {
          setState(() => _error =
              'Enter marks between 0 and ${test.maxMarks} for ${test.subject}.');
          return;
        }
        final remarks = _remarkControllers[test.testId]?.text.trim();
        results.add(TestResultModel(
          resultId: TestResultModel.buildResultId(test.testId, student.id),
          testId: test.testId,
          testTitle: test.title,
          subject: test.subject,
          studentId: student.id,
          studentName: student.name,
          classId: test.classId,
          section: test.section,
          marksObtained: marks,
          maxMarks: test.maxMarks,
          grade: _examService.calculateGrade(marks, test.maxMarks),
          remarks: remarks == null || remarks.isEmpty ? null : remarks,
          createdAt: DateTime.now(),
          createdBy: user!.uid,
          isFinalExam: test.isFinalExam,
        ));
      }
    setState(() => _savingMarks = true);
    try {
      await _examService.saveTestResults(results, user!.uid, user.role);
      await _loadResults(student.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student marks saved.')),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Unable to save student marks.');
    } finally {
      if (mounted) setState(() => _savingMarks = false);
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
        if (selected.classId != null && selected.section != null) {
          await _loadPositionForClassSection(
            selected.classId!,
            selected.section!,
          );
        }
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
          _positionReady = false;
          _selectedPosition = null;
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
                            if (_positionReady && _selectedPosition != null)
                              Text('Position in class: $_selectedPosition'),
                          ],
                        ),
                      ),
                    ),
                  if (_availableTests.isNotEmpty &&
                      Provider.of<AuthProvider>(context).user?.role ==
                          UserRole.superManager) ...[
                    const SizedBox(height: 12),
                    _buildMarkEntrySection(),
                  ],
                  const SizedBox(height: 16),
                  Expanded(child: _buildResultsSection()),
                ],
              ),
      ),
    );
  }

  Widget _buildMarkEntrySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enter marks for ${_selectedStudent!.name}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ..._availableTests.map((test) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${test.subject} (${test.isFinalExam ? 'Final' : test.title})',
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _markControllers[test.testId],
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Marks / ${test.maxMarks}',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
            FilledButton.icon(
              onPressed: _savingMarks ? null : _saveSelectedStudentMarks,
              icon: const Icon(Icons.save),
              label: Text(_savingMarks ? 'Saving...' : 'Save marks'),
            ),
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
