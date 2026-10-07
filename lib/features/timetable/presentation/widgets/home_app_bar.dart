import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../class_join/presentation/providers/class_provider.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../../../chat/presentation/widgets/sync_status_indicator.dart';

/// Collapsing SliverAppBar.large for the Home dashboard feed.
/// Watches unread count, auth name, and active class in isolation.
class HomeSliverAppBar extends ConsumerWidget {
  final VoidCallback onOpenMore;
  final VoidCallback onOpenProfile;

  const HomeSliverAppBar({
    super.key,
    required this.onOpenMore,
    required this.onOpenProfile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentClass = ref.watch(currentClassProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final userName = ref.watch(authControllerProvider.select((a) => a.value?.name));

    return SliverAppBar.large(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
      scrolledUnderElevation: 0,
      pinned: true,
      floating: false,
      leading: IconButton(
        icon: const Icon(
          Icons.menu_rounded,
          color: AppColors.primary,
          size: 26,
        ),
        tooltip: 'More options',
        onPressed: onOpenMore,
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(7.w),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: AppColors.onPrimary,
              size: 18,
            ),
          ),
          SizedBox(width: 10.w),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Campusly',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                if (currentClass != null)
                  Text(
                    currentClass.code,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Global Sync Status
        const Center(child: SyncStatusIndicator()),
        SizedBox(width: 4.w),

        // Class switcher button
        IconButton(
          onPressed: () => context.push('/join-class-choice'),
          tooltip: 'Switch or Join Class',
          icon: Container(
            padding: EdgeInsets.all(7.w),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.swap_horiz_rounded,
              color: AppColors.primary,
              size: 19,
            ),
          ),
        ),

        // Folded Chat FAB into Header (Phase B requirement)
        IconButton(
          onPressed: () => context.push('/inbox'),
          tooltip: 'Chat & Messages',
          icon: Container(
            padding: EdgeInsets.all(7.w),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: AppColors.primary,
              size: 19,
            ),
          ),
        ),

        // Notification icon with badge
        IconButton(
          onPressed: () => context.push('/notifications'),
          tooltip: 'Notification Center',
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.notifications_none_rounded,
                color: AppColors.onSurfaceVariant,
                size: 24,
              ),
              if (unreadCount > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 1.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(width: 4.w),

        // Profile Avatar
        GestureDetector(
          onTap: onOpenProfile,
          child: Padding(
            padding: EdgeInsets.only(right: 14.w),
            child: CircleAvatar(
              radius: 17.r,
              backgroundColor: AppColors.primary,
              child: Text(
                (userName?.trim().isNotEmpty == true)
                    ? userName!.trim()[0].toUpperCase()
                    : 'S',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Legacy / standalone AppBar fallback.
class HomeAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final VoidCallback onOpenDrawer;
  final VoidCallback onOpenProfile;

  const HomeAppBar({
    super.key,
    required this.onOpenDrawer,
    required this.onOpenProfile,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentClass = ref.watch(currentClassProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final userName = ref.watch(authControllerProvider.select((a) => a.value?.name));

    return AppBar(
      backgroundColor: AppColors.surface.withValues(alpha: 0.9),
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.menu_rounded,
          color: AppColors.primary,
          size: 26,
        ),
        tooltip: 'More options',
        onPressed: onOpenDrawer,
      ),
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: AppColors.onPrimary,
              size: 20,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Campusly',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                if (currentClass != null)
                  Text(
                    currentClass.code,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        const Center(child: SyncStatusIndicator()),
        SizedBox(width: 8.w),
        IconButton(
          onPressed: () => context.push('/join-class-choice'),
          tooltip: 'Switch or Join Class',
          icon: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.swap_horiz_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
        ),
        IconButton(
          onPressed: () => context.push('/inbox'),
          tooltip: 'Chat & Messages',
          icon: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
        ),
        IconButton(
          onPressed: () => context.push('/notifications'),
          tooltip: 'Notification Center',
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.notifications_none_rounded,
                color: AppColors.onSurfaceVariant,
                size: 26,
              ),
              if (unreadCount > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 1.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(width: 4.w),
        GestureDetector(
          onTap: onOpenProfile,
          child: Padding(
            padding: EdgeInsets.only(right: 16.0.w),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary,
              child: Text(
                (userName?.trim().isNotEmpty == true)
                    ? userName!.trim()[0].toUpperCase()
                    : 'S',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
