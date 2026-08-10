import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/campus_location.dart';

final campusLocationRepositoryProvider = Provider<CampusLocationRepository>((
  ref,
) {
  return CampusLocationRepository(Supabase.instance.client);
});

final campusLocationsProvider = StreamProvider<List<CampusLocation>>((ref) {
  final repository = ref.watch(campusLocationRepositoryProvider);
  return repository.streamCampusLocations();
});

class CampusLocationRepository {
  final SupabaseClient _supabase;

  CampusLocationRepository(this._supabase);

  Stream<List<CampusLocation>> streamCampusLocations() {
    return _supabase.from('campus_locations').stream(primaryKey: ['id']).map((
      data,
    ) {
      return data.map((row) {
        final map = Map<String, dynamic>.from(row);
        return CampusLocation.fromJson(map);
      }).toList();
    });
  }

  Future<void> addLocation(CampusLocation location) async {
    try {
      await _supabase.from('campus_locations').upsert(location.toJson());
    } catch (_) {}
  }

  Future<CampusLocation?> getLocationById(String id) async {
    try {
      final response = await _supabase
          .from('campus_locations')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response != null) {
        final map = Map<String, dynamic>.from(response);
        return CampusLocation.fromJson(map);
      }
    } catch (_) {}
    return null;
  }
}
