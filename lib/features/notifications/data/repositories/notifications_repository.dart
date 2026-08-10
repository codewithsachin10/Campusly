import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/notification_item_model.dart';

abstract class NotificationsRepository {
  Stream<List<NotificationItemModel>> getNotificationsStream();
  Future<void> markAsRead(String notificationId, String studentId);
  Future<void> markAllAsRead(List<String> notificationIds, String studentId);
}

class SupabaseNotificationsRepository implements NotificationsRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Stream<List<NotificationItemModel>> getNotificationsStream() {
    return _supabase.from('notifications').stream(primaryKey: ['id']).map((
      data,
    ) {
      final list = data
          .map((doc) => NotificationItemModel.fromMap(doc))
          .toList();
      // Sort descending by sentAt
      list.sort((a, b) => b.sentAt.compareTo(a.sentAt));
      return list;
    });
  }

  @override
  Future<void> markAsRead(String notificationId, String studentId) async {
    if (notificationId.isEmpty || studentId.isEmpty) return;
    try {
      final response = await _supabase
          .from('notifications')
          .select('readBy')
          .eq('id', notificationId)
          .maybeSingle();

      if (response != null) {
        final currentReadBy = List<String>.from(response['readBy'] ?? []);
        if (!currentReadBy.contains(studentId)) {
          currentReadBy.add(studentId);
          await _supabase
              .from('notifications')
              .update({'readBy': currentReadBy})
              .eq('id', notificationId);
        }
      }
    } catch (_) {
      // Ignore if document is deleted or permission error
    }
  }

  @override
  Future<void> markAllAsRead(
    List<String> notificationIds,
    String studentId,
  ) async {
    if (notificationIds.isEmpty || studentId.isEmpty) return;
    for (final id in notificationIds) {
      if (id.isNotEmpty) {
        await markAsRead(id, studentId);
      }
    }
  }
}
