import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:udaan_campus/models/student.dart';
import 'package:udaan_campus/services/qr_service.dart';
import 'package:udaan_campus/services/auth_provider.dart';
import 'package:udaan_campus/models/user_role.dart';

class StudentQrScreen extends StatefulWidget {
  const StudentQrScreen({super.key, required this.studentId});

  final String studentId;

  @override
  State<StudentQrScreen> createState() => _StudentQrScreenState();
}

class _StudentQrScreenState extends State<StudentQrScreen> {
  final QrService _qrService = QrService();
  Student? _student;
  String? _qrToken;
  bool _loading = true;
  bool _regenerating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStudentQr();
  }

  Future<void> _loadStudentQr() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final student = await _qrService.getStudentById(widget.studentId);
      if (student == null) {
        setState(() {
          _error = 'Student not found.';
          _loading = false;
        });
        return;
      }
      final token = student.qrToken;
      setState(() {
        _student = student;
        _qrToken = token;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Unable to load student QR details.';
        _loading = false;
      });
    }
  }

  Future<void> _regenerateQr() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    if (user == null || !UserRole.isAtLeastManager(user.role)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Only managers can regenerate QR tokens.')));
      return;
    }

    setState(() {
      _regenerating = true;
      _error = null;
    });

    try {
      final token = await _qrService.regenerateStudentQrToken(
        studentId: widget.studentId,
        performedBy: user.uid,
      );
      setState(() {
        _qrToken = token;
        _regenerating = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('QR token regenerated successfully.')));
      }
    } catch (e) {
      setState(() {
        _error = 'Unable to regenerate QR token.';
        _regenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student QR Card')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                : _student == null
                    ? const Center(child: Text('Student data unavailable.'))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Center(
                                    child: CircleAvatar(
                                      radius: 36,
                                      backgroundImage: _student!.profileImage != null ? NetworkImage(_student!.profileImage!) : null,
                                      child: _student!.profileImage == null ? const Icon(Icons.person, size: 36) : null,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Center(child: Text(_student!.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
                                  const SizedBox(height: 8),
                                  Center(child: Text('Class: ${_student!.classId ?? 'N/A'}', style: const TextStyle(fontSize: 16))),
                                  const SizedBox(height: 4),
                                  Center(child: Text('Section: ${_student!.section ?? 'N/A'}', style: const TextStyle(fontSize: 16))),
                                  const SizedBox(height: 4),
                                  Center(child: Text('Roll No: ${_student!.rollNumber}', style: const TextStyle(fontSize: 16))),
                                  const SizedBox(height: 12),
                                  const Divider(),
                                  const SizedBox(height: 12),
                                  Text('Student ID:', style: Theme.of(context).textTheme.labelMedium),
                                  const SizedBox(height: 4),
                                  Text(_student!.id, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 20),
                                  Center(
                                    child: _qrToken != null
                                        ? QrImageView(
                                            data: _qrToken!,
                                            version: QrVersions.auto,
                                            size: 200,
                                            errorStateBuilder: (context, err) => const Center(child: Text('Unable to render QR.')),
                                          )
                                        : const Text('QR token unavailable', textAlign: TextAlign.center),
                                  ),
                                  const SizedBox(height: 20),
                                  if (_qrToken != null)
                                    Center(child: SelectableText(_qrToken!, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _qrToken == null ? null : () {},
                            child: const Text('Show QR'),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _regenerating ? null : _regenerateQr,
                            child: _regenerating
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Refresh QR'),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _qrToken == null ? null : () {},
                            child: const Text('Share QR'),
                          ),
                        ],
                      ),
      ),
    );
  }
}
