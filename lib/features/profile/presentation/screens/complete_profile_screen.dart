import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/three_d_pushable_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/utils/error_handler.dart';

class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _sectionController = TextEditingController();
  final _rollNumberController = TextEditingController();
  final _emergencyContactController = TextEditingController();

  String? _gender;
  DateTime? _dob;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authControllerProvider).value;
      if (user != null) {
        if (user.rollNumber != null) {
          _rollNumberController.text = user.rollNumber!;
        }
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _sectionController.dispose();
    _rollNumberController.dispose();
    _emergencyContactController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Complete Profile Required'),
        content: Text('You must complete your profile to continue using the app.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('OK'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(true);
              await ref.read(authControllerProvider.notifier).signOut();
            },
            child: Text('Log Out', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    return shouldPop ?? false;
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      await ref.read(authControllerProvider.notifier).updateProfile(
        phone: _phoneController.text.trim(),
        section: _sectionController.text.trim(),
        rollNumber: _rollNumberController.text.trim(),
        gender: _gender,
        dob: _dob,
        emergencyContact: _emergencyContactController.text.trim(),
        isProfileCompleted: true,
      );
      
      if (mounted) {
        final authState = ref.read(authControllerProvider);
        if (authState.hasError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppErrorHandler.getErrorMessage(authState.error),
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          context.go('/home');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            'Complete Your Profile',
            style: TextStyle(color: AppColors.primary),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.0.w),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Almost there!',
                    style: AppTypography.textTheme.headlineMedium,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Please provide a few more details to complete your account setup.',
                    style: AppTypography.textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 32.h),

                  // Roll Number
                  TextFormField(
                    controller: _rollNumberController,
                    decoration: InputDecoration(
                      labelText: 'Roll Number *',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                  ),
                  SizedBox(height: 20.h),

                  // Section
                  TextFormField(
                    controller: _sectionController,
                    decoration: InputDecoration(
                      labelText: 'Section (e.g. A, B, C) *',
                      prefixIcon: Icon(Icons.class_outlined),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                  ),
                  SizedBox(height: 20.h),

                  // Phone Number
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // Gender Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _gender,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Gender',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    items: ['Male', 'Female', 'Other', 'Prefer not to say'].map((g) {
                      return DropdownMenuItem(value: g, child: Text(g));
                    }).toList(),
                    onChanged: (val) => setState(() => _gender = val),
                  ),
                  SizedBox(height: 20.h),

                  // Date of Birth
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_dob == null ? 'Select Date of Birth' : 'DOB: ${_dob!.toLocal().toString().split(' ')[0]}'),
                    leading: Icon(Icons.calendar_today_outlined),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().subtract(Duration(days: 365 * 18)),
                        firstDate: DateTime(1990),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _dob = picked);
                      }
                    },
                  ),
                  Divider(),
                  SizedBox(height: 20.h),

                  // Emergency Contact
                  TextFormField(
                    controller: _emergencyContactController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Emergency Contact Number',
                      prefixIcon: Icon(Icons.warning_amber_rounded),
                    ),
                  ),
                  
                  SizedBox(height: 40.h),
                  ThreeDPushableButton(
                    text: 'Complete Setup',
                    isLoading: isLoading,
                    onPressed: isLoading ? null : _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
