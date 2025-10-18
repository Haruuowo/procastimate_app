import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AuthService {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get userChanges => _auth.authStateChanges();

  /// Sign in with email + password
  Future<User?> signIn(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return result.user;
  }

  /// Sign up and create Firestore user profile
  Future<User?> signUp(String email, String password,
      {String? username, File? profileImage}) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = result.user;
    if (user == null) return null;

    // Upload profile image if provided
    String? photoUrl;
    if (profileImage != null) {
      final ref = _storage.ref().child('profile_pictures/${user.uid}.jpg');
      await ref.putFile(profileImage);
      photoUrl = await ref.getDownloadURL();
      await user.updatePhotoURL(photoUrl);
    }

    // Update username in Firebase Auth
    if (username != null && username.isNotEmpty) {
      await user.updateDisplayName(username);
    }

    // Save Firestore document
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': email,
      'username': username ?? '',
      'photoUrl': photoUrl ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return user;
  }

  /// Update user profile later
  Future<void> updateProfile({String? username, File? profileImage}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    String? photoUrl;
    if (profileImage != null) {
      final ref = _storage.ref().child('profile_pictures/${user.uid}.jpg');
      await ref.putFile(profileImage);
      photoUrl = await ref.getDownloadURL();
      await user.updatePhotoURL(photoUrl);
    }

    if (username != null && username.isNotEmpty) {
      await user.updateDisplayName(username);
    }

    await _firestore.collection('users').doc(user.uid).update({
      if (username != null) 'username': username,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Sign out
  Future<void> signOut() async => await _auth.signOut();
}
