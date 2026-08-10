import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/support_ticket.dart';
import '../providers/support_provider.dart';
import '../widgets/gradient_text.dart';
import '../widgets/ticket_status_badge.dart';
import '../widgets/activity_timeline.dart';

class TicketDetailsScreen extends ConsumerStatefulWidget {
  final SupportTicket ticket;

  const TicketDetailsScreen({super.key, required this.ticket});

  @override
  ConsumerState<TicketDetailsScreen> createState() => _TicketDetailsScreenState();
}

class _TicketDetailsScreenState extends ConsumerState<TicketDetailsScreen> {
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);

    try {
      final repo = ref.read(supportRepositoryProvider);
      await repo.sendMessage(ticketId: widget.ticket.id, message: text);
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 0) return '${diff.inDays} days ago';
    if (diff.inHours > 0) return '${diff.inHours} hours ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes} minutes ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    final messagesStream = ref.watch(ticketMessagesStreamProvider(widget.ticket.id));
    final studentData = widget.ticket.student ?? {};
    final studentName = studentData['name'] ?? 'Unknown Student';
    final rollNo = studentData['roll_no'] ?? 'N/A';
    final initials = studentName.isNotEmpty ? studentName.substring(0, 2).toUpperCase() : '??';
    final branch = studentData['branch'] ?? 'Unknown';
    final section = studentData['section'] ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: GradientText(
          'Ticket #${widget.ticket.ticketNumber.substring(0, 7)}',
          gradient: const LinearGradient(
            colors: [Color(0xFF4285F4), Color(0xFFE91E63)],
          ),
          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.moreVertical, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main Glow Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE91E63).withOpacity(0.08),
                          blurRadius: 40,
                          offset: const Offset(-10, 10),
                        ),
                        BoxShadow(
                          color: const Color(0xFF4285F4).withOpacity(0.08),
                          blurRadius: 40,
                          offset: const Offset(10, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TicketStatusBadge(status: widget.ticket.status),
                            Text(
                              _timeAgo(widget.ticket.createdAt),
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.ticket.subject,
                          style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFCE4EC),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            widget.ticket.categoryId ?? 'General',
                            style: const TextStyle(color: Color(0xFF880E4F), fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Student Details Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.surfaceVariant),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFF5C6BC0),
                          child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(studentName, style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                              Text('Student', style: TextStyle(color: const Color(0xFF7E57C2), fontSize: 12)),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: AppColors.surfaceVariant,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Roll', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              Text(rollNo, style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Description
                  const Text('DESCRIPTION', style: TextStyle(color: Color(0xFF4285F4), fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.surfaceVariant),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(4, 0), // left border effect
                        ),
                      ],
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFFAB47BC),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.ticket.description,
                              style: AppTypography.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Activity
                  const Text('ACTIVITY', style: TextStyle(color: Color(0xFFE91E63), fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 12),
                  ActivityTimeline(currentStatus: widget.ticket.status),
                  const SizedBox(height: 24),
                  
                  // Chat Messages Timeline
                  messagesStream.when(
                    data: (messagesRaw) {
                      final messages = messagesRaw.where((m) => m['is_internal'] != true).toList();
                      
                      return ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final isAdmin = msg['sender_type'] == 'Admin';
                          
                          return IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Timeline line and dot
                                Column(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: isAdmin ? const Color(0xFFEDE7F6) : const Color(0xFFF3E5F5),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Icon(
                                          isAdmin ? LucideIcons.userCheck : LucideIcons.sparkles, 
                                          size: 12, 
                                          color: isAdmin ? const Color(0xFF5E35B1) : const Color(0xFF8E24AA)
                                        ),
                                      ),
                                    ),
                                    if (index != messages.length - 1)
                                      Expanded(
                                        child: Container(
                                          width: 2,
                                          color: const Color(0xFFF3E5F5),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 24),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: AppColors.surfaceVariant),
                                    ),
                                    child: IntrinsicHeight(
                                      child: Row(
                                        children: [
                                          if (isAdmin)
                                            Container(
                                              width: 4,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF7E57C2),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              margin: const EdgeInsets.only(right: 12),
                                            ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      isAdmin ? 'Admin (IT Support)' : 'Ticket created by System',
                                                      style: TextStyle(
                                                        color: isAdmin ? const Color(0xFF7E57C2) : AppColors.textPrimary,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    Text(
                                                      _timeAgo(DateTime.parse(msg['created_at'])),
                                                      style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Text(msg['message'], style: AppTypography.bodyMedium),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom Chat Input
          if (widget.ticket.status != 'Closed' && widget.ticket.status != 'Resolved')
            Container(
              padding: const EdgeInsets.all(16).copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                border: const Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.paperclip, color: Color(0xFF9C27B0)),
                    onPressed: () {},
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.surfaceVariant),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Type your reply...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF4285F4), Color(0xFF9C27B0)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: _isSending 
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 24, height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(LucideIcons.send, color: Colors.white, size: 20),
                          onPressed: _sendMessage,
                        ),
                  ),
                ],
              ),
            )
          else 
            Container(
              padding: const EdgeInsets.all(24).copyWith(bottom: MediaQuery.of(context).padding.bottom + 24),
              color: const Color(0xFFF8F9FA),
              child: const Center(
                child: Text('This ticket is closed.'),
              ),
            )
        ],
      ),
    );
  }
}

