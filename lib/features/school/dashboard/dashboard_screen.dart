import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:udaan_campus/models/user_role.dart';
import 'package:udaan_campus/services/auth_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    switch (user.role) {
      case UserRole.superManager:
        return const ManagerDashboard();
      case UserRole.manager:
        return const ManagerDashboard();
      case UserRole.teacher:
        return const TeacherDashboard();
      case UserRole.parent:
        return const ParentDashboard();
      case UserRole.student:
      default:
        return const StudentDashboard();
    }
  }
}

class DashboardShell extends StatelessWidget {
  const DashboardShell({
    super.key,
    required this.title,
    required this.description,
    required this.children,
  });

  final String title;
  final String description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: auth.signOut,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            if (user != null)
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(user.displayName.isNotEmpty
                        ? user.displayName[0].toUpperCase()
                        : user.role[0].toUpperCase()),
                  ),
                  title: Text(user.displayName.isNotEmpty ? user.displayName : user.email),
                  subtitle: Text('Role: ${user.role}'),
                ),
              ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: MediaQuery.of(context).size.width > 700 ? 3 : 1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 3,
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardActionCard extends StatelessWidget {
  const DashboardActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Theme.of(context).colorScheme.primary.withAlpha((0.12 * 255).round()),
                child: Icon(icon, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700])),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class ManagerDashboard extends StatelessWidget {
  const ManagerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      title: 'Manager Panel',
      description: 'Manage school operations, users, and academic resources.',
      children: [
        DashboardActionCard(
          icon: Icons.people,
          title: 'User Management',
          subtitle: 'Add or update teachers, parents and students.',
        ),
        DashboardActionCard(
          icon: Icons.class_,
          title: 'Classes & Sections',
          subtitle: 'Create classes, assign teachers and review schedules.',
        ),
        DashboardActionCard(
          icon: Icons.event_available,
          title: 'Attendance',
          subtitle: 'Monitor attendance across the school.',
          onTap: () => Navigator.pushNamed(context, '/attendance_home'),
        ),
        DashboardActionCard(
          icon: Icons.assignment,
          title: 'Homework',
          subtitle: 'Track homework assignments and deadlines.',
          onTap: () => Navigator.pushNamed(context, '/homework'),
        ),
        DashboardActionCard(
          icon: Icons.notifications,
          title: 'Announcements',
          subtitle: 'Send school-wide notices and alerts.',
        ),
        DashboardActionCard(
          icon: Icons.analytics,
          title: 'Reports',
          subtitle: 'Review performance, logs, and audit activities.',
          onTap: () => Navigator.pushNamed(context, '/exam_results'),
        ),
      ],
    );
  }
}

class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      title: 'Teacher Panel',
      description: 'Manage classes, attendance, homework, and student progress.',
      children: [
        DashboardActionCard(
          icon: Icons.check_box,
          title: 'Attendance',
          subtitle: 'Mark attendance and review class trends.',
          onTap: () => Navigator.pushNamed(context, '/attendance_home'),
        ),
        DashboardActionCard(
          icon: Icons.assignment_turned_in,
          title: 'Homework',
          subtitle: 'Create assignments and track submissions.',
          onTap: () => Navigator.pushNamed(context, '/homework'),
        ),
        DashboardActionCard(
          icon: Icons.school,
          title: 'Assessments',
          subtitle: 'Publish tests and record student scores.',
          onTap: () => Navigator.pushNamed(context, '/exam_management'),
        ),
        DashboardActionCard(
          icon: Icons.message,
          title: 'Messages',
          subtitle: 'Communicate with students and parents.',
        ),
        DashboardActionCard(
          icon: Icons.calendar_today,
          title: 'Timetable',
          subtitle: 'View your daily schedule.',
        ),
      ],
    );
  }
}

class ParentDashboard extends StatelessWidget {
  const ParentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      title: 'Parent Portal',
      description: 'Follow your child’s attendance, homework, and school announcements.',
      children: [
        const DashboardActionCard(
          icon: Icons.family_restroom,
          title: 'Child Attendance',
          subtitle: 'Monitor daily attendance and trends.',
        ),
        DashboardActionCard(
          icon: Icons.book,
          title: 'Homework Updates',
          subtitle: 'See assignments and deadlines.',
          onTap: () => Navigator.pushNamed(context, '/homework'),
        ),
        DashboardActionCard(
          icon: Icons.grade,
          title: 'Academic Progress',
          subtitle: 'Review test results and grades.',
          onTap: () => Navigator.pushNamed(context, '/exam_results'),
        ),
        const DashboardActionCard(
          icon: Icons.notifications_active,
          title: 'Notifications',
          subtitle: 'Receive school announcements and alerts.',
        ),
      ],
    );
  }
}

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      title: 'Student Hub',
      description: 'Access your schedule, homework, results, and school updates.',
      children: [
        const DashboardActionCard(
          icon: Icons.schedule,
          title: 'Class Schedule',
          subtitle: 'View today’s classes and timings.',
        ),
        DashboardActionCard(
          icon: Icons.assignment,
          title: 'Homework',
          subtitle: 'Track assignments and submission status.',
          onTap: () => Navigator.pushNamed(context, '/homework'),
        ),
        DashboardActionCard(
          icon: Icons.assessment,
          title: 'Results',
          subtitle: 'See test scores and academic feedback.',
          onTap: () => Navigator.pushNamed(context, '/exam_results'),
        ),
        const DashboardActionCard(
          icon: Icons.notifications,
          title: 'Announcements',
          subtitle: 'Stay updated with school news.',
        ),
      ],
    );
  }
}
