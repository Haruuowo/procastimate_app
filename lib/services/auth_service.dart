import 'dart:async';

// Simple placeholder auth service to be replaced with Firebase later.
class AuthService {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  String? _email;

  String? get currentUserEmail => _email;

  Future<String> signInWithEmail(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 400));
    _email = email;
    return _email!;
  }

  Future<String> createUserWithEmail(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _email = email;
    return _email!;
  }

  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _email = null;
  }
}
