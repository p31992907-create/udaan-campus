import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:udaan_campus/models/homework_model.dart';
import 'package:udaan_campus/models/homework_submission_model.dart';
import 'package:udaan_campus/models/user_role.dart';
import 'package:udaan_campus/services/auth_provider.dart';
import 'package:udaan_campus/services/homework_service.dart';
import 'package:udaan_campus/features/school/homework/homework_review_screen.dart';
import 'package:udaan_campus/features/school/homework/homework_submission_screen.dart';
import 'package:udaan_campus/utils/utils.dart';
import 'package:url_launcher/url_launcher_string.dart';

class HomeworkDetailsScreen extends StatefulWidget {
  const HomeworkDetailsScreen({super.key, required this.homeworkId});

  final String homeworkId;

  @override
  State<HomeworkDetailsScreen> createState() => _HomeworkDetailsScreenState();
}

class _HomeworkDetailsScreenState extends State<HomeworkDetailsScreen> {
  final HomeworkService _homeworkService = HomeworkService();

  bool _loading = true;
  HomeworkModel? _homework;
  HomeworkSubmissionModel? _submission;
  List<HomeworkSubmissionModel> _submissions = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDetails());
  }

  Future<void> _loadDetails() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final homework = await _homeworkService.getHomeworkById(widget.homeworkId);
      if (homework == null) {
        if (!mounted) return;
        setState(() {
          _error = 'Homework not found.';
          _loading = false;
        });
        return;
      }
      if (!mounted) return;
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.user;
      if (user != null) {
        if (user.role == UserRole.student) {
          _submission = await _homeworkService.fetchSubmissionForStudent(homework.homeworkId, user.uid);
        }
        if (user.role == UserRole.teacher || user.role == UserRole.manager) {
          _submissions = await _homeworkService.fetchSubmissionsForHomework(homework.homeworkId);
        }
      }
      setState(() {
        _homework = homework;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Unable to load homework details.';
        _loading = false;
      });
    }
  }

  bool get _canSubmit {
    if (_homework == null) return false;
    return _homework!.allowSubmission && _homework!.status == 'PUBLISHED';
  }

  bool get _isOverdue {
    if (_homework == null) return false;
    return DateTime.now().isAfter(_homework!.dueDate) && _homework!.status != 'COMPLETED';
  }

  String _statusText(HomeworkModel homework) {
    if (homework.status == 'DRAFT') return 'Draft';
    if (homework.status == 'CLOSED') return 'Closed';
    if (homework.status == 'COMPLETED') return 'Completed';
    if (_isOverdue) return 'Overdue';
    return homework.status == 'PUBLISHED' ? 'Pending' : homework.status;
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Homework Details')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _homework == null
                  ? const Center(child: Text('Homework not found.'))
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: ListView(
                        children: [
                          Text(_homework!.title, style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 8),
                          Text('${_homework!.subjectName} • ${_homework!.teacherName}'),
                          const SizedBox(height: 12),
                          _buildDetailRow('Class', '${_homework!.className}-${_homework!.section}'),
                          _buildDetailRow('Assigned', DateTimeUtils.formatDate(_homework!.assignedDate)),
                          _buildDetailRow('Due', DateTimeUtils.formatDate(_homework!.dueDate)),
                          _buildDetailRow('Priority', _homework!.priority),
                          _buildDetailRow('Status', _statusText(_homework!)),
                          const SizedBox(height: 16),
                          Text(_homework!.description),
                          const SizedBox(height: 16),
                          if (_homework!.attachments.isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Attachments', style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                ..._homework!.attachments.map((attachment) => ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(attachment.fileName),
                                      subtitle: Text('${attachment.fileType.toUpperCase()} • ${(attachment.fileSize / 1024).toStringAsFixed(1)} KB'),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.open_in_new),
                                        onPressed: () async {
                                          final fileUrl = attachment.fileUrl;
                                          final canLaunch = fileUrl.isNotEmpty && await canLaunchUrlString(fileUrl);
                                          if (!context.mounted) return;
                                          if (canLaunch) {
                                            await launchUrlString(fileUrl);
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to open attachment.')));
                                          }
                                        },
                                      ),
                                    )),
                              ],
                            ),
                          const SizedBox(height: 16),
                          if (user != null && user.role == UserRole.student && _canSubmit) ...[
                            ElevatedButton(
                              onPressed: _submission != null
                                  ? null
                                  : () async {
                                      if (!mounted) return;
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => HomeworkSubmissionScreen(homework: _homework!),
                                        ),
                                      );
                                      if (!mounted) return;
                                      await _loadDetails();
                                    },
                              child: Text(_submission != null ? 'Already Submitted' : 'Submit Homework'),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _submission != null
                                  ? null
                                  : () async {
                                      if (_isOverdue && !_homework!.allowLateSubmission) {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Submission deadline has passed.')));
                                        return;
                                      }
                                      await _homeworkService.markHomeworkCompleted(
                                        _homework!,
                                        user.uid,
                                        user.displayName.isNotEmpty ? user.displayName : user.email,
                                      );
                                      if (!mounted) return;
                                      await _loadDetails();
                                    },
                              child: const Text('Mark as Completed'),
                            ),
                          ],
                          if (_submission != null) ...[
                            const SizedBox(height: 16),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Your Submission', style: TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    Text('Status: ${_submission!.status}'),
                                    if (_submission!.textResponse != null && _submission!.textResponse!.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text('Answer: ${_submission!.textResponse}'),
                                    ],
                                    if (_submission!.attachments.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      const Text('Attachments', style: TextStyle(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      ..._submission!.attachments.map((attachment) => ListTile(
                                            contentPadding: EdgeInsets.zero,
                                            title: Text(attachment.fileName),
                                            subtitle: Text('${attachment.fileType.toUpperCase()} • ${(attachment.fileSize / 1024).toStringAsFixed(1)} KB'),
                                            trailing: IconButton(
                                              icon: const Icon(Icons.open_in_new),
                                              onPressed: () async {
                                                final fileUrl = attachment.fileUrl;
                                                final canLaunch = fileUrl.isNotEmpty && await canLaunchUrlString(fileUrl);
                                                if (!context.mounted) return;
                                                if (canLaunch) {
                                                  await launchUrlString(fileUrl);
                                                } else {
                                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to open attachment.')));
                                                }
                                              },
                                            ),
                                          )),
                                    ],
                                    if (_submission!.teacherRemark != null) ...[
                                      const SizedBox(height: 8),
                                      Text('Teacher Remark: ${_submission!.teacherRemark}'),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                          if (user != null && (UserRole.isTeacher(user.role) || UserRole.isAtLeastManager(user.role)) && _submissions.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Text('Student Submissions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            ..._submissions.map((submission) => Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    title: Text(submission.studentName),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Status: ${submission.status}'),
                                        if (submission.teacherRemark != null)
                                          Text('Remark: ${submission.teacherRemark}'),
                                      ],
                                    ),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () async {
                                      if (!mounted) return;
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => HomeworkReviewScreen(submission: submission),
                                        ),
                                      );
                                      if (!mounted) return;
                                      await _loadDetails();
                                    },
                                  ),
                                )),
                          ],
                        ],
                      ),
                    ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}
