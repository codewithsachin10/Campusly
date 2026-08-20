import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
        duration: Duration(milliseconds: 300),
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
          icon: Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: GradientText(
          'Ticket #${widget.ticket.ticketNumber.length > 7 ? widget.ticket.ticketNumber.substring(0, 7) : widget.ticket.ticketNumber}',
          gradient: LinearGradient(
            colors: [Color(0xFF4285F4), Color(0xFFE91E63)],
          ),
          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.moreVertical, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main Glow Card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFFE91E63).withOpacity(0.08),
                          blurRadius: 40,
                          offset: Offset(-10, 10),
                        ),
                        BoxShadow(
                          color: Color(0xFF4285F4).withOpacity(0.08),
                          blurRadius: 40,
                          offset: Offset(10, 10),
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
                        SizedBox(height: 16.h),
                        Text(
                          widget.ticket.subject,
                          style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 12.h),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: Color(0xFFFCE4EC),
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          child: Text(
                            widget.ticket.categoryId ?? 'General',
                            style: TextStyle(color: Color(0xFF880E4F), fontSize: 12.sp),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),
                  
                  // Student Details Box
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: AppColors.surfaceVariant),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Color(0xFF5C6BC0),
                          child: Text(initials, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(studentName, style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text('Student', style: TextStyle(color: Color(0xFF7E57C2), fontSize: 12.sp)),
                            ],
                          ),
                        ),
                        Container(
                          width: 1.w,
                          height: 40.h,
                          color: AppColors.surfaceVariant,
                          margin: EdgeInsets.symmetric(horizontal: 16.w),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Roll', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp)),
                              Text(rollNo, style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Description
                  Text('DESCRIPTION', style: TextStyle(color: Color(0xFF4285F4), fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  SizedBox(height: 12.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: AppColors.surfaceVariant),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(4, 0), // left border effect
                        ),
                      ],
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          Container(
                            width: 4.w,
                            decoration: BoxDecoration(
                              color: Color(0xFFAB47BC),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                          ),
                          SizedBox(width: 12.w),
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
                  SizedBox(height: 24.h),

                  // Activity
                  Text('ACTIVITY', style: TextStyle(color: Color(0xFFE91E63), fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  SizedBox(height: 12.h),
                  ActivityTimeline(currentStatus: widget.ticket.status),
                  SizedBox(height: 24.h),
                  
                  // Chat Messages Timeline
                  messagesStream.when(
                    data: (messagesRaw) {
                      final messages = messagesRaw.where((m) => m['is_internal'] != true).toList();
                      
                      return ListView.builder(
                        physics: NeverScrollableScrollPhysics(),
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
                                      width: 24.w,
                                      height: 24.h,
                                      decoration: BoxDecoration(
                                        color: isAdmin ? Color(0xFFEDE7F6) : Color(0xFFF3E5F5),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Icon(
                                          isAdmin ? LucideIcons.userCheck : LucideIcons.sparkles, 
                                          size: 12, 
                                          color: isAdmin ? Color(0xFF5E35B1) : Color(0xFF8E24AA)
                                        ),
                                      ),
                                    ),
                                    if (index != messages.length - 1)
                                      Expanded(
                                        child: Container(
                                          width: 2.w,
                                          color: Color(0xFFF3E5F5),
                                        ),
                                      ),
                                  ],
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Container(
                                    margin: EdgeInsets.only(bottom: 24.h),
                                    padding: EdgeInsets.all(16.w),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16.r),
                                      border: Border.all(color: AppColors.surfaceVariant),
                                    ),
                                    child: IntrinsicHeight(
                                      child: Row(
                                        children: [
                                          if (isAdmin)
                                            Container(
                                              width: 4.w,
                                              decoration: BoxDecoration(
                                                color: Color(0xFF7E57C2),
                                                borderRadius: BorderRadius.circular(4.r),
                                              ),
                                              margin: EdgeInsets.only(right: 12.w),
                                            ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        isAdmin ? 'Admin (IT Support)' : 'Ticket created by System',
                                                        style: TextStyle(
                                                          color: isAdmin ? Color(0xFF7E57C2) : AppColors.textPrimary,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    SizedBox(width: 8.w),
                                                    Text(
                                                      _timeAgo(DateTime.parse(msg['created_at'])),
                                                      style: TextStyle(color: AppColors.textSecondary, fontSize: 10.sp),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 8.h),
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
                    loading: () => Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom Chat Input
          if (widget.ticket.status != 'Closed' && widget.ticket.status != 'Resolved')
            Container(
              padding: EdgeInsets.all(16.w).copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
              decoration: BoxDecoration(
                color: Color(0xFFF8F9FA),
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(LucideIcons.paperclip, color: Color(0xFF9C27B0)),
                    onPressed: () {},
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24.r),
                        border: Border.all(color: AppColors.surfaceVariant),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type your reply...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF4285F4), Color(0xFF9C27B0)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: _isSending 
                      ? Padding(
                          padding: EdgeInsets.all(12.0.w),
                          child: SizedBox(
                            width: 24.w, height: 24.h,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          icon: Icon(LucideIcons.send, color: Colors.white, size: 20),
                          onPressed: _sendMessage,
                        ),
                  ),
                ],
              ),
            )
          else 
            Container(
              padding: EdgeInsets.all(24.w).copyWith(bottom: MediaQuery.of(context).padding.bottom + 24),
              color: Color(0xFFF8F9FA),
              child: Center(
                child: Text('This ticket is closed.'),
              ),
            )
        ],
      ),
    );
  }
}

