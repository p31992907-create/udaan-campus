import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:udaan_campus/models/qr_scan_result_model.dart';
import 'package:udaan_campus/services/auth_provider.dart';
import 'package:udaan_campus/services/qr_attendance_service.dart';
import 'package:udaan_campus/services/attendance_service.dart';
import 'package:udaan_campus/utils/utils.dart';

class QrAttendanceScannerScreen extends StatefulWidget {
  const QrAttendanceScannerScreen({
    super.key,
    required this.classId,
    required this.className,
    required this.section,
    required this.selectedDate,
  });

  final String classId;
  final String className;
  final String section;
  final DateTime selectedDate;

  @override
  State<QrAttendanceScannerScreen> createState() => _QrAttendanceScannerScreenState();
}

class _QrAttendanceScannerScreenState extends State<QrAttendanceScannerScreen> {
  final QrAttendanceService _qrAttendanceService = QrAttendanceService();
  final AttendanceService _attendanceService = AttendanceService();
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;
  String _message = 'Place the student QR code inside the frame.';
  QrScanResultModel? _lastResult;
  int _totalStudents = 0;
  int _scannedCount = 0;
  int _presentCount = 0;
  int _remainingCount = 0;
  Set<String> _scannedStudentIds = {};
  Timer? _resetTimer;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  @override
  void dispose() {
    _controller.dispose();
    _resetTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSummary() async {
    final students = await _attendanceService.getStudentsForClassSection(
      classId: widget.classId,
      section: widget.section,
    );
    final attendance = await _attendanceService.getAttendanceForDate(
      classId: widget.classId,
      section: widget.section,
      date: widget.selectedDate,
    );
    final markedIds = attendance.map((e) => e.studentId).toSet();
    setState(() {
      _totalStudents = students.length;
      _scannedStudentIds = markedIds;
      _presentCount = attendance.where((e) => e.status == 'present').length;
      _scannedCount = markedIds.length;
      _remainingCount = _totalStudents - _scannedCount;
    });
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcode = capture.barcodes.first;
    final raw = barcode.rawValue?.trim() ?? '';
    if (raw.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    if (user == null) {
      _showResult(QrScanResultModel(status: QrScanStatus.error, message: 'Authenticated user not found.'));
      return;
    }

    final result = await _qrAttendanceService.scanAndMarkAttendance(
      qrToken: raw,
      teacherUid: user.uid,
      teacherRole: user.role,
      classId: widget.classId,
      className: widget.className,
      section: widget.section,
      date: widget.selectedDate,
    );

    _showResult(result);
  }

  void _showResult(QrScanResultModel result) {
    setState(() {
      _lastResult = result;
      _message = result.message;
      _isProcessing = false;
    });
    if (result.status == QrScanStatus.success && result.attendance != null) {
      _scannedStudentIds.add(result.student!.id);
      _scannedCount = _scannedStudentIds.length;
      _presentCount += 1;
      _remainingCount = _totalStudents - _scannedCount;
    }

    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _message = 'Place the student QR code inside the frame.';
          _lastResult = null;
        });
      }
    });
  }

  Future<void> _toggleTorch() async {
    await _controller.toggleTorch();
    setState(() {});
  }

  Future<void> _completeAttendance() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    if (user == null) return;
    final students = await _attendanceService.getStudentsForClassSection(
      classId: widget.classId,
      section: widget.section,
    );
    await _qrAttendanceService.markRemainingAbsent(
      classId: widget.classId,
      className: widget.className,
      section: widget.section,
      date: widget.selectedDate,
      markedBy: user.uid,
      markedByRole: user.role,
      students: students,
      alreadyMarkedStudentIds: _scannedStudentIds,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Remaining students marked absent.')));
      await _loadSummary();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Attendance'),
        actions: [
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: _controller,
            builder: (context, state, child) {
              final enabled = state.torchState == TorchState.on;
              return IconButton(
                icon: Icon(enabled ? Icons.flash_on : Icons.flash_off),
                onPressed: _toggleTorch,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Class: ${widget.className}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Section: ${widget.section}', style: const TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 4),
                Text('Date: ${DateTimeUtils.formatDate(widget.selectedDate)}', style: const TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _statusTile('Total', _totalStudents.toString()),
                    _statusTile('Scanned', _scannedCount.toString()),
                    _statusTile('Present', _presentCount.toString()),
                    _statusTile('Remaining', _remainingCount.toString()),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: _handleBarcode,
                ),
                Center(
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white70, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            color: Colors.black87,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(_message, style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
                if (_lastResult != null) ...[
                  const SizedBox(height: 12),
                  _buildResultCard(_lastResult!),
                ],
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _completeAttendance,
                  child: const Text('COMPLETE ATTENDANCE'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusTile(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }

  Widget _buildResultCard(QrScanResultModel result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(result.message, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (result.status == QrScanStatus.success && result.student != null && result.attendance != null) ...[
              const SizedBox(height: 12),
              Text('Student: ${result.student!.name}'),
              Text('Class: ${result.student!.classId}-${result.student!.section}'),
              Text('Status: PRESENT'),
              Text('Time: ${DateTimeUtils.formatTime(result.attendance!.timestamp)}'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _lastResult = null;
                    _message = 'Place the student QR code inside the frame.';
                  });
                },
                child: const Text('SCAN NEXT STUDENT'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
