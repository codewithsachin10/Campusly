import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/chat_model.dart';
import '../../auth/domain/models/user_model.dart';

final communityManagerServiceProvider = Provider<CommunityManagerService>((
  ref,
) {
  return CommunityManagerService(Supabase.instance.client);
});

class CommunityManagerService {
  final SupabaseClient _supabase;

  CommunityManagerService(this._supabase);

  Future<void> syncUserCommunities(UserModel user) async {
    // We create/join 3 types of communities based on profile:
    // 1. Department Community (e.g. CSBS)
    // 2. Year Community (e.g. 1st Year)
    // 3. Section Community (e.g. CSBS - 1st Year - Section A)

    if (user.department != null && user.department!.isNotEmpty) {
      await _joinOrCreateCommunity(
        communityId: 'dept_${user.department}',
        name: '${user.department} Department',
        userId: user.id,
      );
    }

    if (user.year != null && user.year!.isNotEmpty) {
      await _joinOrCreateCommunity(
        communityId: 'year_${user.year}',
        name: '${user.year} Batch',
        userId: user.id,
      );
    }

    if (user.department != null && user.year != null && user.section != null) {
      await _joinOrCreateCommunity(
        communityId: 'sec_${user.department}_${user.year}_${user.section}',
        name: '${user.department} - ${user.year} - Section ${user.section}',
        userId: user.id,
      );
    }
  }

  Future<void> _joinOrCreateCommunity({
    required String communityId,
    required String name,
    required String userId,
  }) async {
    try {
      final docSnap = await _supabase
          .from('chats')
          .select()
          .eq('id', communityId)
          .maybeSingle();

      if (docSnap == null) {
        final newChat = ChatModel(
          id: communityId,
          type: ChatType.community,
          participants: [userId],
          groupMetadata: {'name': name, 'isAutoCommunity': true},
        );
        await _supabase.from('chats').insert(newChat.toJson());
      } else {
        // Add user to participants if not already there
        final data = docSnap;
        final participants = List<String>.from(data['participants'] ?? []);
        if (!participants.contains(userId)) {
          participants.add(userId);
          await _supabase
              .from('chats')
              .update({'participants': participants})
              .eq('id', communityId);
        }
      }
    } catch (_) {}
  }
}
