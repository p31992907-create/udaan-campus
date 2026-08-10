import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:udaan_campus/models/app_user.dart';
import 'package:udaan_campus/models/user_role.dart';
import 'package:udaan_campus/services/auth_provider.dart';
import 'package:udaan_campus/features/school/attendance/select_class_attendance_screen.dart';
import 'package:udaan_campus/features/school/attendance/qr_attendance_select_screen.dart';
import 'package:udaan_campus/features/school/attendance/qr_student_management_screen.dart';

class AttendanceHomeScreen extends StatelessWidget {
  const AttendanceHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Attendance Dashboard', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (user != null) _buildUserInfo(context, user),
            const SizedBox(height: 16),
            Expanded(child: _buildActions(context, user)),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context, AppUser user) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.displayName.isNotEmpty ? user.displayName : user.email, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Role: ${user.role}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
            if (user.assignedClassSections != null && user.assignedClassSections!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Assigned Classes', style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: user.assignedClassSections!
                    .map((entry) => Chip(label: Text(entry.toUpperCase())))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, AppUser? user) {
    final isManager = user != null && UserRole.isAtLeastManager(user.role);
    final isTeacher = user != null && UserRole.isTeacher(user.role);

    return ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.checklist_rtl),
          title: const Text('Mark Attendance'),
          subtitle: const Text('Select class, section and date to start attendance'),
          trailing: const Icon(Icons.arrow_forward),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SelectClassAttendanceScreen()));
          },
        ),
        if (isTeacher || isManager) ...[
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Attendance History'),
            subtitle: const Text('Review attendance records by student or class'),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              Navigator.pushNamed(context, '/attendance_history');
            },
          ),
          ListTile(
            leading: const Icon(Icons.qr_code_scanner),
            title: const Text('QR Attendance'),
            subtitle: const Text('Scan student QR codes to mark attendance'),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const QrAttendanceSelectScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('Monthly Report'),
            subtitle: const Text('View student attendance percentages for a month'),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              Navigator.pushNamed(context, '/attendance_monthly');
            },
          ),
        ],
        if (isManager) ...[
          ListTile(
            leading: const Icon(Icons.shield_moon),
            title: const Text('QR Student Management'),
            subtitle: const Text('Search students and manage QR tokens'),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const QrStudentManagementScreen()));
            },
          ),
        ],
        if (isManager || isTeacher) ...[
          ListTile(
            leading: const Icon(Icons.assessment),
            title: const Text('Class Attendance Report'),
            subtitle: const Text('View attendance summaries across all classes'),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              Navigator.pushNamed(context, '/attendance_report');
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_off),
            title: const Text('Absent Students'),
            subtitle: const Text('View absent students for any selected class and date'),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              Navigator.pushNamed(context, '/absent_students');
            },
          ),
        ],
      ],
    );
  }
}
