import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'pressable_scale.dart';

/// Clean EmptyState placeholder for zero-data views
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final double iconSize;

  const EmptyState({
    super.key,
    this.icon = LucideIcons.inbox,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.iconSize = 48,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final custom = context.customColors;

    return Center(
      child: Padding(
        padding: AppSpacing.p24,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: AppSpacing.p20,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: iconSize,
                color: theme.colorScheme.primary,
              ),
            ),
            AppSpacing.v16,
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            if (subtitle != null) ...[
              AppSpacing.v8,
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: custom.subtleText,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              AppSpacing.v24,
              PressableScale(
                onTap: onAction,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: AppRadius.k12,
                  ),
                  child: Text(
                    actionLabel!,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
