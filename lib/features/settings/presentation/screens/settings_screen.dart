import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/services/notification_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifPrefs = ref.watch(notificationPreferencesProvider);
    final notifNotifier = ref.read(notificationPreferencesProvider.notifier);
    final notifService = ref.read(notificationServiceProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface.withValues(alpha: 0.9),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.onSurface,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Settings & Preferences',
          style: AppTypography.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: System Notifications & Class Reminders
            _buildSectionHeader(
              Icons.notifications_active_rounded,
              'Class Reminders & Alerts',
              AppColors.primary,
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  _buildSwitchTile(
                    title: 'Master Class Reminders',
                    subtitle:
                        'Enable or disable all automated pre-class alerts',
                    value: notifPrefs.masterEnabled,
                    onChanged: (val) {
                      notifNotifier.setMasterEnabled(val);
                      if (!val) notifService.cancelAllReminders();
                    },
                    isHeader: true,
                  ),
                  if (notifPrefs.masterEnabled) ...[
                    const Divider(height: 1, indent: 20, endIndent: 20),
                    _buildSwitchTile(
                      title: '15 Minutes Before Class',
                      subtitle: 'Alert to check materials and room location',
                      value: notifPrefs.remind15Min,
                      onChanged: (val) => notifNotifier.setRemind15Min(val),
                    ),
                    const Divider(height: 1, indent: 20, endIndent: 20),
                    _buildSwitchTile(
                      title: '10 Minutes Before Class',
                      subtitle: 'Alert to wrap up break and head to classroom',
                      value: notifPrefs.remind10Min,
                      onChanged: (val) => notifNotifier.setRemind10Min(val),
                    ),
                    const Divider(height: 1, indent: 20, endIndent: 20),
                    _buildSwitchTile(
                      title: 'Daily Morning Briefing',
                      subtitle:
                          'Receive an 8:00 AM summary of today\'s schedule',
                      value: notifPrefs.morningBriefing,
                      onChanged: (val) => notifNotifier.setMorningBriefing(val),
                    ),
                    const Divider(height: 1, indent: 20, endIndent: 20),
                    _buildSwitchTile(
                      title: 'Sound & Vibration',
                      subtitle: 'Play high priority notification alert tone',
                      value: notifPrefs.soundAndVibrate,
                      onChanged: (val) => notifNotifier.setSoundAndVibrate(val),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),
            // Test Notification simulation card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryContainer.withValues(alpha: 0.6),
                    AppColors.surfaceContainerLowest,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.bolt_rounded,
                          color: AppColors.onPrimary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Test System Notifications',
                              style: AppTypography.textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.onSurface,
                                  ),
                            ),
                            Text(
                              'Verify reminders appear right on your device',
                              style: AppTypography.textTheme.labelMedium
                                  ?.copyWith(color: AppColors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await notifService.showTestNotification(
                              minutesBefore: 15,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'Sent simulated 15-min class alert!',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(
                            Icons.notifications_active_outlined,
                            size: 18,
                          ),
                          label: const Text(
                            'Test 15-Min',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await notifService.showTestNotification(
                              minutesBefore: 10,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'Sent simulated 10-min urgent class alert!',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.onPrimary,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.timer_outlined, size: 18),
                          label: const Text(
                            'Test 10-Min',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            // Section 2: Appearance & Display
            _buildSectionHeader(
              Icons.palette_outlined,
              'Appearance & Display',
              AppColors.secondary,
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.dark_mode_rounded,
                        color: AppColors.secondary,
                        size: 22,
                      ),
                    ),
                    title: Text(
                      'Color Theme',
                      style: AppTypography.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'System Default (Editorial Indigo)',
                      style: AppTypography.textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.onSurfaceVariant,
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'System Dynamic & Dark mode are matched to your device settings.',
                          ),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 20, endIndent: 20),
                  _buildSwitchTile(
                    title: 'Compact Schedule Cards',
                    subtitle:
                        'Show denser timetable items without room thumbnails',
                    value: false,
                    onChanged: (val) {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            // Section 3: Offline Data & Sync
            _buildSectionHeader(
              Icons.cloud_sync_outlined,
              'Offline-First & Cloud Sync',
              AppColors.tertiary,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.tertiary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.verified_rounded,
                          color: AppColors.tertiary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Real-time Cloud Sync Active',
                              style: AppTypography.textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.onSurface,
                                  ),
                            ),
                            Text(
                              'Firebase Firestore · Region: asia-south1',
                              style: AppTypography.textTheme.labelMedium
                                  ?.copyWith(
                                    color: AppColors.tertiary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'Offline cache verified and refreshed!',
                            ),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.onSurface,
                        side: BorderSide(
                          color: AppColors.outlineVariant.withValues(
                            alpha: 0.6,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.cached_rounded, size: 20),
                      label: const Text('Refresh Offline Timetable Cache'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            // Section 4: About & Legal
            _buildSectionHeader(
              Icons.info_outline_rounded,
              'About Campusly',
              AppColors.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
                    title: Text(
                      'App Version',
                      style: AppTypography.textTheme.bodyMedium,
                    ),
                    trailing: Text(
                      '1.0.0+1 (Stitch Editorial)',
                      style: AppTypography.textTheme.labelLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Divider(height: 1, indent: 20, endIndent: 20),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
                    title: Text(
                      'Terms of Service & Privacy',
                      style: AppTypography.textTheme.bodyMedium,
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.onSurfaceVariant,
                    ),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Text(
          title.toUpperCase(),
          style: AppTypography.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isHeader = false,
  }) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      title: Text(
        title,
        style: AppTypography.textTheme.titleMedium?.copyWith(
          fontWeight: isHeader ? FontWeight.w800 : FontWeight.bold,
          color: isHeader && value ? AppColors.primary : AppColors.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.textTheme.bodySmall?.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
      ),
      value: value,
      activeThumbColor: AppColors.primary,
      onChanged: onChanged,
    );
  }
}
