import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/class_model.dart';
import '../providers/class_provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class JoinByCodeScreen extends ConsumerStatefulWidget {
  const JoinByCodeScreen({super.key});

  @override
  ConsumerState<JoinByCodeScreen> createState() => _JoinByCodeScreenState();
}

class _JoinByCodeScreenState extends ConsumerState<JoinByCodeScreen> {
  final _codeController = TextEditingController();
  ClassModel? _previewClass;
  bool _isLoadingPreview = false;
  String? _errorMessage;
  int _selectedModeIndex = 1; // 0 = Scan QR, 1 = Join via Code

  @override
  void initState() {
    super.initState();
    _codeController.text = '';
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _lookupCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isLoadingPreview = true;
      _errorMessage = null;
    });

    try {
      final classModel = await ref
          .read(classControllerProvider.notifier)
          .lookupByCode(code);

      if (mounted) {
        setState(() {
          _isLoadingPreview = false;
          _previewClass = classModel;
          if (classModel == null) {
            _errorMessage = 'No class found with code "$code". Please verify.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPreview = false;
          _previewClass = null;
          _errorMessage = AppErrorHandler.getMessage(e);
        });
      }
    }
  }

  void _showQrScannerModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scan Class QR Code',
                          style: AppTypography.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Point your camera at the QR code displayed by your professor or peer',
                          style: AppTypography.textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              // Camera Viewfinder using MobileScanner
              Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.primary, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(21),
                  child: Stack(
                    children: [
                      MobileScanner(
                        onDetect: (capture) {
                          final List<Barcode> barcodes = capture.barcodes;
                          if (barcodes.isNotEmpty) {
                            final String? code = barcodes.first.rawValue;
                            if (code != null && code.isNotEmpty) {
                              Navigator.of(bottomSheetContext).pop();
                              _codeController.text = code;
                              _lookupCode();
                            }
                          }
                        },
                      ),
                      // Laser scan animation bar
                      Positioned(
                        top: 120,
                        left: 16,
                        right: 16,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.secondary.withValues(alpha: 0.8),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Simulate QR Scan (Test Codes):',
                style: AppTypography.textTheme.labelMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _buildScanTestChip(
                    'CAMPUS-B7K2',
                    'CSBS (DBMS)',
                    bottomSheetContext,
                  ),
                  _buildScanTestChip(
                    'CAMPUS-A9M4',
                    'CSE (DSA)',
                    bottomSheetContext,
                  ),
                  _buildScanTestChip(
                    'CAMPUS-W3Z8',
                    'IT (Web Dev)',
                    bottomSheetContext,
                  ),
                  _buildScanTestChip(
                    'CAMPUS-D5X1',
                    'AI&DS (AI/ML)',
                    bottomSheetContext,
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScanTestChip(
    String code,
    String label,
    BuildContext bottomSheetContext,
  ) {
    return ActionChip(
      avatar: const Icon(
        Icons.qr_code_rounded,
        size: 16,
        color: AppColors.primary,
      ),
      label: Text('$label ($code)'),
      labelStyle: AppTypography.textTheme.labelSmall?.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.bold,
      ),
      backgroundColor: AppColors.primaryContainer.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      onPressed: () {
        Navigator.of(bottomSheetContext).pop();
        setState(() {
          _selectedModeIndex = 1;
          _codeController.text = code;
        });
        _lookupCode();
      },
    );
  }

  void _showJoinConfirmationDialog(
    BuildContext context,
    ClassModel classModel,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppColors.surfaceContainerLowest,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.class_rounded,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Confirm Class Join',
                style: AppTypography.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Do you want to join this class?',
              style: AppTypography.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          classModel.code,
                          style: AppTypography.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        classModel.section,
                        style: AppTypography.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    classModel.name,
                    style: AppTypography.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Department: ${classModel.department}',
                    style: AppTypography.textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    'Institution: ${classModel.institution}',
                    style: AppTypography.textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.sync_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Once confirmed, your personal timetable and reminders will switch to this class until you change it.',
                    style: AppTypography.textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 18,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.onSurfaceVariant,
            ),
            child: Text('Cancel', style: AppTypography.textTheme.titleMedium),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _handleJoinClassConfirmed(classModel);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Yes, Join Class',
              style: AppTypography.textTheme.titleMedium?.copyWith(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleJoinClassConfirmed(ClassModel classModel) {
    ref.read(currentClassProvider.notifier).joinClass(classModel);
    AppErrorHandler.showSuccessSnackBar(
      context,
      '🎉 Successfully enrolled in "${classModel.name}" timetable!',
    );
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value;

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
          'Campusly',
          style: AppTypography.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
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
              vertical: 20.0,
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                children: [
                  // Mode Switcher Header (Scan QR Code vs Join via Code)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() => _selectedModeIndex = 0);
                              _showQrScannerModal(context);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _selectedModeIndex == 0
                                    ? AppColors.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.qr_code_scanner_rounded,
                                    size: 20,
                                    color: _selectedModeIndex == 0
                                        ? AppColors.onPrimary
                                        : AppColors.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Scan QR Code',
                                    style: AppTypography.textTheme.titleSmall
                                        ?.copyWith(
                                          color: _selectedModeIndex == 0
                                              ? AppColors.onPrimary
                                              : AppColors.onSurfaceVariant,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() => _selectedModeIndex = 1);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _selectedModeIndex == 1
                                    ? AppColors.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.keyboard_alt_rounded,
                                    size: 20,
                                    color: _selectedModeIndex == 1
                                        ? AppColors.onPrimary
                                        : AppColors.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Join via Code',
                                    style: AppTypography.textTheme.titleSmall
                                        ?.copyWith(
                                          color: _selectedModeIndex == 1
                                              ? AppColors.onPrimary
                                              : AppColors.onSurfaceVariant,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Header Section
                  Text(
                    'Enter class code',
                    textAlign: TextAlign.center,
                    style: AppTypography.textTheme.headlineLarge?.copyWith(
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Join your academic group by entering the unique 10-character code or scanning the class QR code.',
                    textAlign: TextAlign.center,
                    style: AppTypography.textTheme.bodyLarge?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Input Box
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.outlineVariant.withValues(alpha: 0.6),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _codeController,
                            textCapitalization: TextCapitalization.characters,
                            textAlign: TextAlign.center,
                            style: AppTypography.textTheme.headlineMedium
                                ?.copyWith(
                                  letterSpacing: 3.0,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                            decoration: const InputDecoration(
                              hintText: 'CAMPUS-XXXX',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 20,
                                horizontal: 16,
                              ),
                            ),
                            onSubmitted: (_) => _lookupCode(),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.qr_code_scanner_rounded,
                            color: AppColors.primary,
                            size: 28,
                          ),
                          tooltip: 'Scan QR Code',
                          onPressed: () {
                            setState(() => _selectedModeIndex = 0);
                            _showQrScannerModal(context);
                          },
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoadingPreview ? null : _lookupCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoadingPreview
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: AppColors.onPrimary,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              'Preview Class',
                              style: AppTypography.textTheme.titleMedium
                                  ?.copyWith(
                                    color: AppColors.onPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                    ),
                  ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: AppTypography.textTheme.bodyMedium?.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ],

                  // Refined Class Preview State
                  if (_previewClass != null) ...[
                    const SizedBox(height: 36),
                    _buildPreviewCard(_previewClass!),
                  ],

                  const SizedBox(height: 36),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.onSurfaceVariant,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Need help? Contact your department administrator.',
                        style: AppTypography.textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewCard(ClassModel classModel) {
    return Container(
      width: double.infinity,
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
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header badges
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondaryFixed,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'PREVIEWING',
                  style: AppTypography.textTheme.labelSmall?.copyWith(
                    color: AppColors.onSecondaryFixed,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.tertiaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  classModel.section,
                  style: AppTypography.textTheme.labelMedium?.copyWith(
                    color: AppColors.onTertiaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'CLASS CODE',
            style: AppTypography.textTheme.labelSmall?.copyWith(
              color: AppColors.primary.withValues(alpha: 0.6),
              letterSpacing: 2.0,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            classModel.code,
            style: AppTypography.textTheme.headlineLarge?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Text(
            classModel.name,
            style: AppTypography.textTheme.headlineMedium?.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Details List
          _buildDetailRow(
            icon: Icons.school_rounded,
            label: 'Department',
            value: classModel.department,
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            icon: Icons.apartment_rounded,
            label: 'Institution',
            value: classModel.institution,
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            icon: Icons.groups_rounded,
            label: 'Enrolled',
            value: '${classModel.enrolledCount} students',
            trailing: InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Viewing student roster...')),
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'View',
                  style: AppTypography.textTheme.labelMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            icon: Icons.calendar_today_rounded,
            label: 'Schedule',
            value: classModel.scheduleSummary,
          ),
          const SizedBox(height: 28),

          // Join This Class button with confirmation check
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () => _showJoinConfirmationDialog(context, classModel),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Join This Class',
                style: AppTypography.textTheme.titleMedium?.copyWith(
                  color: AppColors.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.textTheme.labelMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTypography.textTheme.bodyLarge?.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        trailing ?? const SizedBox.shrink(),
      ],
    );
  }
}
