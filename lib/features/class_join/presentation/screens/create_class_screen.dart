import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/error_handler.dart';
import '../providers/class_provider.dart';

class CreateClassScreen extends ConsumerStatefulWidget {
  const CreateClassScreen({super.key});

  @override
  ConsumerState<CreateClassScreen> createState() => _CreateClassScreenState();
}

class _CreateClassScreenState extends ConsumerState<CreateClassScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _sectionController = TextEditingController();
  final _institutionController = TextEditingController(text: '');
  final _scheduleController = TextEditingController(text: '');
  String? _selectedDepartment = 'CSBS';

  final List<String> _departments = [
    'CSBS',
    'CSE',
    'IT',
    'AI&DS',
    'ECE',
    'EEE',
    'MECH',
    'CIVIL',
    'BIO',
    'MBA/BBA',
  ];

  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _sectionController.dispose();
    _institutionController.dispose();
    _scheduleController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isCreating = true;
      });

      try {
        final newClass = await ref
            .read(classControllerProvider.notifier)
            .createAndJoin(
              name: _nameController.text.trim(),
              section: _sectionController.text.trim(),
              department: _selectedDepartment ?? 'CSBS',
              institution: _institutionController.text.trim(),
              scheduleSummary: _scheduleController.text.trim(),
            );

        if (mounted) {
          if (newClass != null) {
            AppErrorHandler.showSuccessSnackBar(
              context,
              '✨ Class Created! Code: ${newClass.code}',
            );
            context.go('/home');
          }
        }
      } finally {
        if (mounted) {
          setState(() {
            _isCreating = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(classControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stack) {
          AppErrorHandler.showErrorSnackBar(context, error);
        },
      );
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Create New Class',
          style: AppTypography.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 540),
              padding: const EdgeInsets.all(32.0),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryContainer.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create your class community',
                      style: AppTypography.textTheme.headlineLarge?.copyWith(
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Set up the shared academic space for your section. Every student enrolled will share the same timetable structure.',
                      style: AppTypography.textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Course / Class Name
                    Text(
                      'CLASS / COURSE NAME',
                      style: AppTypography.textTheme.labelLarge?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      style: AppTypography.textTheme.bodyMedium,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Database Management Systems',
                        prefixIcon: Icon(Icons.class_outlined, size: 20),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Please enter class name'
                          : null,
                    ),
                    const SizedBox(height: 20),

                    // Section & Department Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SECTION',
                                style: AppTypography.textTheme.labelLarge
                                    ?.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                      letterSpacing: 1.2,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _sectionController,
                                textInputAction: TextInputAction.next,
                                style: AppTypography.textTheme.bodyMedium,
                                decoration: const InputDecoration(
                                  hintText: 'e.g. B or Sec A',
                                  prefixIcon: Icon(
                                    Icons.label_outline_rounded,
                                    size: 20,
                                  ),
                                ),
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                    ? 'Required'
                                    : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DEPARTMENT',
                                style: AppTypography.textTheme.labelLarge
                                    ?.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                      letterSpacing: 1.2,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedDepartment,
                                isExpanded: true,
                                style: AppTypography.textTheme.bodyMedium,
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(
                                    Icons.school_outlined,
                                    size: 20,
                                  ),
                                ),
                                items: _departments.map((dept) {
                                  return DropdownMenuItem<String>(
                                    value: dept,
                                    child: Text(dept),
                                  );
                                }).toList(),
                                onChanged: (val) =>
                                    setState(() => _selectedDepartment = val),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Institution
                    Text(
                      'INSTITUTION',
                      style: AppTypography.textTheme.labelLarge?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _institutionController,
                      textInputAction: TextInputAction.next,
                      style: AppTypography.textTheme.bodyMedium,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.apartment_rounded, size: 20),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Please enter institution'
                          : null,
                    ),
                    const SizedBox(height: 20),

                    // Schedule Summary
                    Text(
                      'DEFAULT SCHEDULE DAYS',
                      style: AppTypography.textTheme.labelLarge?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _scheduleController,
                      textInputAction: TextInputAction.done,
                      style: AppTypography.textTheme.bodyMedium,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Mon, Wed, Fri',
                        prefixIcon: Icon(
                          Icons.calendar_today_rounded,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isCreating ? null : _handleCreate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isCreating
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: AppColors.onPrimary,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                'Create & Generate Code',
                                style: AppTypography.textTheme.titleMedium
                                    ?.copyWith(
                                      color: AppColors.onPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
