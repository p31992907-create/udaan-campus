import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:udaan_campus/models/user_role.dart';
import 'package:udaan_campus/services/auth_provider.dart';
import 'package:udaan_campus/services/homework_storage_service.dart';

class ExamPapersScreen extends StatefulWidget {
  const ExamPapersScreen({super.key});

  @override
  State<ExamPapersScreen> createState() => _ExamPapersScreenState();
}

class _ExamPapersScreenState extends State<ExamPapersScreen> {
  final _storage = HomeworkStorageService();
  final _papers = FirebaseFirestore.instance.collection('exam_papers');
  bool _uploading = false;

  Future<void> _uploadPaper() async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null ||
        !(user.role == UserRole.superManager || user.role == UserRole.teacher)) {
      return;
    }
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result.isEmpty || result.first.path == null) return;
    final selected = result.first;
    final file = File(selected.path!);
    if (file.lengthSync() > 20 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF must be 20 MB or smaller.')),
        );
      }
      return;
    }
    setState(() => _uploading = true);
    try {
      final doc = _papers.doc();
      final path = 'exam_papers/${user.uid}/${doc.id}.pdf';
      final url = await _storage.uploadHomeworkAttachment(
        storagePath: path,
        file: file,
      );
      await doc.set({
        'paperId': doc.id,
        'fileName': selected.name,
        'downloadUrl': url,
        'storagePath': path,
        'uploadedBy': user.uid,
        'uploadedByRole': user.role,
        'ocrStatus': 'REVIEW_REQUIRED',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paper uploaded. OCR draft requires review before saving marks.'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to upload paper PDF.')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final canUpload =
        user != null && (user.role == UserRole.superManager || user.role == UserRole.teacher);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Papers'),
        actions: [
          if (canUpload)
            IconButton(
              onPressed: _uploading ? null : _uploadPaper,
              icon: _uploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file),
              tooltip: 'Upload PDF paper',
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _papers.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Unable to load exam papers.'));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No exam papers uploaded.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final status = data['ocrStatus'] ?? 'REVIEW_REQUIRED';
              return ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: Text(data['fileName'] ?? 'Exam paper'),
                subtitle: Text('OCR: $status'),
                trailing: IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () {
                    final url = data['downloadUrl'] as String?;
                    if (url != null) launchUrlString(url);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
