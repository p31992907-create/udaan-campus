import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:udaan_campus/models/student.dart';
import 'package:udaan_campus/models/student_qr_model.dart';

class QrService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random.secure();

  CollectionReference<Map<String, dynamic>> get students => _firestore.collection('students');
  CollectionReference<Map<String, dynamic>> get qrTokens => _firestore.collection('student_qr_tokens');

  static const String tokenPrefix = 'UED-STU-';
  static const int tokenLength = 8;
  static const String _chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

  Future<String> generateQrToken() async {
    String token;
    do {
      token = '$tokenPrefix${List.generate(tokenLength, (_) => _chars[_random.nextInt(_chars.length)]).join()}';
    } while (await tokenExists(token));
    return token;
  }

  Future<bool> tokenExists(String token) async {
    final snapshot = await qrTokens.doc(token).get();
    return snapshot.exists;
  }

  Future<Student?> getStudentById(String studentId) async {
    final snapshot = await students.doc(studentId).get();
    if (!snapshot.exists || snapshot.data() == null) return null;
    final json = Map<String, dynamic>.from(snapshot.data()!);
    json['id'] = snapshot.id;
    return Student.fromJson(json);
  }

  Future<Student?> getStudentByQrToken(String qrToken) async {
    final tokenSnapshot = await qrTokens.doc(qrToken).get();
    if (!tokenSnapshot.exists || tokenSnapshot.data() == null) return null;
    final tokenData = tokenSnapshot.data()!;
    if (tokenData['active'] != true) return null;
    final studentId = tokenData['studentId'] as String?;
    if (studentId == null || studentId.isEmpty) return null;
    return getStudentById(studentId);
  }

  Future<StudentQrModel?> getStudentQrForStudent(String studentId) async {
    final snapshot = await students.doc(studentId).get();
    if (!snapshot.exists || snapshot.data() == null) return null;
    final data = Map<String, dynamic>.from(snapshot.data()!);
    final qrToken = data['qrToken'] as String?;
    if (qrToken == null || qrToken.isEmpty) {
      return StudentQrModel(
        studentId: studentId,
        qrToken: null,
        qrVersion: 0,
        qrActive: false,
        qrCreatedAt: null,
        qrUpdatedAt: null,
        qrRegeneratedBy: null,
      );
    }
    final tokenSnapshot = await qrTokens.doc(qrToken).get();
    if (!tokenSnapshot.exists || tokenSnapshot.data() == null) {
      return StudentQrModel(
        studentId: studentId,
        qrToken: qrToken,
        qrVersion: data['qrVersion'] is int ? data['qrVersion'] as int : int.tryParse(data['qrVersion']?.toString() ?? '') ?? 0,
        qrActive: data['qrActive'] == true,
        qrCreatedAt: data['qrCreatedAt'] is Timestamp ? (data['qrCreatedAt'] as Timestamp).toDate() : null,
        qrUpdatedAt: data['qrUpdatedAt'] is Timestamp ? (data['qrUpdatedAt'] as Timestamp).toDate() : null,
        qrRegeneratedBy: data['qrRegeneratedBy'] as String?,
      );
    }
    return StudentQrModel.fromJson(tokenSnapshot.data()!..['studentId'] = studentId);
  }

  Future<String> createStudentQrToken({
    required String studentId,
    required String performedBy,
  }) async {
    final studentSnapshot = await students.doc(studentId).get();
    if (!studentSnapshot.exists || studentSnapshot.data() == null) {
      throw StateError('Student not found');
    }

    final studentData = studentSnapshot.data()!;
    final oldToken = studentData['qrToken'] as String?;
    final version = (studentData['qrVersion'] is int
            ? studentData['qrVersion'] as int
            : int.tryParse(studentData['qrVersion']?.toString() ?? '') ?? 0) +
        1;
    final token = await generateQrToken();
    final batch = _firestore.batch();

    if (oldToken != null && oldToken.isNotEmpty) {
      batch.set(
        qrTokens.doc(oldToken),
        {
          'active': false,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': performedBy,
        },
        SetOptions(merge: true),
      );
    }

    batch.set(
      qrTokens.doc(token),
      {
        'qrToken': token,
        'studentId': studentId,
        'active': true,
        'qrVersion': version,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdBy': performedBy,
        'updatedBy': performedBy,
      },
    );

    batch.set(
      students.doc(studentId),
      {
        'qrToken': token,
        'qrVersion': version,
        'qrActive': true,
        'qrCreatedAt': FieldValue.serverTimestamp(),
        'qrUpdatedAt': FieldValue.serverTimestamp(),
        'qrRegeneratedBy': performedBy,
      },
      SetOptions(merge: true),
    );

    await batch.commit();
    return token;
  }

  Future<String> regenerateStudentQrToken({
    required String studentId,
    required String performedBy,
  }) async {
    return createStudentQrToken(studentId: studentId, performedBy: performedBy);
  }

  Future<String?> ensureStudentQrToken({
    required String studentId,
    required String performedBy,
  }) async {
    final snapshot = await students.doc(studentId).get();
    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }
    final data = snapshot.data()!;
    final existing = data['qrToken'] as String?;
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    return createStudentQrToken(studentId: studentId, performedBy: performedBy);
  }
}
