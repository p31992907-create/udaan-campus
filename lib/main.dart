import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_provider.dart';
import 'services/firebase_service.dart';
import 'features/school/attendance/attendance_home_screen.dart';
import 'features/school/attendance/attendance_history_screen.dart';
import 'features/school/attendance/student_attendance_history_screen.dart';
import 'features/school/attendance/class_attendance_report_screen.dart';
import 'features/school/attendance/monthly_attendance_screen.dart';
import 'features/school/attendance/absent_students_screen.dart';
import 'features/school/exams/test_management_screen.dart';
import 'features/school/exams/exam_results_screen.dart';
import 'features/school/homework/homework_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initialize();
  runApp(const UdaanCampusApp());
}

class UdaanCampusApp extends StatelessWidget {
  const UdaanCampusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const _UdaanAppRouter(),
    );
  }
}

class _UdaanAppRouter extends StatelessWidget {
  const _UdaanAppRouter();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        return MaterialApp(
          title: 'Udaan Campus',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
          ),
          themeMode: ThemeMode.system,
          home: auth.isLoading
              ? const Scaffold(body: Center(child: CircularProgressIndicator()))
              : auth.isAuthenticated
                  ? const HomeScreen()
                  : const LoginScreen(),
          routes: {
            '/login': (context) => const LoginScreen(),
            '/home': (context) => const HomeScreen(),
            '/attendance_home': (context) => const AttendanceHomeScreen(),
            '/attendance_history': (context) => const AttendanceHistoryScreen(),
            '/student_attendance_history': (context) => const StudentAttendanceHistoryScreen(),
            '/attendance_report': (context) => const ClassAttendanceReportScreen(),
            '/attendance_monthly': (context) => const MonthlyAttendanceScreen(),
            '/absent_students': (context) => const AbsentStudentsScreen(),
            '/exam_management': (context) => const TestManagementScreen(),
            '/exam_results': (context) => const ExamResultsScreen(),
            '/homework': (context) => const HomeworkScreen(),
          },
        );
      },
    );
  }
}
