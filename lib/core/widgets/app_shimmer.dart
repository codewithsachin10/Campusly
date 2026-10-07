import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// Theme-aware shimmer loading container
class AppShimmer extends StatelessWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;

  const AppShimmer({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    final custom = context.customColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final base = baseColor ?? custom.shimmerBase;
    final highlight = highlightColor ?? custom.shimmerHighlight;

    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disableAnimations) {
      return Opacity(
        opacity: isDark ? 0.3 : 0.6,
        child: child,
      );
    }

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      period: const Duration(milliseconds: 1500),
      child: child,
    );
  }
}

/// Generic rounded rectangle skeleton block
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadiusGeometry borderRadius;
  final Color? color;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = AppRadius.k8,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: borderRadius,
      ),
    );
  }
}

/// Standard Skeleton card matching app card geometry
class SkeletonCard extends StatelessWidget {
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry borderRadius;
  final Widget? child;

  const SkeletonCard({
    super.key,
    this.width,
    this.height = 140,
    this.padding = AppSpacing.p16,
    this.borderRadius = AppRadius.k16,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Container(
        width: width,
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius,
        ),
        child: child,
      ),
    );
  }
}

/// Skeleton representing a standard list item with avatar/badge and text rows
class SkeletonListTile extends StatelessWidget {
  final bool hasLeading;
  final bool hasTrailing;

  const SkeletonListTile({
    super.key,
    this.hasLeading = true,
    this.hasTrailing = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Padding(
        padding: AppSpacing.pv8,
        child: Row(
          children: [
            if (hasLeading) ...[
              const SkeletonBox(
                width: 44,
                height: 44,
                borderRadius: AppRadius.k12,
              ),
              AppSpacing.h12,
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SkeletonBox(
                    width: double.infinity,
                    height: 14,
                    borderRadius: AppRadius.k4,
                  ),
                  AppSpacing.v8,
                  SkeletonBox(
                    width: MediaQuery.sizeOf(context).width * 0.45,
                    height: 11,
                    borderRadius: AppRadius.k4,
                  ),
                ],
              ),
            ),
            if (hasTrailing) ...[
              AppSpacing.h12,
              const SkeletonBox(
                width: 28,
                height: 28,
                borderRadius: AppRadius.pill,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
