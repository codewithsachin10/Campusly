import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _supabase;

  SupabaseAuthRepository({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  @override
  Stream<UserModel?> get authStateChanges {
    return _supabase.auth.onAuthStateChange.asyncMap((data) async {
      final session = data.session;
      if (session == null) return null;
      return _fetchUserFromSupabase(session.user);
    });
  }

  Future<UserModel> _fetchUserFromSupabase(User supaUser) async {
    try {
      final data = await _supabase
          .from('students')
          .select()
          .eq('email', supaUser.email ?? '')
          .maybeSingle();

      if (data != null) {
        return UserModel(
          id: supaUser.id,
          name:
              data['name'] as String? ??
              supaUser.userMetadata?['full_name'] ??
              supaUser.email?.split('@').first ??
              'Student',
          department: data['departmentId'] as String?,
          email: data['email'] as String? ?? supaUser.email ?? '',
          avatarUrl:
              data['avatarUrl'] as String? ??
              supaUser.userMetadata?['avatar_url'],
          isEmailVerified: supaUser.emailConfirmedAt != null,
          createdAt: (data['created_at'] != null)
              ? DateTime.parse(data['created_at'])
              : DateTime.parse(supaUser.createdAt),
          phone: data['phone'] as String?,
          section: data['section'] as String?,
          year: data['academicYear'] as String?,
          semester: data['semester'] as int?,
          rollNumber: data['rollNumber'] as String?,
          status: data['status'] as String?,
          isProfileCompleted: data['is_profile_completed'] as bool? ?? false,
          gender: data['gender'] as String?,
          dob: data['dob'] != null ? DateTime.parse(data['dob'] as String) : null,
          emergencyContact: data['emergency_contact'] as String?,
        );
      }
    } catch (e) {
      debugPrint('Error fetching user from Supabase: $e');
    }

    // Fallback if doc doesn't exist yet
    return UserModel(
      id: supaUser.id,
      name:
          supaUser.userMetadata?['full_name'] ??
          supaUser.email?.split('@').first.toUpperCase() ??
          'STUDENT',
      email: supaUser.email ?? '',
      isEmailVerified: supaUser.emailConfirmedAt != null,
      createdAt: DateTime.parse(supaUser.createdAt),
    );
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final supaUser = _supabase.auth.currentUser;
    if (supaUser == null) return null;
    return _fetchUserFromSupabase(supaUser);
  }

  @override
  Future<UserModel> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    if (!email.trim().endsWith('@rajalakshmi.edu.in')) {
      throw Exception('This application is only available for students with an official college email (@rajalakshmi.edu.in).');
    }

    final response = await _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    final supaUser = response.user;
    if (supaUser == null) {
      throw Exception('Authentication failed. No user returned.');
    }
    return _fetchUserFromSupabase(supaUser);
  }

  Future<Map<String, dynamic>> _getAcademicContext(String email) async {
    try {
      final res = await _supabase.rpc('get_student_academic_context', params: {
        'student_email': email.trim(),
      });
      if (res != null && res['error'] == null) {
        return res as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Failed to get academic context: $e');
    }
    return {}; // fallback empty context
  }

  @override
  Future<UserModel> signUpWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
    required String rollNumber,
  }) async {
    if (!email.trim().endsWith('@rajalakshmi.edu.in')) {
      throw Exception('This application is only available for students with an official college email (@rajalakshmi.edu.in).');
    }

    final response = await _supabase.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'full_name': name},
    );

    final supaUser = response.user;
    if (supaUser == null) {
      throw Exception('Sign up failed. No user returned.');
    }

    // Create user profile in students table
    try {
      final context = await _getAcademicContext(email.trim());
      await _supabase.from('students').insert({
        'name': name,
        'email': email.trim(),
        'rollNumber': rollNumber,
        'departmentId': context['department_code'] ?? 'GENERAL',
        'academicYear': context['current_year']?.toString(),
        'semester': context['current_semester'],
        'is_profile_completed': false,
      });
    } catch (e) {
      debugPrint('Error creating student profile: $e');
    }

    return _fetchUserFromSupabase(supaUser);
  }

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: const String.fromEnvironment(
      'GOOGLE_CLIENT_ID',
      defaultValue:
          '1144756968-k9k91c90cn4m82jmkq23o4tq89cqrr9u.apps.googleusercontent.com',
    ),
  );

  @override
  Future<UserModel> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

    if (googleUser == null) {
      throw Exception('Google Sign-In canceled.');
    }

    if (!googleUser.email.endsWith('@rajalakshmi.edu.in')) {
      await _googleSignIn.signOut();
      throw Exception('This application is only available for students with an official college email (@rajalakshmi.edu.in).');
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;

    if (idToken == null) {
      throw Exception('No ID Token found.');
    }

    final response = await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );

    final supaUser = response.user;
    if (supaUser == null) {
      throw Exception('Authentication failed. No user returned from Supabase.');
    }

    // Ensure user document exists in Supabase
    try {
      final data = await _supabase
          .from('students')
          .select()
          .eq('email', supaUser.email ?? '')
          .maybeSingle();
      
      if (data == null) {
        final name =
            supaUser.userMetadata?['full_name'] ??
            supaUser.email?.split('@').first ??
            'Student';
        final email = supaUser.email ?? '';
        
        final context = await _getAcademicContext(email);
        
        await _supabase.from('students').insert({
          'name': name,
          'email': email,
          'departmentId': context['department_code'] ?? 'GENERAL',
          'academicYear': context['current_year']?.toString(),
          'semester': context['current_semester'],
          'is_profile_completed': false,
        });
      }
    } catch (e) {
      debugPrint('Error creating/checking Google user in Supabase: $e');
    }

    return _fetchUserFromSupabase(supaUser);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _supabase.auth.resetPasswordForEmail(email.trim());
  }

  @override
  Future<void> resendVerificationEmail() async {
    final supaUser = _supabase.auth.currentUser;
    if (supaUser != null && supaUser.emailConfirmedAt == null) {
      await _supabase.auth.resend(type: OtpType.signup, email: supaUser.email);
    }
  }

  @override
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
  }) async {
    final supaUser = _supabase.auth.currentUser;
    if (supaUser == null) return null;

    final updates = <String, dynamic>{};
    if (name != null) {
      updates['name'] = name;
      await _supabase.auth.updateUser(
        UserAttributes(data: {'full_name': name}),
      );
    }
    
    if (phone != null) updates['phone'] = phone;
    if (section != null) updates['section'] = section;
    if (gender != null) updates['gender'] = gender;
    if (dob != null) updates['dob'] = dob.toIso8601String();
    if (emergencyContact != null) updates['emergency_contact'] = emergencyContact;
    if (rollNumber != null) updates['rollNumber'] = rollNumber;
    if (isProfileCompleted != null) updates['is_profile_completed'] = isProfileCompleted;

    // Note: skills, interests, privacySettings would need schema updates if we want to store them in Postgres natively

    if (updates.isNotEmpty) {
      final existing = await _supabase
          .from('students')
          .select()
          .eq('email', supaUser.email ?? '')
          .maybeSingle();

      if (existing != null) {
        await _supabase
            .from('students')
            .update(updates)
            .eq('email', supaUser.email ?? '');
      } else {
        updates['email'] = supaUser.email;
        if (name == null) {
          updates['name'] = supaUser.userMetadata?['full_name'] ?? 
                            supaUser.email?.split('@').first ?? 'Student';
        }
        await _supabase.from('students').insert(updates);
      }
    }
    return _fetchUserFromSupabase(supaUser);
  }

  @override
  Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      debugPrint('Error clearing SharedPreferences on sign out: $e');
    }
    await _googleSignIn.signOut();
    await _supabase.auth.signOut();
  }
}
