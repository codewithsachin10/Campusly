import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'pressable_scale.dart';

/// Clean ErrorState widget with friendly illustration and retry callback
class ErrorState extends StatelessWidget {
  final String title;
  final String? message;
  final VoidCallback? onRetry;
  final String retryLabel;
  final IconData icon;

  const ErrorState({
    super.key,
    this.title = 'Something went wrong',
    this.message,
    this.onRetry,
    this.retryLabel = 'Try Again',
    this.icon = LucideIcons.alertCircle,
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
                color: theme.colorScheme.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: theme.colorScheme.error,
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
            if (message != null && message!.isNotEmpty) ...[
              AppSpacing.v8,
              Text(
                message!,
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: custom.subtleText,
                ),
              ),
            ],
            if (onRetry != null) ...[
              AppSpacing.v24,
              PressableScale(
                onTap: onRetry,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: AppRadius.k12,
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.refreshCw,
                        size: 16,
                        color: theme.colorScheme.onPrimary,
                      ),
                      AppSpacing.h8,
                      Text(
                        retryLabel,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
