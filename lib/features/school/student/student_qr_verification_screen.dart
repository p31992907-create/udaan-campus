import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:udaan_campus/models/student.dart';
import 'package:udaan_campus/services/qr_service.dart';

class StudentQrVerificationScreen extends StatefulWidget {
  const StudentQrVerificationScreen({super.key});

  @override
  State<StudentQrVerificationScreen> createState() =>
      _StudentQrVerificationScreenState();
}

class _StudentQrVerificationScreenState
    extends State<StudentQrVerificationScreen> {
  final MobileScannerController _controller = MobileScannerController();
  final QrService _qrService = QrService();
  bool _processing = false;
  String? _message;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _verify(BarcodeCapture capture) async {
    if (_processing) return;
    final value = capture.barcodes.isEmpty
        ? null
        : capture.barcodes.first.rawValue?.trim();
    if (value == null || value.isEmpty) return;
    setState(() {
      _processing = true;
      _message = null;
    });
    try {
      final student = await _qrService.getStudentByQrToken(value);
      if (!mounted) return;
      if (student == null) {
        setState(() {
          _processing = false;
          _message = 'This student card is invalid or inactive.';
        });
        return;
      }
      await _controller.stop();
      if (!mounted) return;
      Navigator.pop<Student>(context, student);
    } catch (_) {
      if (mounted) {
        setState(() {
          _processing = false;
          _message = 'Unable to verify this student card.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Student ID Card')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _verify),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 32,
            child: Card(
              color: Colors.black87,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _message ?? 'Scan the permanent QR on the student ID card.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
          if (_processing)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
