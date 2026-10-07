import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../../../core/widgets/fade_slide_in.dart';
import '../../../../core/widgets/animated_state_switcher.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/notification_item_model.dart';
import '../providers/notifications_provider.dart';

class NotificationInboxScreen extends ConsumerWidget {
  const NotificationInboxScreen({super.key});

  static final List<String> _categories = [
    'All',
    'Announcement',
    'Exam Reminder',
    'Assignment Reminder',
    'Emergency Alert',
    'Event Reminder',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeCategory = ref.watch(notificationsCategoryFilterProvider);
    final filteredAsync = ref.watch(filteredNotificationsProvider);
    final user = ref.watch(authControllerProvider).value;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header Bar
            _buildHeader(
              context,
              ref,
              filteredAsync.value ?? [],
              user?.id ?? '',
            ),
            SizedBox(height: 12.h),
            // Category Filter Pills
            _buildCategorySelector(ref, activeCategory),
            SizedBox(height: 16.h),
            // Notifications List
            Expanded(
              child: AnimatedStateSwitcher(
                child: filteredAsync.when(
                  loading: () => KeyedSubtree(
                    key: const ValueKey('notif_loading'),
                    child: AppShimmer(
                      child: ListView.separated(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 8.h,
                        ),
                        itemCount: 6,
                        separatorBuilder: (context, index) =>
                            SizedBox(height: 12.h),
                        itemBuilder: (context, index) =>
                            const SkeletonListTile(),
                      ),
                    ),
                  ),
                  error: (error, stack) => KeyedSubtree(
                    key: const ValueKey('notif_error'),
                    child: ErrorState(
                      title: 'Failed to load notifications',
                      message: AppErrorHandler.getErrorMessage(error),
                      onRetry: () =>
                          ref.refresh(notificationsStreamProvider),
                    ),
                  ),
                  data: (items) {
                    if (items.isEmpty) {
                      return KeyedSubtree(
                        key: const ValueKey('notif_empty'),
                        child: EmptyState(
                          icon: LucideIcons.bellOff,
                          title: 'No notifications right now',
                          subtitle: activeCategory == 'All'
                              ? 'You are completely caught up on all alerts and notices!'
                              : 'No alerts in the "$activeCategory" category.',
                        ),
                      );
                    }

                    return KeyedSubtree(
                      key: const ValueKey('notif_list'),
                      child: RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(notificationsStreamProvider);
                        },
                        color: AppColors.primary,
                        child: ListView.separated(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20.w,
                            vertical: 8.h,
                          ),
                          itemCount: items.length,
                          separatorBuilder: (context, index) =>
                              SizedBox(height: 12.h),
                          itemBuilder: (context, index) {
                            return FadeSlideIn(
                              index: index,
                              child: _buildNotificationCard(
                                context,
                                ref,
                                items[index],
                                user?.id ?? '',
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    List<NotificationItemModel> items,
    String userId,
  ) {
    final unreadIds = items
        .where((i) => !i.isReadBy(userId))
        .map((i) => i.id)
        .toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: Icon(
                    LucideIcons.arrowLeft,
                    color: AppColors.onSurface,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surfaceContainerLowest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notification Inbox',
                        style: AppTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Targeted alerts & updates',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (unreadIds.isNotEmpty && userId.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                ref
                    .read(notificationsRepositoryProvider)
                    .markAllAsRead(unreadIds, userId);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('All notifications marked as read'),
                  ),
                );
              },
              icon: Icon(
                LucideIcons.checkCheck,
                size: 16,
                color: AppColors.primary,
              ),
              label: Text(
                'Mark All Read',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector(WidgetRef ref, String activeCategory) {
    return SizedBox(
      height: 40.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        itemCount: _categories.length,
        separatorBuilder: (context, index) => SizedBox(width: 8.w),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = cat == activeCategory;
          return ChoiceChip(
            label: Text(
              cat,
              style: AppTypography.labelMedium.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.onPrimary : AppColors.textPrimary,
              ),
            ),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                ref.read(notificationsCategoryFilterProvider.notifier).state =
                    cat;
              }
            },
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.surfaceContainerLowest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
              side: BorderSide(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            showCheckmark: false,
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    WidgetRef ref,
    NotificationItemModel item,
    String userId,
  ) {
    final isRead = userId.isEmpty ? true : item.isReadBy(userId);
    final isEmergency =
        item.priority == 'emergency' || item.category == 'Emergency Alert';
    final isHigh = item.priority == 'high' || isEmergency;

    Color badgeColor = AppColors.primary;
    IconData icon = LucideIcons.bell;
    switch (item.category.toLowerCase()) {
      case 'emergency alert':
        badgeColor = AppColors.error;
        icon = LucideIcons.siren;
        break;
      case 'exam reminder':
        badgeColor = AppColors.warning;
        icon = LucideIcons.graduationCap;
        break;
      case 'assignment reminder':
        badgeColor = Color(0xFF8B5CF6);
        icon = LucideIcons.fileText;
        break;
      case 'event reminder':
        badgeColor = Color(0xFF06B6D4);
        icon = LucideIcons.calendar;
        break;
      case 'announcement':
      default:
        badgeColor = AppColors.primary;
        icon = LucideIcons.megaphone;
        break;
    }

    return InkWell(
      onTap: () {
        if (!isRead && userId.isNotEmpty) {
          ref.read(notificationsRepositoryProvider).markAsRead(item.id, userId);
        }
      },
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isEmergency
              ? AppColors.error.withValues(alpha: 0.08)
              : (isRead
                    ? AppColors.surfaceContainerLowest
                    : AppColors.primary.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isEmergency
                ? AppColors.error
                : (isRead
                      ? AppColors.outlineVariant.withValues(alpha: 0.25)
                      : AppColors.primary.withValues(alpha: 0.4)),
            width: isEmergency || !isRead ? 1.5 : 1.0,
          ),
          boxShadow: [
            if (!isRead)
              BoxShadow(
                color: badgeColor.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, size: 20, color: badgeColor),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  item.category.toUpperCase(),
                                  style: AppTypography.labelSmall.copyWith(
                                    color: badgeColor,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                if (isHigh) ...[
                                  SizedBox(width: 6.w),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6.w,
                                      vertical: 2.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.error.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(6.r),
                                    ),
                                    child: Text(
                                      item.priority.toUpperCase(),
                                      style: AppTypography.labelSmall.copyWith(
                                        color: AppColors.error,
                                        fontSize: 9.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              item.title,
                              style: AppTypography.titleMedium.copyWith(
                                fontWeight: isRead
                                    ? FontWeight.w600
                                    : FontWeight.w800,
                                color: AppColors.onSurface,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isRead)
                  Container(
                    width: 10.w,
                    height: 10.h,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              item.message,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                height: 1.4.h,
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.user,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Text(
                          item.sentBy,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatTimeAgo(item.sentAt),
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
