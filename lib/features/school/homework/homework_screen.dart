import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:udaan_campus/models/app_user.dart';
import 'package:udaan_campus/models/homework_model.dart';
import 'package:udaan_campus/models/student.dart';
import 'package:udaan_campus/models/user_role.dart';
import 'package:udaan_campus/services/auth_provider.dart';
import 'package:udaan_campus/services/attendance_service.dart';
import 'package:udaan_campus/services/homework_service.dart';
import 'package:udaan_campus/features/school/homework/homework_details_screen.dart';
import 'package:udaan_campus/features/school/homework/create_homework_screen.dart';
import 'package:udaan_campus/utils/utils.dart';

class HomeworkScreen extends StatefulWidget {
  const HomeworkScreen({super.key});

  @override
  State<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen>
    with SingleTickerProviderStateMixin {
  final HomeworkService _homeworkService = HomeworkService();
  final AttendanceService _attendanceService = AttendanceService();

  late TabController _tabController;
  bool _loading = true;
  String? _selectedChildId;
  List<Student> _linkedChildren = [];
  List<HomeworkModel> _homework = [];
  List<String> _classSectionOptions = [];
  String? _selectedClassSection;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
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
        if (UserRole.isStudent(user.role)) {
          await _loadStudentHomework(user);
        } else if (UserRole.isParent(user.role)) {
          await _loadParentHomework(user);
        } else if (UserRole.isTeacher(user.role)) {
          await _loadTeacherHomework(user);
        } else {
          await _loadManagerHomework();
        }
    } catch (e) {
      setState(() {
        _error = 'Unable to load homework.';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _loadStudentHomework(AppUser user) async {
    if (user.studentClassId == null || user.studentSection == null) {
      throw Exception('Student class or section not available.');
    }
    _selectedClassSection = '${user.studentClassId}-${user.studentSection}';
    final homeworks = await _homeworkService.fetchPublishedHomeworkForClassSection(
      classId: user.studentClassId!,
      section: user.studentSection!,
    );
    setState(() {
      _homework = homeworks;
    });
  }

  Future<void> _loadParentHomework(AppUser user) async {
    final children = <Student>[];
    if (user.linkedChildren?.isNotEmpty ?? false) {
      children.addAll(await _attendanceService.getStudentsByIds(user.linkedChildren!));
    }
    if (children.isEmpty) {
      setState(() {
        _error = 'No linked children found.';
        _linkedChildren = [];
      });
      return;
    }
    setState(() {
      _linkedChildren = children;
      _selectedChildId = children.first.id;
    });
    await _loadSelectedChildHomework();
  }

  Future<void> _loadSelectedChildHomework() async {
    final selected = _linkedChildren.firstWhere((child) => child.id == _selectedChildId);
    final homeworks = await _homeworkService.fetchPublishedHomeworkForClassSection(
      classId: selected.classId ?? '',
      section: selected.section ?? '',
    );
    setState(() {
      _homework = homeworks;
    });
  }

  Future<void> _loadTeacherHomework(AppUser user) async {
    final homeworks = await _homeworkService.fetchHomeworkForTeacher(user.uid);
    final assigned = await _attendanceService.getAssignedClassSections(
      userUid: user.uid,
      role: user.role,
    );
    setState(() {
      _homework = homeworks;
      _classSectionOptions = assigned;
      if (_classSectionOptions.isNotEmpty && _selectedClassSection == null) {
        _selectedClassSection = _classSectionOptions.first;
      }
    });
  }

  Future<void> _loadManagerHomework() async {
    final homeworks = await _homeworkService.fetchAllHomework();
    setState(() {
      _homework = homeworks;
    });
  }

  List<HomeworkModel> _homeworkForTab(int index) {
    final now = DateTime.now();
    return _homework.where((homework) {
      final dueDate = homework.dueDate;
      final isOverdue = now.isAfter(dueDate) && homework.status != 'COMPLETED';
      switch (index) {
        case 0:
          return homework.assignedDate.year == now.year &&
              homework.assignedDate.month == now.month &&
              homework.assignedDate.day == now.day;
        case 1:
          return dueDate.isAfter(now) && !isOverdue;
        case 2:
          return homework.status == 'PUBLISHED' && dueDate.isAfter(now);
        case 3:
          return homework.status == 'COMPLETED';
        case 4:
          return isOverdue;
        default:
          return false;
      }
    }).toList();
  }

  String _statusBadge(HomeworkModel homework) {
    final now = DateTime.now();
    if (homework.status == 'CLOSED') return 'Closed';
    if (homework.status == 'DRAFT') return 'Draft';
    if (homework.status == 'COMPLETED') return 'Completed';
    if (now.isAfter(homework.dueDate)) return 'Overdue';
    return homework.status == 'PUBLISHED' ? 'Pending' : homework.status;
  }

  Color _statusColor(HomeworkModel homework) {
    final badge = _statusBadge(homework).toLowerCase();
    if (badge == 'overdue') return Colors.redAccent;
    if (badge == 'completed') return Colors.green;
    if (badge == 'draft') return Colors.grey;
    if (badge == 'urgent') return Colors.deepOrange;
    return Colors.blue;
  }

  Widget _buildSummaryCards() {
    final now = DateTime.now();
    final todayCount = _homeworkForTab(0).length;
    final overdueCount = _homeworkForTab(4).length;
    final completedCount = _homeworkForTab(3).length;
    final pendingCount = _homework.where((homework) {
      final dueDate = homework.dueDate;
      return homework.status == 'PUBLISHED' && dueDate.isAfter(now);
    }).length;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildMetricCard('Today', todayCount, Colors.blue),
        _buildMetricCard('Pending', pendingCount, Colors.orange),
        _buildMetricCard('Completed', completedCount, Colors.green),
        _buildMetricCard('Overdue', overdueCount, Colors.red),
      ],
    );
  }

  Widget _buildMetricCard(String label, int count, Color color) {
    return Card(
      elevation: 1,
      child: Container(
        width: MediaQuery.of(context).size.width > 600 ? 150 : double.infinity,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: color)),
            const SizedBox(height: 8),
            Text('$count', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeworkCard(HomeworkModel homework) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HomeworkDetailsScreen(homeworkId: homework.homeworkId),
            ),
          );
        },
        title: Text(homework.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${homework.subjectName} • ${homework.teacherName}'),
            const SizedBox(height: 4),
            Text('Assigned: ${DateTimeUtils.formatDate(homework.assignedDate)} • Due: ${DateTimeUtils.formatDate(homework.dueDate)}'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor(homework).withAlpha((0.16 * 255).round()),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_statusBadge(homework), style: TextStyle(color: _statusColor(homework), fontSize: 12)),
            ),
            const SizedBox(height: 8),
            Text(homework.priority, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Homework'),
        actions: [
            if (user != null && (UserRole.isTeacher(user.role) || UserRole.isAtLeastManager(user.role)))
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Create Homework',
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateHomeworkScreen()),
                );
                await _loadData();
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Pending'),
            Tab(text: 'Completed'),
            Tab(text: 'Overdue'),
          ],
          isScrollable: true,
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null) ...[
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 16),
                  ],
                  if (user != null && !(UserRole.isStudent(user.role) || UserRole.isParent(user.role)))
                    _buildSummaryCards(),
                  if (user != null && user.role == UserRole.parent && _linkedChildren.length > 1) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedChildId,
                      items: _linkedChildren
                          .map((child) => DropdownMenuItem(
                                value: child.id,
                                child: Text('${child.name} • ${child.classId}-${child.section}'),
                              ))
                          .toList(),
                      onChanged: (value) async {
                        if (value == null) return;
                        setState(() {
                          _selectedChildId = value;
                        });
                        await _loadSelectedChildHomework();
                      },
                      decoration: const InputDecoration(
                        labelText: 'Select Child',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: List.generate(5, (index) {
                        final list = _homeworkForTab(index);
                        if (list.isEmpty) {
                          return Center(
                            child: Text(index == 3
                                ? 'Great! All homework is completed.'
                                : 'No homework available.'),
                          );
                        }
                        return ListView.builder(
                          itemCount: list.length,
                          itemBuilder: (context, idx) => _buildHomeworkCard(list[idx]),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
