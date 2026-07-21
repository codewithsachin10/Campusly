import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/announcements_provider.dart';

class AnnouncementsBanner extends ConsumerWidget {
  const AnnouncementsBanner({super.key});

  void _showPostDialog(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController();
    final msgCtrl = TextEditingController();
    bool isHigh = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(LucideIcons.megaphone, color: AppColors.primary, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Post Live Announcement',
                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notice Title (e.g., Class Swap / Exam Update)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: msgCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Message Body...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('High Priority Alert Indicator'),
                value: isHigh,
                onChanged: (val) => setState(() => isHigh = val ?? true),
                activeColor: AppColors.primary,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty || msgCtrl.text.trim().isEmpty) return;
                ref.read(announcementsRepositoryProvider).postAnnouncement(
                      title: titleCtrl.text.trim(),
                      message: msgCtrl.text.trim(),
                      priority: isHigh ? 'high' : 'normal',
                    );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
              ),
              child: const Text('Broadcast Live'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAnn = ref.watch(announcementsStreamProvider);

    return asyncAnn.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row with Post Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.bellRing, color: AppColors.warning, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Live Campus & Class Notices',
                      style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => _showPostDialog(context, ref),
                  icon: const Icon(LucideIcons.plusCircle, size: 16, color: AppColors.primary),
                  label: const Text('Post Notice', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (items.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.2)),
                ),
                child: Text(
                  'No urgent announcements right now. All classes running as per schedule.',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                itemBuilder: (context, idx) {
                  final ann = items[idx];
                  final isHigh = ann.priority == 'high';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isHigh
                          ? AppColors.warning.withValues(alpha: 0.08)
                          : AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isHigh ? AppColors.warning : AppColors.outlineVariant.withValues(alpha: 0.3),
                        width: isHigh ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                if (isHigh) ...[
                                  const Icon(LucideIcons.alertTriangle, color: AppColors.warning, size: 18),
                                  const SizedBox(width: 6),
                                ],
                                Text(
                                  ann.title,
                                  style: AppTypography.titleSmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isHigh ? AppColors.warning : AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              onPressed: () => ref.read(announcementsRepositoryProvider).deleteAnnouncement(ann.id),
                              icon: const Icon(LucideIcons.x, size: 16, color: AppColors.textSecondary),
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(4),
                              tooltip: 'Clear Notice',
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          ann.message,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Posted by ${ann.author} • ${_formatTimeAgo(ann.createdAt)}',
                          style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary.withValues(alpha: 0.8)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours} hrs ago';
    return '${diff.inDays} days ago';
  }
}
