import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/class_model.dart';
import '../providers/class_provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../timetable/presentation/providers/timetable_provider.dart';

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
      // 1. Try to find an academic class
      final classModel = await ref
          .read(classControllerProvider.notifier)
          .lookupByCode(code);

      if (classModel != null) {
        if (mounted) {
          setState(() {
            _isLoadingPreview = false;
            _previewClass = classModel;
            _errorMessage = null;
          });
        }
        return;
      }

      // 2. Try to find a custom timetable if academic class not found
      final cleanCode = code.trim();
      
      // Check if it's a URL
      String finalCode = cleanCode;
      if (cleanCode.toUpperCase().startsWith('CAMPUSLY://')) {
        final uri = Uri.tryParse(cleanCode.toLowerCase());
        if (uri != null && uri.queryParameters.containsKey('code')) {
          finalCode = uri.queryParameters['code']!.toUpperCase();
        }
      }

      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('custom_timetables')
          .select()
          .eq('join_code', finalCode.toUpperCase())
          .eq('status', 'published')
          .maybeSingle();

      if (response != null) {
        // Auto-join the custom timetable immediately!
        final user = ref.read(authControllerProvider).value;
        if (user != null) {
          final existing = await supabase
              .from('student_timetable_members')
              .select()
              .eq('student_id', user.id)
              .eq('timetable_id', response['id'])
              .maybeSingle();

          if (existing != null) {
            if (mounted) {
               setState(() => _isLoadingPreview = false);
               AppErrorHandler.showErrorSnackBar(
                 context,
                 'You have already joined "${response['title']}".',
               );
               context.go('/home');
            }
            return;
          }

          await supabase.from('student_timetable_members').insert({
            'student_id': user.id,
            'timetable_id': response['id'],
            'joined_at': DateTime.now().toIso8601String(),
          });
          
          if (mounted) {
             setState(() => _isLoadingPreview = false);
             ref.invalidate(weeklyScheduleProvider);
             ref.invalidate(todayScheduleProvider);
             ref.invalidate(dailyScheduleProvider);
             ref.invalidate(joinedCustomTimetablesProvider);
             
             AppErrorHandler.showSuccessSnackBar(
               context,
               '🎉 Successfully joined custom timetable "${response['title']}"!',
             );
             context.go('/home');
          }
          return;
        }
      }

      // 3. Not found in either
      if (mounted) {
        setState(() {
          _isLoadingPreview = false;
          _previewClass = null;
          _errorMessage = 'No class or timetable found with code "$code". Please verify.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPreview = false;
          _previewClass = null;
          _errorMessage = AppErrorHandler.getErrorMessage(e);
        });
      }
    }
  }

  void _showQrScannerModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      builder: (bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24.w,
            right: 24.w,
            top: 24.h,
            bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48.w,
                height: 5.h,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.qr_code_scanner_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scan Class QR Code',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Point your camera at the QR code displayed by your professor or peer',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 28.h),
              // Camera Viewfinder using MobileScanner
              Container(
                width: 240.w,
                height: 240.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(color: AppColors.primary, width: 3.w),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(21.r),
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
                        top: 120.h,
                        left: 16.w,
                        right: 16.w,
                        child: Container(
                          height: 3.h,
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.secondary.withValues(
                                  alpha: 0.8,
                                ),
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
              SizedBox(height: 24.h),
              Text(
                'Simulate QR Scan (Test Codes):',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12.h),
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
              SizedBox(height: 20.h),
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
      avatar: Icon(
        Icons.qr_code_rounded,
        size: 16,
        color: AppColors.primary,
      ),
      label: Text('$label ($code)'),
      labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.bold,
      ),
      backgroundColor: AppColors.primaryContainer.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        backgroundColor: AppColors.surfaceContainerLowest,
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.class_rounded,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(
                'Confirm Class Join',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            SizedBox(height: 14.h),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16.r),
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
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          classModel.code,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.onPrimaryContainer,
                          ),
                        ),
                      ),
                      Spacer(),
                      Text(
                        classModel.section,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    classModel.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'Department: ${classModel.department}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    'Institution: ${classModel.institution}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Icon(
                  Icons.sync_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    'Once confirmed, your personal timetable and reminders will switch to this class until you change it.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      height: 1.4.h,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actionsPadding: EdgeInsets.symmetric(
          horizontal: 24.w,
          vertical: 18.h,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.onSurfaceVariant,
            ),
            child: Text('Cancel', style: Theme.of(context).textTheme.titleMedium),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _handleJoinClassConfirmed(classModel);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            ),
            child: Text(
              'Yes, Join Class',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Campusly',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 20.0.w),
            child: Container(
              width: 40.w,
              height: 40.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  width: 2.w,
                ),
                color: AppColors.primaryContainer.withValues(alpha: 0.2),
              ),
              child: ClipOval(
                child: Center(
                  child: Text(
                    (user?.name.isNotEmpty == true ? user!.name[0] : 'S')
                        .toUpperCase(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
            padding: EdgeInsets.symmetric(
              horizontal: 24.0.w,
              vertical: 20.0.h,
            ),
            child: Container(
              constraints: BoxConstraints(maxWidth: 640),
              child: Column(
                children: [
                  // Mode Switcher Header (Scan QR Code vs Join via Code)
                  Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16.r),
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
                            borderRadius: BorderRadius.circular(12.r),
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              decoration: BoxDecoration(
                                color: _selectedModeIndex == 0
                                    ? AppColors.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12.r),
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
                                  SizedBox(width: 8.w),
                                  Text(
                                    'Scan QR Code',
                                    style: Theme.of(context).textTheme.titleSmall
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
                            borderRadius: BorderRadius.circular(12.r),
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              decoration: BoxDecoration(
                                color: _selectedModeIndex == 1
                                    ? AppColors.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12.r),
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
                                  SizedBox(width: 8.w),
                                  Text(
                                    'Join via Code',
                                    style: Theme.of(context).textTheme.titleSmall
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
                  SizedBox(height: 24.h),

                  // Header Section
                  Text(
                    'Enter class code',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppColors.onSurface,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Join your academic group by entering the unique 10-character code or scanning the class QR code.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      height: 1.5.h,
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Input Box
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: AppColors.outlineVariant.withValues(alpha: 0.6),
                        width: 2.w,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _codeController,
                            textCapitalization: TextCapitalization.characters,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  letterSpacing: 3.0,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                            decoration: InputDecoration(
                              hintText: 'CAMPUS-XXXX',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 20.h,
                                horizontal: 16.w,
                              ),
                            ),
                            onSubmitted: (_) => _lookupCode(),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
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
                        SizedBox(width: 8.w),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  SizedBox(
                    width: double.infinity,
                    height: 54.h,
                    child: ElevatedButton(
                      onPressed: _isLoadingPreview ? null : _lookupCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                      ),
                      child: _isLoadingPreview
                          ? SizedBox(
                              width: 24.w,
                              height: 24.h,
                              child: CircularProgressIndicator(
                                color: AppColors.onPrimary,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              'Preview Class',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: AppColors.onPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                    ),
                  ),

                  if (_errorMessage != null) ...[
                    SizedBox(height: 16.h),
                    Text(
                      _errorMessage!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ],

                  // Refined Class Preview State
                  if (_previewClass != null) ...[
                    SizedBox(height: 36.h),
                    _buildPreviewCard(_previewClass!),
                  ],

                  SizedBox(height: 36.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.onSurfaceVariant,
                        size: 20,
                      ),
                      SizedBox(width: 8.w),
                      Flexible(
                        child: Text(
                          'Need help? Contact your department administrator.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
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
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.35),
          width: 1.5.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header badges
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 10.w,
                  vertical: 4.h,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondaryFixed,
                  borderRadius: BorderRadius.circular(999.r),
                ),
                child: Text(
                  'PREVIEWING',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.onSecondaryFixed,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 6.h,
                ),
                decoration: BoxDecoration(
                  color: AppColors.tertiaryContainer,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  classModel.section,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.onTertiaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            'CLASS CODE',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.primary.withValues(alpha: 0.6),
              letterSpacing: 2.0,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            classModel.code,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          SizedBox(height: 16.h),
          Divider(height: 1.h),
          SizedBox(height: 16.h),
          Text(
            classModel.name,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20.h),

          // Details List
          _buildDetailRow(
            icon: Icons.school_rounded,
            label: 'Department',
            value: classModel.department,
          ),
          SizedBox(height: 16.h),
          _buildDetailRow(
            icon: Icons.apartment_rounded,
            label: 'Institution',
            value: classModel.institution,
          ),
          SizedBox(height: 16.h),
          _buildDetailRow(
            icon: Icons.groups_rounded,
            label: 'Enrolled',
            value: '${classModel.enrolledCount} students',
            trailing: InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Viewing student roster...')),
                );
              },
              borderRadius: BorderRadius.circular(8.r),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 6.h,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'View',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          _buildDetailRow(
            icon: Icons.calendar_today_rounded,
            label: 'Schedule',
            value: classModel.scheduleSummary,
          ),
          SizedBox(height: 28.h),

          // Join This Class button with confirmation check
          SizedBox(
            width: double.infinity,
            height: 54.h,
            child: ElevatedButton(
              onPressed: () => _showJoinConfirmationDialog(context, classModel),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              child: Text(
                'Join This Class',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
          width: 44.w,
          height: 44.h,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        trailing ?? SizedBox.shrink(),
      ],
    );
  }
}
