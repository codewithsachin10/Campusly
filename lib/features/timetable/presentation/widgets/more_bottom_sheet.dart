import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/services/app_haptics.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../class_join/presentation/providers/class_provider.dart';
import '../../../curriculum/presentation/screens/curriculum_screen.dart';

/// Modal "More" bottom sheet replacing the legacy side navigation drawer.
class MoreBottomSheet extends ConsumerWidget {
  const MoreBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    AppHaptics.lightImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const MoreBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = ref.watch(authControllerProvider).value;
    final currentClass = ref.watch(currentClassProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 44.w,
                  height: 4.5.h,
                  margin: EdgeInsets.only(bottom: 16.h),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkOutline : AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(999.r),
                  ),
                ),
              ),

              // Student Profile Card
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  context.push('/profile-edit');
                },
                borderRadius: BorderRadius.circular(18.r),
                child: Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceContainer
                        : AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(18.r),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkOutlineVariant
                          : AppColors.primary.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26.r,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          user?.name.trim().isNotEmpty == true
                              ? user!.name.trim()[0].toUpperCase()
                              : 'S',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.name.trim().isNotEmpty == true
                                  ? user!.name.trim()
                                  : 'Student Profile',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              currentClass?.name ?? 'No active section',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (user?.email != null)
                              Text(
                                user!.email,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: isDark
                                      ? AppColors.darkOnSurfaceVariant
                                      : AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      Icon(
                        LucideIcons.chevronRight,
                        size: 20,
                        color: isDark
                            ? AppColors.darkOnSurfaceVariant
                            : AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20.h),

              // Navigation Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                mainAxisSpacing: 16.h,
                crossAxisSpacing: 12.w,
                childAspectRatio: 0.85,
                children: [
                  _buildQuickAction(
                    context,
                    icon: LucideIcons.map,
                    label: 'Campus Map',
                    color: const Color(0xFF0284C7),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/campus-map');
                    },
                  ),
                  _buildQuickAction(
                    context,
                    icon: LucideIcons.calendarCheck,
                    label: 'Events',
                    color: AppColors.coral,
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/events');
                    },
                  ),
                  _buildQuickAction(
                    context,
                    icon: LucideIcons.users,
                    label: 'Directory',
                    color: const Color(0xFF8B5CF6),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/people');
                    },
                  ),
                  _buildQuickAction(
                    context,
                    icon: LucideIcons.bookOpen,
                    label: 'Curriculum',
                    color: AppColors.mint,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CurriculumScreen(),
                        ),
                      );
                    },
                  ),
                  _buildQuickAction(
                    context,
                    icon: LucideIcons.lifeBuoy,
                    label: 'Helpdesk',
                    color: const Color(0xFFEC4899),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/helpdesk');
                    },
                  ),
                  _buildQuickAction(
                    context,
                    icon: LucideIcons.settings,
                    label: 'Settings',
                    color: const Color(0xFF64748B),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/settings');
                    },
                  ),
                  _buildQuickAction(
                    context,
                    icon: LucideIcons.info,
                    label: 'About',
                    color: const Color(0xFFF59E0B),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/about');
                    },
                  ),
                  _buildQuickAction(
                    context,
                    icon: themeMode == ThemeMode.dark
                        ? LucideIcons.sun
                        : LucideIcons.moon,
                    label: themeMode == ThemeMode.dark ? 'Light Mode' : 'Dark Mode',
                    color: const Color(0xFF6366F1),
                    onTap: () {
                      final notifier = ref.read(themeModeProvider.notifier);
                      notifier.setThemeMode(
                        themeMode == ThemeMode.dark
                            ? ThemeMode.light
                            : ThemeMode.dark,
                      );
                    },
                  ),
                ],
              ),

              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        AppHaptics.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(16.r),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48.w,
            height: 48.h,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.22 : 0.12),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(icon, color: color, size: 22.sp),
          ),
          SizedBox(height: 6.h),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkOnSurface : AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
