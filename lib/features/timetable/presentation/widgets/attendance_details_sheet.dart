import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/attendance_model.dart';
import '../providers/attendance_provider.dart';

class AttendanceDetailsSheet extends ConsumerStatefulWidget {
  final String subjectCode;
  final String subjectName;

  const AttendanceDetailsSheet({
    super.key,
    required this.subjectCode,
    required this.subjectName,
  });

  static void show(BuildContext context, {required String subjectCode, required String subjectName}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AttendanceDetailsSheet(
        subjectCode: subjectCode,
        subjectName: subjectName,
      ),
    );
  }

  @override
  ConsumerState<AttendanceDetailsSheet> createState() => _AttendanceDetailsSheetState();
}

class _AttendanceDetailsSheetState extends ConsumerState<AttendanceDetailsSheet> {
  void _showEditCountsDialog(AttendanceModel current) {
    final presentCtrl = TextEditingController(text: current.presentCount.toString());
    final totalCtrl = TextEditingController(text: current.totalCount.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Edit Attendance Counts', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: presentCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'No. of Classes Present',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: totalCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Total Classes Held',
                border: OutlineInputBorder(),
              ),
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
              final present = int.tryParse(presentCtrl.text) ?? current.presentCount;
              final total = int.tryParse(totalCtrl.text) ?? current.totalCount;
              final user = ref.read(authControllerProvider).value;
              if (user != null) {
                final key = AttendanceQueryKey(
                  userId: user.id,
                  subjectCode: widget.subjectCode,
                  subjectName: widget.subjectName,
                );
                ref.read(attendanceProvider(key).notifier).updateCounts(present, total);
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value;
    if (user == null) return const SizedBox.shrink();

    final key = AttendanceQueryKey(
      userId: user.id,
      subjectCode: widget.subjectCode,
      subjectName: widget.subjectName,
    );
    final asyncAttendance = ref.watch(attendanceProvider(key));

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(LucideIcons.calendarCheck, color: AppColors.primary, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.subjectName,
                      style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Attendance & Smart Bunk Calculator',
                      style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              asyncAttendance.when(
                data: (model) => IconButton(
                  onPressed: () => _showEditCountsDialog(model),
                  icon: const Icon(LucideIcons.edit3, color: AppColors.primary),
                  tooltip: 'Edit Counts',
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Expanded(
            child: asyncAttendance.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (model) {
                final pct = model.percentage;
                final isRisk = model.willDropBelowIfMissedNext || pct < 75.0;
                final safeBunks = model.safeBunkClasses;

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatBox(
                              label: 'Present',
                              value: '${model.presentCount}',
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatBox(
                              label: 'Total Classes',
                              value: '${model.totalCount}',
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatBox(
                              label: 'Attendance %',
                              value: '${pct.toStringAsFixed(1)}%',
                              color: isRisk ? AppColors.error : AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Smart Bunk Predictor Banner
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isRisk
                              ? AppColors.error.withValues(alpha: 0.12)
                              : AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isRisk ? AppColors.error : AppColors.success,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isRisk ? LucideIcons.alertTriangle : LucideIcons.shieldCheck,
                              color: isRisk ? AppColors.error : AppColors.success,
                              size: 28,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isRisk ? '⚠️ Attendance Alert' : '✅ Smart Bunk Predictor',
                                    style: AppTypography.titleSmall.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isRisk ? AppColors.error : AppColors.success,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isRisk
                                        ? "Warning: If you miss today's class, your attendance will drop below 75% REC criterion!"
                                        : "You can safely miss the next $safeBunks classes and stay above your 75% REC criterion.",
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Quick Log Section
                      Text('Log Today\'s Class Status', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              title: 'Present ✅',
                              color: AppColors.success,
                              onTap: () => ref.read(attendanceProvider(key).notifier).markStatus('present'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildActionButton(
                              title: 'Absent ❌',
                              color: AppColors.error,
                              onTap: () => ref.read(attendanceProvider(key).notifier).markStatus('absent'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildActionButton(
                              title: 'Cancelled 🚫',
                              color: AppColors.warning,
                              onTap: () => ref.read(attendanceProvider(key).notifier).markStatus('cancelled'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // History Log
                      Text('Recent Class Log Details', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      if (model.history.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'No dates marked yet. Tap Present or Absent above when your class finishes!',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: model.history.length,
                          itemBuilder: (context, idx) {
                            final log = model.history[idx];
                            final isP = log.status == 'present';
                            final isA = log.status == 'absent';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(log.dateString, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: (isP
                                              ? AppColors.success
                                              : isA
                                                  ? AppColors.error
                                                  : AppColors.warning)
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      isP
                                          ? 'Present ✅'
                                          : isA
                                              ? 'Absent ❌'
                                              : 'Cancelled 🚫',
                                      style: AppTypography.labelSmall.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: isP
                                            ? AppColors.success
                                            : isA
                                                ? AppColors.error
                                                : AppColors.warning,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox({required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(value, style: AppTypography.headlineMedium.copyWith(color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildActionButton({required String title, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color),
        ),
        child: Text(title, style: AppTypography.labelMedium.copyWith(color: color, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
