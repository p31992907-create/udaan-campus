import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';
import '../models/user_role.dart';
import 'user_repository.dart';
import 'external_backend_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserRepository _userRepository = UserRepository();
  final ExternalBackendService _externalBackend = ExternalBackendService();

  AppUser? _user;
  AppUser? get user => _user;

  bool _isLoading = true;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    _isLoading = true;
    notifyListeners();

    if (firebaseUser == null) {
      _user = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      await _externalBackend.syncUser(
        displayName: firebaseUser.displayName ?? '',
        email: firebaseUser.email ?? '',
      );
    } catch (error, stackTrace) {
      debugPrint('External user sync failed: $error\n$stackTrace');
    }

    final userProfile = await _userRepository.fetchUser(firebaseUser.uid);
    if (userProfile != null) {
      final updatedUser = AppUser(
        uid: userProfile.uid,
        email: firebaseUser.email ?? userProfile.email,
        displayName: firebaseUser.displayName ?? userProfile.displayName,
        role: UserRole.normalize(userProfile.role),
        photoUrl: firebaseUser.photoURL ?? userProfile.photoUrl,
        assignedClassSections: userProfile.assignedClassSections,
        studentClassId: userProfile.studentClassId,
        studentSection: userProfile.studentSection,
        linkedChildren: userProfile.linkedChildren,
      );
      _user = updatedUser;
      await _userRepository.saveUser(updatedUser);
    } else {
      final newUser = AppUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName ?? '',
        role: UserRole.student,
        photoUrl: firebaseUser.photoURL,
      );
      _user = newUser;
      await _userRepository.createUser(
        uid: newUser.uid,
        email: newUser.email,
        displayName: newUser.displayName,
        role: newUser.role,
      );
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    notifyListeners();
  }

  Future<void> updateRole(String role) async {
    if (_user == null) return;
    final normalized = UserRole.normalize(role);
    _user = AppUser(
      uid: _user!.uid,
      email: _user!.email,
      displayName: _user!.displayName,
      role: normalized,
      photoUrl: _user!.photoUrl,
    );
    await _userRepository.saveUser(_user!);
    notifyListeners();
  }
}
