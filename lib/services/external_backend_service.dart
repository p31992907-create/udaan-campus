import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class ExternalBackendService {
  ExternalBackendService({
    http.Client? client,
    FirebaseAuth? auth,
    this.baseUrl = 'https://udaan-campus.onrender.com',
  })  : _client = client ?? http.Client(),
        _auth = auth ?? FirebaseAuth.instance;

  final http.Client _client;
  final FirebaseAuth _auth;
  final String baseUrl;

  Future<void> syncUser({
    required String displayName,
    required String email,
  }) async {
    final response = await _authorizedPost(
      '/v1/auth/sync-user',
      {'displayName': displayName, 'email': email},
    );
    _requireSuccess(response, 'User sync failed');
  }

  Future<String> linkParent({
    required String parentUid,
    required String studentUid,
  }) async {
    final response = await _authorizedPost(
      '/v1/parent-links',
      {'parentUid': parentUid, 'studentUid': studentUid},
    );
    _requireSuccess(response, 'Parent link failed');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final linkId = data['linkId'];
    if (linkId is! String || linkId.isEmpty) {
      throw const FormatException('Parent link response did not include linkId');
    }
    return linkId;
  }

  Future<http.Response> _authorizedPost(
    String path,
    Map<String, dynamic> body,
  ) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('A signed-in Firebase user is required');
    }
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw StateError('Firebase ID token is unavailable');
    }

    return _client
        .post(
          Uri.parse('$baseUrl$path'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));
  }

  void _requireSuccess(http.Response response, String operation) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    String detail = response.body;
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      detail = data['error']?.toString() ?? detail;
    } catch (_) {
      // Preserve the raw response when the backend does not return JSON.
    }
    throw StateError('$operation (${response.statusCode}): $detail');
  }
}
