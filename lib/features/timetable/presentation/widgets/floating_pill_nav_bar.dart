import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/services/app_haptics.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';

class FloatingPillNavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const FloatingPillNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

/// Floating capsule navigation bar with a smooth animated sliding indicator.
class FloatingPillNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<FloatingPillNavItem> items;

  const FloatingPillNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
        child: Container(
          height: 64.h,
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurfaceContainer
                : AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(32.r),
            border: Border.all(
              color: isDark
                  ? AppColors.darkOutlineVariant
                  : AppColors.outlineVariant.withValues(alpha: 0.4),
              width: 1.2,
            ),
            boxShadow: AppShadows.cardShadow,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tabWidth = constraints.maxWidth / items.length;

              return Stack(
                children: [
                  // Smooth animated sliding capsule indicator
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    left: selectedIndex * tabWidth + 4.w,
                    top: 6.h,
                    width: tabWidth - 8.w,
                    height: constraints.maxHeight - 12.h,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(24.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Destination Items
                  Row(
                    children: List.generate(items.length, (index) {
                      final item = items[index];
                      final isSelected = selectedIndex == index;

                      return Expanded(
                        child: InkWell(
                          onTap: () {
                            if (selectedIndex != index) {
                              AppHaptics.selectionClick();
                              onDestinationSelected(index);
                            }
                          },
                          borderRadius: BorderRadius.circular(24.r),
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          child: Center(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Column(
                                key: ValueKey<bool>(isSelected),
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isSelected ? item.selectedIcon : item.icon,
                                    size: 22.sp,
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark
                                            ? AppColors.darkOnSurfaceVariant
                                            : AppColors.onSurfaceVariant),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    item.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10.5.sp,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? Colors.white
                                          : (isDark
                                              ? AppColors.darkOnSurfaceVariant
                                              : AppColors.onSurfaceVariant),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
