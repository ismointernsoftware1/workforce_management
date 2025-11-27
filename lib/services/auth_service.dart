import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Ensure user profile exists in Firestore
      await _ensureUserProfile(credential.user!);

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to sign in: ${e.toString()}');
    }
  }

  // Sign up with email and password
  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    String? role,
    String? department,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update display name
      await credential.user?.updateDisplayName(name);

      // Create user profile in Firestore
      await _createUserProfile(
        credential.user!,
        name: name,
        role: role ?? 'Employee',
        department: department ?? 'General',
      );

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to sign up: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Ensure user profile exists in Firestore (create if doesn't exist)
  Future<void> _ensureUserProfile(User user) async {
    try {
      final userDoc = _firestore.collection('users').doc(user.uid);
      final docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        // Create user profile if it doesn't exist
        final displayName = user.displayName ?? user.email?.split('@')[0] ?? 'User';
        await _createUserProfile(
          user,
          name: displayName,
          role: 'Employee',
          department: 'General',
        );
      } else {
        // Update email if changed
        final data = docSnapshot.data();
        if (data != null && data['email'] != user.email) {
          await userDoc.update({'email': user.email});
        }
      }
    } catch (e) {
      print('Error ensuring user profile: $e');
      // Don't throw - allow login to proceed even if profile update fails
    }
  }

  // Create user profile in Firestore
  Future<void> _createUserProfile(
    User user, {
    required String name,
    required String role,
    required String department,
  }) async {
    try {
      final userModel = UserModel(
        id: user.uid,
        name: name,
        email: user.email ?? '',
        role: role,
        department: department,
        status: 'Active',
        joinDate: DateTime.now(),
      );

      await _firestore.collection('users').doc(user.uid).set(userModel.toMap());
    } catch (e) {
      print('Error creating user profile: $e');
      throw Exception('Failed to create user profile: ${e.toString()}');
    }
  }

  // Handle Firebase Auth exceptions
  Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('No user found with this email.');
      case 'wrong-password':
        return Exception('Wrong password provided.');
      case 'email-already-in-use':
        return Exception('An account already exists with this email.');
      case 'weak-password':
        return Exception('Password is too weak.');
      case 'invalid-email':
        return Exception('Invalid email address.');
      case 'user-disabled':
        return Exception('This account has been disabled.');
      case 'too-many-requests':
        return Exception('Too many requests. Please try again later.');
      case 'operation-not-allowed':
        return Exception('This operation is not allowed.');
      default:
        return Exception(e.message ?? 'Authentication failed.');
    }
  }
}

