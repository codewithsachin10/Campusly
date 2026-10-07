import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/support_provider.dart';
import '../widgets/ticket_status_badge.dart';
import 'ticket_details_screen.dart';
import 'package:intl/intl.dart';

class MyTicketsScreen extends ConsumerStatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  ConsumerState<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends ConsumerState<MyTicketsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final myTicketsAsync = ref.watch(myTicketsProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Support Tickets',
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0.w, vertical: 12.0.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Support Requests',
                  style: AppTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Real-time status updates from campus staff and admins.',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                SizedBox(height: 16.h),
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: AppTypography.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Search by ticket ID or subject...',
                      hintStyle: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary.withValues(alpha: 0.6),
                      ),
                      prefixIcon: Icon(
                        LucideIcons.search,
                        size: 18.sp,
                        color: AppColors.textSecondary,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: myTicketsAsync.when(
              data: (tickets) {
                final filtered = tickets.where((t) {
                  final query = _searchQuery.toLowerCase();
                  return t.subject.toLowerCase().contains(query) ||
                      t.ticketNumber.toLowerCase().contains(query);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.w),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.inbox, size: 40.sp, color: AppColors.textSecondary),
                          SizedBox(height: 12.h),
                          Text(
                            'No tickets found',
                            style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No requests match "$_searchQuery"'
                                : 'You have not submitted any support tickets yet.',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final ticket = filtered[index];
                    return RepaintBoundary(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TicketDetailsScreen(ticket: ticket),
                            ),
                          );
                        },
                        child: Container(
                          margin: EdgeInsets.only(bottom: 12.h),
                          padding: EdgeInsets.all(18.w),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(18.r),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    child: Text(
                                      ticket.ticketNumber.length > 7 ? ticket.ticketNumber.substring(0, 7) : ticket.ticketNumber,
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                  ),
                                  TicketStatusBadge(status: ticket.status),
                                ],
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                ticket.subject,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                'Last updated: ${DateFormat('MMM d, y, h:mm a').format(ticket.updatedAt)}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error loading tickets: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

