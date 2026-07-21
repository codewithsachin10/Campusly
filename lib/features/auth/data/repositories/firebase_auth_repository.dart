import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final fb_auth.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  FirebaseAuthRepository({
    fb_auth.FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? fb_auth.FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<UserModel?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((fbUser) async {
      if (fbUser == null) return null;
      return _fetchUserFromFirestore(fbUser);
    });
  }

  Future<UserModel> _fetchUserFromFirestore(fb_auth.User fbUser) async {
    try {
      final doc = await _firestore.collection('users').doc(fbUser.uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        return UserModel(
          id: fbUser.uid,
          name:
              data['name'] as String? ??
              fbUser.displayName ??
              fbUser.email?.split('@').first ??
              'Student',
          department: data['department'] as String?,
          email: data['email'] as String? ?? fbUser.email ?? '',
          avatarUrl: data['avatarUrl'] as String? ?? fbUser.photoURL,
          isEmailVerified: fbUser.emailVerified,
          createdAt: (data['createdAt'] is Timestamp)
              ? (data['createdAt'] as Timestamp).toDate()
              : (fbUser.metadata.creationTime ?? DateTime.now()),
        );
      }
    } catch (e) {
      debugPrint('Error fetching user doc from Firestore: $e');
    }

    // Fallback if doc doesn't exist yet
    return UserModel(
      id: fbUser.uid,
      name:
          fbUser.displayName ??
          fbUser.email?.split('@').first.toUpperCase() ??
          'STUDENT',
      email: fbUser.email ?? '',
      isEmailVerified: fbUser.emailVerified,
      createdAt: fbUser.metadata.creationTime ?? DateTime.now(),
    );
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) return null;
    return _fetchUserFromFirestore(fbUser);
  }

  @override
  Future<UserModel> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final fbUser = credential.user;
    if (fbUser == null) {
      throw Exception('Authentication failed. No user returned.');
    }
    return _fetchUserFromFirestore(fbUser);
  }

  @override
  Future<UserModel> signUpWithEmailAndPassword({
    required String name,
    required String department,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final fbUser = credential.user;
    if (fbUser == null) {
      throw Exception('Sign up failed. No user returned.');
    }

    // Update display name
    await fbUser.updateDisplayName(name);

    // Create user profile in Firestore
    final userData = {
      'uid': fbUser.uid,
      'name': name,
      'department': department,
      'email': email.trim(),
      'isEmailVerified': fbUser.emailVerified,
      'createdAt': Timestamp.fromDate(DateTime.now()),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };

    await _firestore.collection('users').doc(fbUser.uid).set(userData);

    // Send verification email
    try {
      await fbUser.sendEmailVerification();
    } catch (e) {
      debugPrint('Could not send email verification: $e');
    }

    return UserModel(
      id: fbUser.uid,
      name: name,
      department: department,
      email: email.trim(),
      isEmailVerified: fbUser.emailVerified,
      createdAt: DateTime.now(),
    );
  }

  bool _googleSignInInitialized = false;

  Future<void> _ensureGoogleSignInInitialized() async {
    if (!_googleSignInInitialized) {
      const String googleClientId = String.fromEnvironment(
        'GOOGLE_CLIENT_ID',
        defaultValue:
            '1144756968-k9k91c90cn4m82jmkq23o4tq89cqrr9u.apps.googleusercontent.com',
      );
      await GoogleSignIn.instance.initialize(serverClientId: googleClientId);
      _googleSignInInitialized = true;
    }
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    await _ensureGoogleSignInInitialized();

    final GoogleSignInAccount googleUser = await GoogleSignIn.instance
        .authenticate();

    final GoogleSignInAuthentication googleAuth = googleUser.authentication;
    final GoogleSignInClientAuthorization? clientAuth = await googleUser
        .authorizationClient
        .authorizationForScopes(['email', 'profile']);

    final fb_auth.OAuthCredential credential =
        fb_auth.GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
          accessToken: clientAuth?.accessToken,
        );

    final fb_auth.UserCredential userCredential = await _auth
        .signInWithCredential(credential);
    final fb_auth.User? fbUser = userCredential.user;
    if (fbUser == null) {
      throw Exception('Authentication failed. No user returned from Google.');
    }

    // Ensure user document exists in Firestore
    try {
      final docRef = _firestore.collection('users').doc(fbUser.uid);
      final doc = await docRef.get();
      if (!doc.exists || doc.data() == null) {
        final name =
            fbUser.displayName ?? fbUser.email?.split('@').first ?? 'Student';
        final email = fbUser.email ?? '';
        final userData = {
          'uid': fbUser.uid,
          'name': name,
          'department': 'CSBS',
          'email': email,
          'avatarUrl': fbUser.photoURL,
          'isEmailVerified': true,
          'createdAt': Timestamp.fromDate(DateTime.now()),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        };
        await docRef.set(userData, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error creating/checking Google user in Firestore: $e');
    }

    return _fetchUserFromFirestore(fbUser);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  @override
  Future<void> resendVerificationEmail() async {
    final fbUser = _auth.currentUser;
    if (fbUser != null && !fbUser.emailVerified) {
      await fbUser.sendEmailVerification();
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
