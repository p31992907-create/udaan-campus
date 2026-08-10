import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:udaan_campus/models/test_model.dart';
import 'package:udaan_campus/models/test_result_model.dart';
import 'package:udaan_campus/models/student.dart';
import 'package:udaan_campus/services/attendance_service.dart';
import 'package:udaan_campus/services/exam_service.dart';
import 'package:udaan_campus/services/auth_provider.dart';

class TestResultEntryScreen extends StatefulWidget {
  const TestResultEntryScreen({super.key, required this.test});

  final TestModel test;

  @override
  State<TestResultEntryScreen> createState() => _TestResultEntryScreenState();
}

class _TestResultEntryScreenState extends State<TestResultEntryScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  final ExamService _examService = ExamService();

  bool _loading = true;
  bool _saving = false;
  String? _error;
  List<Student> _students = [];
  final Map<String, TextEditingController> _marksControllers = {};
  final Map<String, TextEditingController> _remarksControllers = {};

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    for (final controller in _marksControllers.values) {
      controller.dispose();
    }
    for (final controller in _remarksControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final students = await _attendanceService.getStudentsForClassSection(
        classId: widget.test.classId,
        section: widget.test.section,
      );
      for (final student in students) {
        _marksControllers.putIfAbsent(
            student.id, () => TextEditingController(text: '0'));
        _remarksControllers.putIfAbsent(student.id, () => TextEditingController());
      }
      setState(() {
        _students = students;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Unable to load students for this class.';
        _loading = false;
      });
    }
  }

  Future<void> _submitScores() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    if (user == null) return;
    final results = <TestResultModel>[];

    for (final student in _students) {
      final marksText = _marksControllers[student.id]?.text.trim() ?? '0';
      final marks = double.tryParse(marksText) ?? 0.0;
      final grade = _examService.calculateGrade(marks, widget.test.maxMarks);
      final remarks = _remarksControllers[student.id]?.text.trim();
      results.add(TestResultModel(
        resultId: TestResultModel.buildResultId(widget.test.testId, student.id),
        testId: widget.test.testId,
        testTitle: widget.test.title,
        subject: widget.test.subject,
        studentId: student.id,
        studentName: student.name,
        classId: widget.test.classId,
        section: widget.test.section,
        marksObtained: marks,
        maxMarks: widget.test.maxMarks,
        grade: grade,
        remarks: remarks?.isEmpty ?? true ? null : remarks,
        createdAt: DateTime.now(),
        createdBy: user.uid,
      ));
    }

    setState(() {
      _saving = true;
    });

    try {
      await _examService.saveTestResults(results, user.uid, user.role);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assessment results saved.')),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _error = 'Unable to save assessment results.';
      });
    } finally {
      setState(() {
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Enter Scores - ${widget.test.title}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Subject: ${widget.test.subject}'),
                  Text('Max Marks: ${widget.test.maxMarks}'),
                  Text('Date: ${widget.test.date.toLocal().toString().split(' ')[0]}'),
                  const SizedBox(height: 12),
                  if (_error != null)
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 12),
                  Expanded(child: _buildStudentInputs()),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _saving ? null : _submitScores,
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save Results'),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStudentInputs() {
    if (_students.isEmpty) {
      return const Center(child: Text('No students available in this class.'));
    }
    return ListView.separated(
      itemCount: _students.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final student = _students[index];
        return ListTile(
          title: Text(student.name),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Roll No: ${student.rollNumber}'),
              TextField(
                controller: _marksControllers[student.id],
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Marks Obtained',
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _remarksControllers[student.id],
                decoration: const InputDecoration(
                  labelText: 'Remarks (optional)',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
