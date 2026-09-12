import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:udaan_campus/models/student.dart';
import 'package:udaan_campus/services/attendance_service.dart';
import 'package:udaan_campus/services/auth_provider.dart';
import 'package:udaan_campus/features/school/student/student_qr_verification_screen.dart';
import 'package:udaan_campus/models/user_role.dart';

class StudentPortalScreen extends StatefulWidget {
  const StudentPortalScreen({super.key});

  @override
  State<StudentPortalScreen> createState() => _StudentPortalScreenState();
}

class _StudentPortalScreenState extends State<StudentPortalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _rollController = TextEditingController();
  final _mobileController = TextEditingController();
  final _attendanceService = AttendanceService();
  Student? _student;
  List<Student> _linkedChildren = [];
  bool _verified = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStudent());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rollController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _loadStudent() async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) {
      setState(() {
        _loading = false;
        _error = 'Unable to identify the signed-in student.';
      });
      return;
    }

    try {
      Student? student;
      if (user.role == UserRole.parent &&
          (user.linkedChildren?.isNotEmpty ?? false)) {
        _linkedChildren =
            await _attendanceService.getStudentsByIds(user.linkedChildren!);
        student = _linkedChildren.isEmpty ? null : _linkedChildren.first;
      } else {
        student = await _attendanceService.getStudentByEmail(user.email);
      }
      if (!mounted) return;
      setState(() {
        _student = student;
        _loading = false;
        _error = student == null
            ? 'Student profile is not linked to this account. Ask the school manager to add your email.'
            : null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load student profile.';
      });
    }

  }

  void _selectChild(String? studentId) {
    if (studentId == null) return;
    final selected = _linkedChildren.firstWhere((child) => child.id == studentId);
    setState(() {
      _student = selected;
      _verified = false;
      _error = null;
    });
  }

  Future<void> _scanStudentCard() async {
    final student = await Navigator.push<Student>(
      context,
      MaterialPageRoute(
        builder: (_) => const StudentQrVerificationScreen(),
      ),
    );
    if (!mounted || student == null) return;
    setState(() {
      _student = student;
      _verified = true;
      _error = null;
    });
  }

  void _verify() {
    if (!_formKey.currentState!.validate() || _student == null) return;
    final mobile = _student!.phoneNumber ?? '';
    final matches = _nameController.text.trim().toLowerCase() ==
            _student!.name.trim().toLowerCase() &&
        _rollController.text.trim().toLowerCase() ==
            _student!.rollNumber.trim().toLowerCase() &&
        (mobile.isEmpty ||
            _mobileController.text.trim() == mobile.trim());
    setState(() {
      _verified = matches;
      _error = matches
          ? null
          : 'Details do not match the verified school record.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Portal')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _student == null
              ? Center(child: Text(_error ?? 'Student profile unavailable.'))
              : _verified
                  ? _buildVerifiedPortal()
                  : _buildVerificationForm(),
    );
  }

  Widget _buildVerificationForm() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Icon(Icons.verified_user_outlined, size: 56),
        const SizedBox(height: 12),
        Text(
          'Verify your student details',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter the details exactly as recorded by the school to open your live student updates.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Student name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _rollController,
                decoration: const InputDecoration(
                  labelText: 'Roll number',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter roll number'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Mobile number',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter mobile number'
                    : null,
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _verify,
                icon: const Icon(Icons.lock_open),
                label: const Text('Verify and continue'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _scanStudentCard,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan student ID card QR'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVerifiedPortal() {
    final student = _student!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.verified)),
            title: Text(student.name),
            subtitle: Text(
              'Roll no. ${student.rollNumber}\n'
              'Mobile: ${student.phoneNumber ?? 'Not added'}\n'
              'Class: ${student.classId ?? '-'}  |  Section: ${student.section ?? '-'}',
            ),
            isThreeLine: true,
          ),
        ),
        if (_linkedChildren.length > 1) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: student.id,
            decoration: const InputDecoration(
              labelText: 'Select child',
              border: OutlineInputBorder(),
            ),
            items: _linkedChildren
                .map((child) => DropdownMenuItem(
                      value: child.id,
                      child: Text(child.name),
                    ))
                .toList(),
            onChanged: _selectChild,
          ),
        ],
        const SizedBox(height: 12),
        _actionTile(
          icon: Icons.assignment,
          title: 'Homework',
          subtitle: 'Assignments, due dates and submissions',
          route: '/homework',
        ),
        _actionTile(
          icon: Icons.assessment,
          title: 'Exam results and marksheet',
          subtitle: 'Marks, grades and final class position',
          route: '/exam_results',
        ),
        const SizedBox(height: 8),
        _buildLiveNotices(),
        const SizedBox(height: 12),
        _buildLiveTimings(student),
      ],
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String route,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.pushNamed(context, route),
      ),
    );
  }

  Widget _buildLiveNotices() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('notices')
          .where('status', isEqualTo: 'PUBLISHED')
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = [...(snapshot.data?.docs ?? [])]
          ..sort((a, b) {
            final aDate = a.data()['publishedAt'];
            final bDate = b.data()['publishedAt'];
            if (aDate is Timestamp && bDate is Timestamp) {
              return bDate.compareTo(aDate);
            }
            return 0;
          });
        return Card(
          child: ExpansionTile(
            leading: const Icon(Icons.notifications_active),
            title: const Text('Live school notices'),
            subtitle: Text('${docs.length} published updates'),
            children: docs.isEmpty
                ? [const ListTile(title: Text('No notices published yet.'))]
                : docs
                    .map((doc) => ListTile(
                          title: Text(doc.data()['title']?.toString() ?? 'Notice'),
                          subtitle: Text(doc.data()['message']?.toString() ?? ''),
                        ))
                    .toList(),
          ),
        );
      },
    );
  }

  Widget _buildLiveTimings(Student student) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('school_timings')
          .where('status', isEqualTo: 'PUBLISHED')
          .snapshots(),
      builder: (context, snapshot) {
        final docs = (snapshot.data?.docs ?? []).where((doc) {
          final data = doc.data();
          return data['classId'] == student.classId &&
              data['section'] == student.section;
        }).toList();
        return Card(
          child: ExpansionTile(
            leading: const Icon(Icons.schedule),
            title: const Text('Class and school timing'),
            children: docs.isEmpty
                ? [const ListTile(title: Text('Timing has not been published yet.'))]
                : docs
                    .map((doc) => ListTile(
                          title: Text(doc.data()['title']?.toString() ?? 'Timing'),
                          subtitle: Text(doc.data()['time']?.toString() ?? ''),
                        ))
                    .toList(),
          ),
        );
      },
    );
  }
}
