import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:udaan_campus/models/test_model.dart';
import 'package:udaan_campus/services/auth_provider.dart';
import 'package:udaan_campus/services/attendance_service.dart';
import 'package:udaan_campus/services/exam_service.dart';
import 'package:udaan_campus/features/school/exams/test_result_entry_screen.dart';

class TestManagementScreen extends StatefulWidget {
  const TestManagementScreen({super.key});

  @override
  State<TestManagementScreen> createState() => _TestManagementScreenState();
}

class _TestManagementScreenState extends State<TestManagementScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  final ExamService _examService = ExamService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _maxMarksController =
      TextEditingController(text: '100');

  bool _loading = true;
  bool _saving = false;
  String? _selectedClassSection;
  DateTime _selectedDate = DateTime.now();
  List<String> _classSectionOptions = [];
  List<TestModel> _tests = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAllowedClassSections();
  }

  Future<void> _loadAllowedClassSections() async {
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
        if (options.isNotEmpty) {
          _selectedClassSection = options.first;
        }
        _loading = false;
      });
      if (_selectedClassSection != null) {
        await _loadTests();
      }
    } catch (e) {
      setState(() {
        _error = 'Unable to load class sections.';
        _loading = false;
      });
    }
  }

  Future<void> _loadTests() async {
    if (_selectedClassSection == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final parts = _selectedClassSection!.split('-');
    if (parts.length != 2) {
      setState(() {
        _error = 'Please select a valid class and section.';
        _loading = false;
      });
      return;
    }

    try {
      final classId = parts[0];
      final section = parts[1];
      final tests = await _examService.fetchTestsForClassSection(
        classId: classId,
        section: section,
      );
      setState(() {
        _tests = tests;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Unable to load assessments.';
        _loading = false;
      });
    }
  }

  Future<void> _selectAssessmentDate() async {
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

  Future<void> _publishTest() async {
    if (_selectedClassSection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a class and section.')),
      );
      return;
    }
    if (_titleController.text.trim().isEmpty ||
        _subjectController.text.trim().isEmpty ||
        _maxMarksController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields.')),
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    if (user == null) return;

    final parts = _selectedClassSection!.split('-');
    if (parts.length != 2) return;

    final maxMarks = int.tryParse(_maxMarksController.text.trim()) ?? 100;
    final classId = parts[0];
    final section = parts[1];

    final test = TestModel(
      testId: 'test_${classId}_${section}_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      subject: _subjectController.text.trim(),
      classId: classId,
      section: section,
      maxMarks: maxMarks,
      date: _selectedDate,
      createdBy: user.uid,
      teacherName: user.displayName.isNotEmpty ? user.displayName : user.email,
      createdAt: DateTime.now(),
    );

    setState(() {
      _saving = true;
    });

    try {
      await _examService.createTest(test, user.uid, user.role);
      _titleController.clear();
      _subjectController.clear();
      _maxMarksController.text = '100';
      await _loadTests();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assessment published successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to publish assessment.')),
      );
    } finally {
      setState(() {
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assessment Management')),
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
                        .map((value) => DropdownMenuItem(
                              value: value,
                              child: Text(value.toUpperCase()),
                            ))
                        .toList(),
                    onChanged: (value) async {
                      setState(() {
                        _selectedClassSection = value;
                      });
                      await _loadTests();
                    },
                    decoration: const InputDecoration(
                      labelText: 'Class & Section',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Assessment Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _subjectController,
                    decoration: const InputDecoration(
                      labelText: 'Subject',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _maxMarksController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Maximum Marks',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: _selectAssessmentDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Assessment Date',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: _saving ? null : _publishTest,
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Publish Assessment'),
                  ),
                  const SizedBox(height: 16),
                  if (_error != null)
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 8),
                  Expanded(child: _buildTestList()),
                ],
              ),
      ),
    );
  }

  Widget _buildTestList() {
    if (_tests.isEmpty) {
      return const Center(child: Text('No assessments published yet.'));
    }

    return ListView.separated(
      itemCount: _tests.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final test = _tests[index];
        return ListTile(
          title: Text(test.title),
          subtitle: Text('${test.subject} • ${test.classId}-${test.section} • ${test.maxMarks} marks'),
          trailing: const Icon(Icons.arrow_forward),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TestResultEntryScreen(test: test),
              ),
            );
            await _loadTests();
          },
        );
      },
    );
  }
}
