import '../models/user_model.dart';

abstract class AuthRepository {
  Stream<UserModel?> get authStateChanges;
  Future<UserModel?> getCurrentUser();
  Future<UserModel> signInWithEmailAndPassword(String email, String password);
  Future<UserModel> signUpWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
    required String rollNumber,
  });
  Future<UserModel> signInWithGoogle();
  Future<void> sendPasswordResetEmail(String email);
  Future<void> resendVerificationEmail();
  Future<UserModel?> updateProfile({
    String? name,
    String? phone,
    String? section,
    String? gender,
    DateTime? dob,
    String? emergencyContact,
    String? rollNumber,
    List<String>? skills,
    List<String>? interests,
    Map<String, dynamic>? privacySettings,
    bool? isProfileCompleted,
  });
  Future<void> signOut();
}
