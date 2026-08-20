import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../class_join/presentation/providers/class_provider.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _sectionController;
  late TextEditingController _emergencyContactController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).value;
    _nameController = TextEditingController(
      text: user?.name ?? 'Student',
    );
    _phoneController = TextEditingController(
      text: user?.phone ?? '',
    );
    _sectionController = TextEditingController(
      text: user?.section ?? '',
    );
    _emergencyContactController = TextEditingController(
      text: user?.emergencyContact ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _sectionController.dispose();
    _emergencyContactController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    await ref
        .read(authControllerProvider.notifier)
        .updateProfile(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          section: _sectionController.text.trim(),
          emergencyContact: _emergencyContactController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(LucideIcons.checkCircle2, color: Colors.white),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'Profile details updated successfully!',
                style: TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value;
    final currentClass = ref.watch(currentClassProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Edit Student Profile',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _saveProfile,
            icon: _isLoading
                ? SizedBox(
                    width: 20.w,
                    height: 20.h,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    LucideIcons.check,
                    color: AppColors.primary,
                    size: 28,
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 54,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        user?.name.isNotEmpty == true
                            ? user!.name[0].toUpperCase()
                            : 'S',
                        style: AppTypography.headlineLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0.h,
                      right: 0.w,
                      child: Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3.w),
                        ),
                        child: Icon(
                          LucideIcons.camera,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),

              Container(
                padding: EdgeInsets.all(18.w),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          LucideIcons.shieldCheck,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            'Verified Institutional Account',
                            style: AppTypography.labelLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    _buildReadOnlyField(
                      'Roll Number',
                      user?.rollNumber ?? 'N/A',
                    ),
                    SizedBox(height: 8.h),
                    _buildReadOnlyField(
                      'Email Address',
                      user?.email.isNotEmpty == true
                          ? user!.email
                          : 'No email associated',
                    ),
                    SizedBox(height: 8.h),
                    _buildReadOnlyField(
                      'Department',
                      user?.department ?? 'General',
                    ),
                    SizedBox(height: 8.h),
                    _buildReadOnlyField(
                      'Academic Year',
                      user?.year ?? 'N/A',
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),

              Text(
                'Editable Information',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.h),

              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(LucideIcons.user),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Please enter your full name'
                    : null,
              ),
              SizedBox(height: 16.h),

              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(LucideIcons.phone),
                ),
              ),
              SizedBox(height: 16.h),
              
              TextFormField(
                controller: _emergencyContactController,
                decoration: InputDecoration(
                  labelText: 'Emergency Contact Number',
                  prefixIcon: Icon(LucideIcons.shieldAlert),
                ),
              ),
              SizedBox(height: 16.h),

              TextFormField(
                controller: _sectionController,
                decoration: InputDecoration(
                  labelText: 'Class Section / Group',
                  prefixIcon: Icon(LucideIcons.users),
                ),
              ),
              SizedBox(height: 32.h),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveProfile,
                  icon: Icon(LucideIcons.save),
                  label: Text(
                    'Save Changes',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
