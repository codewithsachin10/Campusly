import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../class_join/presentation/providers/class_provider.dart';
import '../../../timetable/domain/models/custom_timetable_membership.dart';
import '../../../timetable/presentation/providers/timetable_provider.dart';
import '../widgets/class_details_sheet.dart';

class JoinOrSearchClassScreen extends ConsumerWidget {
  const JoinOrSearchClassScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    final currentClass = ref.watch(currentClassProvider);
    final joinedCustomTimetablesAsync = ref.watch(joinedCustomTimetablesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.menu_rounded, color: AppColors.primary),
              onPressed: () {
                // Future navigation drawer
              },
            ),
            const SizedBox(width: 4),
            Text(
              'Campusly',
              style: AppTypography.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  width: 2,
                ),
                color: AppColors.primaryContainer.withValues(alpha: 0.2),
              ),
              child: ClipOval(
                child: Center(
                  child: Text(
                    (user?.name.isNotEmpty == true ? user!.name[0] : 'S')
                        .toUpperCase(),
                    style: AppTypography.textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 24.0,
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Header Section
                  Text(
                    'Find your class',
                    textAlign: TextAlign.center,
                    style: AppTypography.textTheme.displayLarge?.copyWith(
                      fontSize: 40,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Connect with your peers and sync your academic schedule in just a few taps.',
                      textAlign: TextAlign.center,
                      style: AppTypography.textTheme.bodyLarge?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Choice Grid (LayoutBuilder for Responsive 1 or 2 col)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isDesktop = constraints.maxWidth > 600;
                      if (isDesktop) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _buildChoiceCard(context, isJoin: true),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildChoiceCard(context, isJoin: false),
                            ),
                          ],
                        );
                      } else {
                        return Row(
                          children: [
                            Expanded(child: _buildChoiceCard(context, isJoin: true)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildChoiceCard(context, isJoin: false)),
                          ],
                        );
                      }
                    },
                  ),

                  const SizedBox(height: 32),

                  // My Timetable Section
                  _buildMyTimetableSection(context, currentClass, joinedCustomTimetablesAsync),

                  const SizedBox(height: 32),

                  // Secondary Navigation
                  InkWell(
                    onTap: () => context.push('/create-class'),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        "Can't find your class? Create one",
                        style: AppTypography.textTheme.labelLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Academic Year 2024 • Term 2',
                    style: AppTypography.textTheme.labelMedium?.copyWith(
                      color: AppColors.outline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceCard(BuildContext context, {required bool isJoin}) {
    final icon = isJoin ? Icons.qr_code_scanner_rounded : Icons.search_rounded;
    final iconBgColor = isJoin
        ? AppColors.primaryContainer.withValues(alpha: 0.15)
        : AppColors.secondaryContainer.withValues(alpha: 0.15);
    final iconColor = isJoin ? AppColors.primary : AppColors.secondary;
    final title = isJoin ? 'Join Class' : 'Search Class';
    final desc = isJoin
        ? 'Quickly join using a QR code or an invite code.'
        : "Browse or search for your specific class space.";
    final route = isJoin ? '/join-by-code' : '/search-class';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(route),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.35),
              width: 1.5,
            ),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: AppTypography.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                desc,
                style: AppTypography.textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyTimetableSection(
    BuildContext context,
    dynamic currentClass, // Academic ClassModel?
    AsyncValue<List<CustomTimetableMembership>> joinedCustomTimetablesAsync, // CustomTimetableMembership list
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.class_rounded, size: 24, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'My Timetables',
              style: AppTypography.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (currentClass == null && !joinedCustomTimetablesAsync.isLoading && (joinedCustomTimetablesAsync.value?.isEmpty ?? true))
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.2)),
            ),
            alignment: Alignment.center,
            child: Text(
              "You haven't joined any classes yet.",
              style: AppTypography.textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          )
        else ...[
          // Show Academic Class
          if (currentClass != null)
            _buildJoinedClassCard(
              context,
              title: currentClass.name,
              subtitle: '${currentClass.department} • Academic Class',
              icon: Icons.school_rounded,
              onTap: () => ClassDetailsSheet.show(context, academicClass: currentClass),
            ),
          
          if (currentClass != null && (joinedCustomTimetablesAsync.value?.isNotEmpty == true))
            const SizedBox(height: 12),

          // Show Custom Timetables
          joinedCustomTimetablesAsync.when(
            data: (customTimetables) {
              if (customTimetables.isEmpty) return const SizedBox.shrink();
              return Column(
                children: customTimetables.map((ct) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildJoinedClassCard(
                      context,
                      title: ct.title,
                      icon: Icons.group_rounded,
                      onTap: () => ClassDetailsSheet.show(context, customTimetable: ct),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            error: (err, _) => Text('Error loading custom timetables', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ],
    );
  }

  Widget _buildJoinedClassCard(
    BuildContext context, {
    required String title,
    String? subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppTypography.textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
