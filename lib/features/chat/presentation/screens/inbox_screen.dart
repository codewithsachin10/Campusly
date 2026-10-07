import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/chat_providers.dart';
import '../../domain/models/chat_model.dart';

import 'package:intl/intl.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../connect/data/connections_repository.dart';
import '../../../auth/domain/models/user_model.dart';

final chatUserProvider = FutureProvider.family<UserModel?, String>((
  ref,
  userId,
) async {
  return ref.read(connectionsRepositoryProvider).getUser(userId);
});

class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(userChatsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Messages',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.group_rounded, color: AppColors.primary),
            tooltip: 'Create Group',
            onPressed: () {
              context.push('/create-group');
            },
          ),
        ],
      ),
      body: chatsAsync.when(
        data: (chats) {
          if (chats.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.0.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 64,
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'No Messages Yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Connect with people or check your class communities.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              return _ChatListTile(chat: chat);
            },
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/people-directory');
        },
        backgroundColor: AppColors.primary,
        child: Icon(Icons.chat_rounded, color: Colors.white),
      ),
    );
  }
}

class _ChatListTile extends ConsumerWidget {
  final ChatModel chat;

  const _ChatListTile({required this.chat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String title = 'Chat';
    IconData icon = Icons.person_rounded;
    Color iconColor = AppColors.primary;

    final currentUserId = ref.watch(authControllerProvider).value?.id;

    if (chat.type == ChatType.community) {
      title = chat.groupMetadata?['name'] ?? 'Community';
      icon = Icons.school_rounded;
      iconColor = Colors.orange;
    } else if (chat.type == ChatType.group) {
      title = chat.groupMetadata?['name'] ?? 'Group Chat';
      icon = Icons.group_rounded;
      iconColor = Colors.green;
    } else {
      final otherUserId = chat.participants.firstWhere(
        (id) => id != currentUserId,
        orElse: () => '',
      );
      if (otherUserId.isNotEmpty) {
        final otherUserAsync = ref.watch(chatUserProvider(otherUserId));
        title = otherUserAsync.when(
          data: (user) => user?.name ?? 'Unknown User',
          loading: () => 'Loading...',
          error: (e, st) => 'Private Chat',
        );
      } else {
        title = 'Private Chat';
      }
    }

    String timeStr = '';
    if (chat.lastMessageTime != null) {
      final now = DateTime.now();
      final diff = now.difference(chat.lastMessageTime!);
      if (diff.inDays > 0) {
        timeStr = DateFormat('MMM d').format(chat.lastMessageTime!);
      } else {
        timeStr = DateFormat('h:mm a').format(chat.lastMessageTime!);
      }
    }

    return Card(
      elevation: 0,
      margin: EdgeInsets.only(bottom: 8.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(color: AppColors.outline.withValues(alpha: 0.1)),
      ),
      color: AppColors.surface,
      child: ListTile(
        contentPadding: EdgeInsets.all(12.w),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: iconColor.withValues(alpha: 0.15),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 4.0.h),
          child: Text(
            chat.lastMessage ?? 'Say hi!',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14.sp),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: timeStr.isNotEmpty
            ? Text(
                timeStr,
                style: TextStyle(color: Colors.grey, fontSize: 12.sp),
              )
            : null,
        onTap: () {
          context.push('/chat/${chat.id}?title=${Uri.encodeComponent(title)}');
        },
      ),
    );
  }
}
