import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/chat_providers.dart';
import '../../domain/models/message_model.dart';
import '../../data/chat_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String chatTitle;

  const ChatScreen({super.key, required this.chatId, required this.chatTitle});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final user = ref.read(authControllerProvider).value;
    if (user == null) return;

    final message = MessageModel(
      id: '',
      chatId: widget.chatId,
      senderId: user.id,
      text: text,
      type: MessageType.text,
      status: MessageStatus.sent,
      timestamp: DateTime.now(),
    );

    ref.read(chatRepositoryProvider).sendMessage(message);
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesStreamProvider(widget.chatId));
    final currentUser = ref.watch(authControllerProvider).value;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.chatTitle,
          style: AppTypography.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: AppColors.onSurface),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(child: Text('No messages here yet.'));
                }

                // Mark unread messages as read
                if (currentUser != null) {
                  for (final message in messages) {
                    if (message.senderId != currentUser.id &&
                        message.status != MessageStatus.read) {
                      ref
                          .read(chatRepositoryProvider)
                          .markMessageRead(widget.chatId, message.id);
                    }
                  }
                }

                return ListView.builder(
                  reverse: true, // Newest at the bottom
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUser?.id;

                    return _MessageBubble(message: message, isMe: isMe);
                  },
                );
              },
              loading: () => Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.symmetric(
        horizontal: 8.w,
        vertical: 12.h,
      ).copyWith(bottom: MediaQuery.of(context).padding.bottom + 12),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.add_circle_outline,
              color: AppColors.primary,
            ),
            onPressed: () {
              // open attachment menu (images, documents, voice)
            },
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                filled: true,
                fillColor: AppColors.background,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 12.h,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.r),
                  borderSide: BorderSide.none,
                ),
              ),
              minLines: 1,
              maxLines: 5,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send_rounded, color: AppColors.primary),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h, top: 4.h),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16.r).copyWith(
            bottomRight: isMe
                ? Radius.circular(4.r)
                : Radius.circular(16.r),
            bottomLeft: isMe
                ? Radius.circular(16.r)
                : Radius.circular(4.r),
          ),
          border: isMe
              ? null
              : Border.all(color: AppColors.outline.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isMe ? AppColors.onPrimary : AppColors.onSurface,
                fontSize: 15.sp,
              ),
            ),
            if (isMe) ...[SizedBox(height: 2.h), _buildStatusIcon()],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    IconData iconData;
    Color iconColor = AppColors.onPrimary.withValues(alpha: 0.7);

    // Use localStatus if available (e.g., for 'pending')
    if (message.localStatus == 'pending') {
      iconData = Icons.access_time_rounded;
    } else {
      switch (message.status) {
        case MessageStatus.sent:
          iconData = Icons.check_rounded;
          break;
        case MessageStatus.delivered:
          iconData = Icons.done_all_rounded;
          break;
        case MessageStatus.read:
          iconData = Icons.done_all_rounded;
          iconColor = Colors.blue.shade200; // distinct color for read
          break;
      }
    }

    return Icon(iconData, size: 12, color: iconColor);
  }
}
