import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:udaan_campus/models/homework_submission_model.dart';
import 'package:udaan_campus/services/auth_provider.dart';
import 'package:udaan_campus/services/homework_service.dart';

class HomeworkReviewScreen extends StatefulWidget {
  const HomeworkReviewScreen({super.key, required this.submission});

  final HomeworkSubmissionModel submission;

  @override
  State<HomeworkReviewScreen> createState() => _HomeworkReviewScreenState();
}

class _HomeworkReviewScreenState extends State<HomeworkReviewScreen> {
  final HomeworkService _homeworkService = HomeworkService();
  final TextEditingController _remarkController = TextEditingController();
  String _status = 'REVIEWED';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _remarkController.text = widget.submission.teacherRemark ?? '';
  }

  Future<void> _saveReview() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    if (user == null) return;

    setState(() {
      _saving = true;
    });

    try {
      await _homeworkService.reviewSubmission(
        widget.submission,
        _status,
        _remarkController.text.trim(),
        user.uid,
        user.role,
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to save review.')));
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _remarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review Submission')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Student: ${widget.submission.studentName}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            InputDecorator(
              decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _status,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'REVIEWED', child: Text('Reviewed')),
                    DropdownMenuItem(value: 'NEEDS_REVISION', child: Text('Needs Revision')),
                    DropdownMenuItem(value: 'APPROVED', child: Text('Approved')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _status = value;
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _remarkController,
              minLines: 4,
              maxLines: 6,
              decoration: const InputDecoration(labelText: 'Teacher Remark', border: OutlineInputBorder()),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _saving ? null : _saveReview,
              child: _saving ? const CircularProgressIndicator() : const Text('Save Review'),
            ),
          ],
        ),
      ),
    );
  }
}
