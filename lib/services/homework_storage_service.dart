import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class HomeworkStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadHomeworkAttachment({
    required String storagePath,
    required File file,
    void Function(double progress)? onProgress,
  }) async {
    final metadata = SettableMetadata(
      contentType: _contentTypeFromExtension(file.path),
    );
    final uploadTask = _storage.ref(storagePath).putFile(file, metadata);

    uploadTask.snapshotEvents.listen((event) {
      final total = event.totalBytes;
      if (total > 0) {
        final progress = event.bytesTransferred / total;
        onProgress?.call(progress);
      }
    });

    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> deleteAttachment(String storagePath) async {
    await _storage.ref(storagePath).delete();
  }

  String _contentTypeFromExtension(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.mp4')) return 'video/mp4';
    if (lower.endsWith('.mp3')) return 'audio/mpeg';
    if (lower.endsWith('.txt')) return 'text/plain';
    return 'application/octet-stream';
  }
}
