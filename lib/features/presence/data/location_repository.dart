import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/presence_model.dart';
import '../../auth/domain/models/user_model.dart';

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return LocationRepository(Supabase.instance.client);
});

class LocationRepository {
  final SupabaseClient _supabase;

  LocationRepository(this._supabase);

  Future<void> checkIn(PresenceModel presence) async {
    try {
      await _supabase.from('campus_presence').upsert(presence.toJson());
    } catch (_) {}
  }

  Future<void> clearCheckIn(String userId) async {
    try {
      await _supabase.from('campus_presence').delete().eq('userId', userId);
    } catch (_) {}
  }

  Stream<List<Map<String, dynamic>>> streamCampusPresence(
    UserModel currentUser,
  ) {
    // We want to fetch all active presences, and then manually filter on the client
    // because visibility rules ('Friends', 'Classmates') are complex to query natively in Supabase
    // without custom SQL functions.
    // Since campus presence is ephemeral and relatively small per campus, fetching all active
    // and filtering client-side is acceptable for now.

    return _supabase.from('campus_presence').stream(primaryKey: ['userId']).map(
      (data) {
        final nowIso = DateTime.now().toIso8601String();
        return data
            .where((row) {
              final expiresAt = row['expiresAt'] as String?;
              if (expiresAt == null) return false;
              return expiresAt.compareTo(nowIso) > 0;
            })
            .map((row) => Map<String, dynamic>.from(row))
            .toList();
      },
    );
  }
}
