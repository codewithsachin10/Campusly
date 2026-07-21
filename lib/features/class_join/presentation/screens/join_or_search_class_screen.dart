import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class JoinOrSearchClassScreen extends ConsumerWidget {
  const JoinOrSearchClassScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;

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
                  const SizedBox(height: 48),

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
                            const SizedBox(width: 24),
                            Expanded(
                              child: _buildChoiceCard(context, isJoin: false),
                            ),
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            _buildChoiceCard(context, isJoin: true),
                            const SizedBox(height: 24),
                            _buildChoiceCard(context, isJoin: false),
                          ],
                        );
                      }
                    },
                  ),

                  const SizedBox(height: 56),

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
        ? 'Quickly join using a QR code or an invite code provided by your instructor or peer.'
        : "Browse or search for your specific class space within your university's directory.";
    final route = isJoin ? '/join-by-code' : '/search-class';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(route),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor, size: 30),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: AppTypography.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                desc,
                style: AppTypography.textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Text(
                    'CONTINUE',
                    style: AppTypography.textTheme.labelLarge?.copyWith(
                      color: iconColor,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded, color: iconColor, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
