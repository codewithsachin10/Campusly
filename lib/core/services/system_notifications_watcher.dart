import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/notifications/presentation/providers/notifications_provider.dart';
import '../../features/timetable/presentation/providers/announcements_provider.dart';
import '../../features/chat/presentation/providers/chat_providers.dart';

import 'notification_service.dart';

final systemNotificationsWatcherProvider = Provider<void>((ref) {
  final notifService = ref.watch(notificationServiceProvider);
  final prefs = ref.watch(notificationPreferencesProvider);

  // Only trigger system popups if master notifications are enabled
  if (!prefs.masterEnabled) return;

  // Listen to targeted notifications from the Notification Inbox stream
  ref.listen(filteredNotificationsProvider, (previous, next) {
    next.whenData((notifs) async {
      // If previous was null or loading (initial app startup), mark existing notifications as seen to prevent flooding
      if (previous == null || previous.isLoading) {
        for (final item in notifs) {
          await notifService.markSeenNotification(item.id);
        }
        return;
      }

      // Check for newly posted notifications while app is running / active
      final now = DateTime.now();
      for (final item in notifs) {
        final seen = await notifService.hasSeenNotification(item.id);
        if (!seen) {
          await notifService.markSeenNotification(item.id);
          // Only show popup if sent recently (within the last 24 hours)
          if (now.difference(item.sentAt).inHours < 24) {
            final int notifId = item.id.hashCode.abs() % 100000 + 100000;
            final isEmergency =
                item.category == 'Emergency Alert' ||
                item.priority == 'emergency';
            await notifService.showSystemNotification(
              id: notifId,
              title: isEmergency ? '🚨 ${item.title}' : '🔔 ${item.title}',
              body: item.message,
              payload: 'notification_inbox',
              isEmergency: isEmergency,
            );
            debugPrint(
              'Triggered system status bar notification for: ${item.title}',
            );
          }
        }
      }
    });
  });

  // Listen to general announcements / circulars from Notice Board stream
  ref.listen(announcementsStreamProvider, (previous, next) {
    next.whenData((announcements) async {
      if (previous == null || previous.isLoading) {
        for (final item in announcements) {
          await notifService.markSeenNotification('ann_${item.id}');
        }
        return;
      }

      final now = DateTime.now();
      for (final item in announcements) {
        final seenKey = 'ann_${item.id}';
        final seen = await notifService.hasSeenNotification(seenKey);
        if (!seen) {
          await notifService.markSeenNotification(seenKey);
          if (now.difference(item.createdAt).inHours < 24) {
            final int notifId = item.id.hashCode.abs() % 100000 + 200000;
            await notifService.showSystemNotification(
              id: notifId,
              title: '📢 Circular: ${item.title}',
              body: item.message,
              payload: 'announcements',
              isEmergency:
                  item.priority == 'high' || item.priority == 'emergency',
            );
            debugPrint(
              'Triggered system circular notification for: ${item.title}',
            );
          }
        }
      }
    });
  });

  // Listen to incoming chat messages
  ref.listen(userChatsStreamProvider, (previous, next) {
    next.whenData((chats) async {
      if (previous == null || previous.isLoading) {
        // Init state, mark all current chats as 'seen' based on their last message
        for (final chat in chats) {
          if (chat.lastMessageTime != null) {
            await notifService.markSeenNotification(
              'chat_${chat.id}_${chat.lastMessageTime!.millisecondsSinceEpoch}',
            );
          }
        }
        return;
      }

      final now = DateTime.now();

      for (final chat in chats) {
        if (chat.lastMessageTime == null) continue;

        // Ensure we don't notify for messages we just sent
        // (In a real app we'd check if the last message senderId != myId,
        // but here we just check if it's recent and not seen)

        final seenKey =
            'chat_${chat.id}_${chat.lastMessageTime!.millisecondsSinceEpoch}';
        final seen = await notifService.hasSeenNotification(seenKey);

        if (!seen) {
          await notifService.markSeenNotification(seenKey);

          if (now.difference(chat.lastMessageTime!).inHours < 1) {
            final int notifId = chat.id.hashCode.abs() % 100000 + 300000;

            await notifService.showChatMessageNotification(
              id: notifId,
              senderName:
                  chat.groupMetadata?['name'] ??
                  'Chat', // In groups this would be sender's name
              message: chat.lastMessage ?? 'New message',
              chatId: chat.id,
              isSilent: false, // Could read from user settings if chat is muted
            );

            debugPrint(
              'Triggered chat notification for: ${chat.groupMetadata?['name'] ?? 'Chat'}',
            );
          }
        }
      }
    });
  });
});
