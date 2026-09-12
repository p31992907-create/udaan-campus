import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabasePaperStorageService {
  static const bucket = 'exam-papers';
  final SupabaseClient _client = Supabase.instance.client;

  Future<String> uploadPaper({
    required String path,
    required File file,
    required String contentType,
  }) async {
    await _client.storage.from(bucket).upload(
          path,
          file,
          fileOptions: FileOptions(
            contentType: contentType,
            upsert: false,
          ),
        );
    return _client.storage.from(bucket).createSignedUrl(path, 60 * 60 * 24);
  }
}
