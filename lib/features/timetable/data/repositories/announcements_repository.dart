import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/announcement_model.dart';

class SupabaseAnnouncementsRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Stream<List<AnnouncementModel>> getAnnouncementsStream() {
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .map((data) {
          final list = data
              .map((row) => _mapRowToAnnouncementModel(row))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        })
        .handleError((e) {
          debugPrint('Announcements stream offline/error: $e');
        });
  }

  Future<AnnouncementModel> postAnnouncement({
    required String title,
    required String message,
    String priority = 'normal',
    String author = 'Admin / CR',
  }) async {
    final response = await _supabase
        .from('notifications')
        .insert({
          'title': title,
          'body': message,
          'priority': priority,
          'target': author,
        })
        .select()
        .single();

    return _mapRowToAnnouncementModel(response);
  }

  Future<void> deleteAnnouncement(String id) async {
    await _supabase.from('notifications').delete().eq('id', id);
  }

  AnnouncementModel _mapRowToAnnouncementModel(Map<String, dynamic> row) {
    return AnnouncementModel(
      id: row['id'] ?? '',
      title: row['title'] ?? 'Announcement',
      message: row['body'] ?? '',
      author: row['target'] ?? 'Admin',
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at'])
          : DateTime.now(),
      priority: row['priority'] ?? 'normal',
    );
  }
}
