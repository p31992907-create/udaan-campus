import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FirebaseService {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    await Firebase.initializeApp();
    await Supabase.initialize(
      url: 'https://homejmttlrjglxzadkky.supabase.co',
      publishableKey: 'sb_publishable__g7bBgkfpxgL5QVH7cOPbQ_fUTJhMrP',
    );
    _initialized = true;
  }
}
