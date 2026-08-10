import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

final presenceServiceProvider = Provider<PresenceService>((ref) {
  final user = ref.watch(authControllerProvider).value;
  final service = PresenceService();
  if (user != null) {
    service.startTracking(user.id);
  }
  return service;
});

class PresenceService {
  final SupabaseClient _supabase = Supabase.instance.client;
  String? _currentUserId;
  RealtimeChannel? _presenceChannel;

  void startTracking(String userId) {
    _currentUserId = userId;

    // We use a shared room for all presence
    _presenceChannel = _supabase.channel('online-users');

    _presenceChannel!
        .onPresenceSync((payload) {
          // Handle presence sync if needed to build a list of online users
        })
        .onPresenceJoin((payload) {
          // Handle join
        })
        .onPresenceLeave((payload) {
          // Handle leave
        })
        .subscribe((status, [error]) async {
          if (status == RealtimeSubscribeStatus.subscribed) {
            // Track ourselves as online
            await _presenceChannel!.track({
              'user_id': userId,
              'status': 'online',
            });

            // Update database presence state
            try {
              await _supabase
                  .from('students')
                  .update({
                    'isOnline': true,
                    'lastSeen': DateTime.now().toIso8601String(),
                    'presenceState': 'online',
                  })
                  .eq('studentId', userId);
            } catch (_) {}
          }
        });
  }

  Future<void> setActivityState(String state) async {
    // state can be: online, in_class, dnd, offline
    if (_currentUserId == null || _presenceChannel == null) return;

    // Track our new state
    await _presenceChannel!.track({'user_id': _currentUserId, 'status': state});

    try {
      await _supabase
          .from('students')
          .update({'presenceState': state, 'isOnline': state != 'offline'})
          .eq('studentId', _currentUserId!);
    } catch (_) {}
  }

  Stream<String> streamUserPresence(String userId) {
    // In Supabase, getting a specific user's presence continuously requires listening to the channel's state.
    // For simplicity, we create a channel to listen to changes on the students table for this user.
    return _supabase
        .from('students')
        .stream(primaryKey: ['studentId'])
        .eq('studentId', userId)
        .map((data) {
          if (data.isEmpty) return 'offline';
          return data.first['presenceState'] as String? ??
              (data.first['isOnline'] == true ? 'online' : 'offline');
        });
  }
}
