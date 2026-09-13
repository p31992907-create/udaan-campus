import 'package:flutter/material.dart';
import 'package:udaan_campus/models/student.dart';
import 'package:udaan_campus/services/attendance_service.dart';
import 'package:udaan_campus/services/external_backend_service.dart';

class CreateParentAccountScreen extends StatefulWidget {
  const CreateParentAccountScreen({super.key});

  @override
  State<CreateParentAccountScreen> createState() =>
      _CreateParentAccountScreenState();
}

class _CreateParentAccountScreenState
    extends State<CreateParentAccountScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _attendance = AttendanceService();
  final _backend = ExternalBackendService();
  List<Student> _students = [];
  String? _selectedStudent;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    try {
      final sections = await _attendance.getAssignedClassSections(
        userUid: '',
        role: 'manager',
      );
      final students = <Student>[];
      for (final entry in sections) {
        final parts = entry.split('-');
        if (parts.length == 2) {
          students.addAll(await _attendance.getStudentsForClassSection(
            classId: parts[0],
            section: parts[1],
          ));
        }
      }
      if (mounted) {
        setState(() {
          _students = students;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Unable to load students.';
        });
      }
    }
  }

  Future<void> _create() async {
    if (_name.text.trim().isEmpty ||
        !_email.text.contains('@') ||
        _password.text.length < 8 ||
        _selectedStudent == null) {
      setState(() => _error =
          'Enter parent name, valid email, 8+ character password, and student.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _backend.createParentAccount(
        email: _email.text.trim(),
        password: _password.text,
        displayName: _name.text.trim(),
        linkedChildren: [_selectedStudent!],
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Parent account created successfully.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Unable to create parent account.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Parent Account')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Parent name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Parent email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Temporary password (8+ characters)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedStudent,
                  decoration: const InputDecoration(
                    labelText: 'Link student',
                    border: OutlineInputBorder(),
                  ),
                  items: _students
                      .map((student) => DropdownMenuItem(
                            value: student.id,
                            child: Text('${student.name} (${student.rollNumber})'),
                          ))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedStudent = value),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _saving ? null : _create,
                  child: Text(_saving ? 'Creating...' : 'Create parent account'),
                ),
              ],
            ),
    );
  }
}
