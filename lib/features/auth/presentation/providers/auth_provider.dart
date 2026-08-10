import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/supabase_auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository();
});

final authStateChangesProvider = StreamProvider<UserModel?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges;
});

class AuthController extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async {
    final repository = ref.watch(authRepositoryProvider);
    return repository.getCurrentUser();
  }

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);
      return await repository.signInWithEmailAndPassword(email, password);
    });
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    required String rollNumber,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);
      return await repository.signUpWithEmailAndPassword(
        name: name,
        email: email,
        password: password,
        rollNumber: rollNumber,
      );
    });
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);
      return await repository.signInWithGoogle();
    });
  }

  Future<void> sendPasswordResetEmail(String email) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);
      await repository.sendPasswordResetEmail(email);
      return state.value;
    });
  }

  Future<void> resendVerificationEmail() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);
      await repository.resendVerificationEmail();
      return state.value;
    });
  }

  Future<void> updateProfile({
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
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);
      return await repository.updateProfile(
        name: name,
        phone: phone,
        section: section,
        gender: gender,
        dob: dob,
        emergencyContact: emergencyContact,
        rollNumber: rollNumber,
        skills: skills,
        interests: interests,
        privacySettings: privacySettings,
        isProfileCompleted: isProfileCompleted,
      );
    });
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);
      await repository.signOut();
      return null;
    });
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, UserModel?>(() {
      return AuthController();
    });
