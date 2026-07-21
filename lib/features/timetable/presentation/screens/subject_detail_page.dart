import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/timetable_item.dart';
import '../providers/attendance_provider.dart';
import '../providers/notes_provider.dart';
import '../widgets/attendance_details_sheet.dart';
import '../widgets/subject_notes_hub_sheet.dart';
import '../widgets/faculty_profile_sheet.dart';

class SubjectDetailPage extends ConsumerWidget {
  final TimetableItem item;

  const SubjectDetailPage({super.key, required this.item});

  static void navigate(BuildContext context, TimetableItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SubjectDetailPage(item: item)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    final code = (item.subjectCode != null && item.subjectCode!.isNotEmpty) ? item.subjectCode! : item.title;
    final attKey = user != null
        ? AttendanceQueryKey(
            userId: user.id,
            subjectCode: code,
            subjectName: item.title,
          )
        : null;
    final notesKey = user != null
        ? NotesQueryKey(
            userId: user.id,
            subjectCode: code,
          )
        : null;

    final asyncAtt = attKey != null ? ref.watch(attendanceProvider(attKey)) : const AsyncValue.data(null);
    final asyncNotes = notesKey != null ? ref.watch(notesProvider(notesKey)) : const AsyncValue.data(null);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Subject Hub & Tools', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subject Header Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.85)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          (item.subjectCode != null && item.subjectCode!.isNotEmpty) ? item.subjectCode! : 'SUBJECT',
                          style: AppTypography.labelMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.mapPin, color: Colors.white, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              item.room.isNotEmpty ? item.room : 'Room TBA',
                              style: AppTypography.labelMedium.copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    item.title,
                    style: AppTypography.headlineMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.white24,
                            child: Icon(LucideIcons.user, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.instructor.isNotEmpty ? item.instructor : 'Faculty TBA',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Course Instructor',
                                style: AppTypography.labelSmall.copyWith(color: Colors.white70),
                              ),
                            ],
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () {
                          FacultyProfileSheet.show(
                            context,
                            nameOrCode: item.instructor.isNotEmpty ? item.instructor : (item.subjectCode ?? ''),
                            fallbackName: item.instructor,
                          );
                        },
                        icon: const Icon(LucideIcons.phoneCall, color: Colors.white, size: 16),
                        label: const Text('Contact Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            Text('Interactive Tools & Tracking', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // 1. Attendance & Bunk Predictor Card
            InkWell(
              onTap: () => AttendanceDetailsSheet.show(
                context,
                subjectCode: (item.subjectCode != null && item.subjectCode!.isNotEmpty) ? item.subjectCode! : item.title,
                subjectName: item.title,
              ),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(LucideIcons.calendarCheck, color: AppColors.primary, size: 26),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Attendance Card', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                              Text('Tap to log present/absent & view bunk limits', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        const Icon(LucideIcons.chevronRight, color: AppColors.textSecondary),
                      ],
                    ),
                    const SizedBox(height: 16),
                    asyncAtt.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (err, _) => Text('Error loading attendance', style: AppTypography.bodySmall),
                      data: (model) {
                        final p = model?.presentCount ?? 0;
                        final t = model?.totalCount ?? 0;
                        final pct = model?.percentage ?? 100.0;
                        final safe = model?.safeBunkClasses ?? 0;
                        final risk = (model?.willDropBelowIfMissedNext ?? false) || pct < 75.0;

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$p / $t Classes Present',
                                      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      risk
                                          ? '⚠️ Warning: Risk < 75%!'
                                          : '✅ Safe to bunk: $safe',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: risk ? AppColors.error : AppColors.success,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: (risk ? AppColors.error : AppColors.success).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${pct.toStringAsFixed(1)}%',
                                  style: AppTypography.titleMedium.copyWith(
                                    color: risk ? AppColors.error : AppColors.success,
                                    fontWeight: FontWeight.bold,
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
              ),
            ),
            const SizedBox(height: 16),

            // 2. Subject Notes Hub Card
            InkWell(
              onTap: () => SubjectNotesHubSheet.show(
                context,
                subjectCode: (item.subjectCode != null && item.subjectCode!.isNotEmpty) ? item.subjectCode! : item.title,
                subjectName: item.title,
              ),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(LucideIcons.fileText, color: AppColors.secondary, size: 26),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Notes Card', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                              Text('Tap to create, edit, or delete subject notes', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        const Icon(LucideIcons.chevronRight, color: AppColors.textSecondary),
                      ],
                    ),
                    const SizedBox(height: 16),
                    asyncNotes.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (err, _) => Text('Error loading notes', style: AppTypography.bodySmall),
                      data: (notes) {
                        final count = notes?.length ?? 0;
                        final latest = count > 0 ? notes!.first.title : 'No notes written yet. Tap to create one!';

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$count Notes',
                                  style: AppTypography.labelMedium.copyWith(
                                    color: AppColors.secondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  latest,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
