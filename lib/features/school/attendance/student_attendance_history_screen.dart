import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:udaan_campus/models/attendance_model.dart';
import 'package:udaan_campus/models/student.dart';
import 'package:udaan_campus/services/attendance_service.dart';
import 'package:udaan_campus/services/auth_provider.dart';
import 'package:udaan_campus/utils/utils.dart';

class StudentAttendanceHistoryScreen extends StatefulWidget {
  const StudentAttendanceHistoryScreen({super.key});

  @override
  State<StudentAttendanceHistoryScreen> createState() => _StudentAttendanceHistoryScreenState();
}

class _StudentAttendanceHistoryScreenState extends State<StudentAttendanceHistoryScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _loading = true;
  String? _error;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  List<Student> _children = [];
  Student? _selectedStudent;
  List<AttendanceModel> _records = [];
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    if (user == null) {
      setState(() {
        _error = 'Unable to determine user role.';
        _loading = false;
      });
      return;
    }

    try {
      if (user.role == 'student') {
        final studentDoc = await _firestore.collection('students').doc(user.uid).get();
        if (studentDoc.exists) {
          final studentData = studentDoc.data();
          if (studentData != null) {
            final student = Student.fromJson({...studentData, 'id': studentDoc.id});
            setState(() {
              _children = [student];
              _selectedStudent = student;
              _loading = false;
            });
          } else {
            setState(() {
              _error = 'Student data is unavailable.';
              _loading = false;
            });
          }
        } else {
          setState(() {
            _error = 'Student record not found.';
            _loading = false;
          });
        }
      } else if (user.role == 'parent') {
        final childIds = user.linkedChildren ?? [];
        if (childIds.isEmpty) {
          setState(() {
            _error = 'No linked child records found.';
            _loading = false;
          });
          return;
        }
        final query = await _firestore.collection('students').where(FieldPath.documentId, whereIn: childIds).get();
        final children = query.docs
            .map((doc) => Student.fromJson({...doc.data(), 'id': doc.id}))
            .toList();
        setState(() {
          _children = children;
          if (children.isNotEmpty) {
            _selectedStudent = children.first;
          }
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'This screen is for students and parents only.';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Unable to load student attendance records.';
        _loading = false;
      });
    }
  }

  Future<void> _searchHistory() async {
    if (_selectedStudent == null) {
      return;
    }
    setState(() {
      _searching = true;
      _error = null;
      _records = [];
    });

    try {
      final selectedStudent = _selectedStudent;
      if (selectedStudent == null) {
        setState(() {
          _error = 'Select a student first.';
          _searching = false;
        });
        return;
      }
      final records = await _attendanceService.getStudentAttendanceHistory(
        studentId: selectedStudent.id,
        startDate: _startDate,
        endDate: _endDate,
      );
      setState(() {
        _records = records;
        _searching = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Unable to load attendance history.';
        _searching = false;
      });
    }
  }

  Future<void> _selectDateRange() async {
    final picker = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picker != null) {
      setState(() {
        _startDate = picker.start;
        _endDate = picker.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Attendance History')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_children.length > 1)
                        DropdownButtonFormField<Student>(
                          initialValue: _selectedStudent,
                          items: _children
                              .map((student) => DropdownMenuItem(value: student, child: Text(student.name)))
                              .toList(),
                          onChanged: (value) => setState(() => _selectedStudent = value),
                          decoration: const InputDecoration(labelText: 'Select Student', border: OutlineInputBorder()),
                        ),
                      if (_children.length > 1) const SizedBox(height: 12),
                      InkWell(
                        onTap: _selectDateRange,
                        child: InputDecorator(
                          decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Date Range'),
                          child: Text('${DateTimeUtils.formatDate(_startDate)} - ${DateTimeUtils.formatDate(_endDate)}'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _searching ? null : _searchHistory, child: const Text('Load History')),
                      if (_searching) const Expanded(child: Center(child: CircularProgressIndicator())),
                      if (!_searching && _records.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Expanded(child: _buildRecordList()),
                      ],
                      if (!_searching && _records.isEmpty && _error == null)
                        const Expanded(child: Center(child: Text('No attendance records found.'))),
                    ],
                  ),
      ),
    );
  }

  Widget _buildRecordList() {
    return ListView.separated(
      itemCount: _records.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final record = _records[index];
        return ListTile(
          title: Text(DateTimeUtils.formatDate(record.date)),
          subtitle: Text('${record.status.toUpperCase()} • ${record.method}'),
          trailing: Text(record.markedByRole.toUpperCase()),
        );
      },
    );
  }
}
