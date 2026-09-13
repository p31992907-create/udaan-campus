import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:udaan_campus/models/audit_log_model.dart';
import 'package:udaan_campus/models/test_model.dart';
import 'package:udaan_campus/models/test_result_model.dart';
import 'package:udaan_campus/services/audit_service.dart';

class ExamService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuditService _auditService = AuditService();

  CollectionReference<Map<String, dynamic>> get tests =>
      _firestore.collection('tests');
  CollectionReference<Map<String, dynamic>> get testResults =>
      _firestore.collection('test_results');
  CollectionReference<Map<String, dynamic>> get notifications =>
      _firestore.collection('notifications');

  String calculateGrade(double marksObtained, int maxMarks) {
    if (maxMarks <= 0) return 'N/A';
    final percentage = (marksObtained / maxMarks) * 100;
    if (percentage >= 95) return 'A+';
    if (percentage >= 90) return 'A';
    if (percentage >= 80) return 'B+';
    if (percentage >= 70) return 'B';
    if (percentage >= 60) return 'C+';
    if (percentage >= 50) return 'C';
    if (percentage >= 40) return 'D';
    return 'F';
  }

  Future<void> createTest(
    TestModel test,
    String performedBy,
    String performedByRole,
  ) async {
    final docRef = tests.doc(test.testId);
    final snapshot = await docRef.get();
    final data = test.toJson();
    data['updatedAt'] = FieldValue.serverTimestamp();
    if (!snapshot.exists) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }
    await docRef.set(data, SetOptions(merge: true));

    await notifications.add({
      'title': 'New assessment published',
      'message': '${test.title} for ${test.classId}-${test.section} is now available.',
      'targetClassId': test.classId,
      'targetSection': test.section,
      'targetType': 'assessment',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _auditService.createAuditLog(
      AuditLogModel(
        auditId: _auditService.buildAuditId('test', test.testId, DateTime.now()),
        action: 'CREATE_TEST',
        targetType: 'test',
        targetId: test.testId,
        performedBy: performedBy,
        performedByRole: performedByRole,
        newValue: data,
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> saveTestResults(
    List<TestResultModel> results,
    String performedBy,
    String performedByRole,
  ) async {
    final batch = _firestore.batch();
    for (final result in results) {
      final docRef = testResults.doc(result.resultId);
      final data = result.toJson();
      data['updatedAt'] = FieldValue.serverTimestamp();
      batch.set(docRef, data, SetOptions(merge: true));
    }
    await batch.commit();

    if (results.isNotEmpty) {
      final first = results.first;
      await notifications.add({
        'title': 'Assessment results updated',
        'message': 'Marks were entered for ${first.testTitle} (${first.classId}-${first.section}).',
        'targetClassId': first.classId,
        'targetSection': first.section,
        'targetType': 'assessment_result',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _auditService.createAuditLog(
        AuditLogModel(
          auditId: _auditService.buildAuditId('test_result', first.testId, DateTime.now()),
          action: 'SAVE_TEST_RESULTS',
          targetType: 'test_result',
          targetId: first.testId,
          performedBy: performedBy,
          performedByRole: performedByRole,
          newValue: {
            'count': results.length,
            'testId': first.testId,
          },
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  Future<List<TestModel>> fetchTestsForClassSection({
    required String classId,
    required String section,
  }) async {
    final query = await tests
        .where('classId', isEqualTo: classId)
        .where('section', isEqualTo: section)
        .get();
    final results = query.docs
        .map((doc) => TestModel.fromJson(doc.data()))
        .toList();
    results.sort((a, b) => b.date.compareTo(a.date));
    return results;
  }

  Future<List<TestResultModel>> fetchResultsForTest(String testId) async {
    final query = await testResults.where('testId', isEqualTo: testId).get();
    final results = query.docs
        .map((doc) => TestResultModel.fromJson(doc.data()))
        .toList();
    results.sort((a, b) => a.studentName.compareTo(b.studentName));
    return results;
  }

  Future<List<TestResultModel>> fetchResultsForStudent(String studentId) async {
    final query = await testResults.where('studentId', isEqualTo: studentId).get();
    final results = query.docs
        .map((doc) => TestResultModel.fromJson(doc.data()))
        .toList();
    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return results;
  }

  Future<List<TestResultModel>> fetchResultsForClassSection({
    required String classId,
    required String section,
  }) async {
    final query = await testResults
        .where('classId', isEqualTo: classId)
        .where('section', isEqualTo: section)
        .get();
    return query.docs
        .map((doc) => TestResultModel.fromJson(doc.data()))
        .where((result) => result.isFinalExam)
        .toList();
  }
}
