import 'package:flutter/material.dart';
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
        title: const Text('Complete Profile Required'),
        content: const Text('You must complete your profile to continue using the app.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(true);
              await ref.read(authControllerProvider.notifier).signOut();
            },
            child: const Text('Log Out', style: TextStyle(color: AppColors.error)),
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
                style: const TextStyle(color: Colors.white),
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
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(
            'Complete Your Profile',
            style: TextStyle(color: AppColors.primary),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Almost there!',
                    style: AppTypography.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please provide a few more details to complete your account setup.',
                    style: AppTypography.textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Roll Number
                  TextFormField(
                    controller: _rollNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Roll Number *',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),

                  // Section
                  TextFormField(
                    controller: _sectionController,
                    decoration: const InputDecoration(
                      labelText: 'Section (e.g. A, B, C) *',
                      prefixIcon: Icon(Icons.class_outlined),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),

                  // Phone Number
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Gender Dropdown
                  DropdownButtonFormField<String>(
                    value: _gender,
                    decoration: const InputDecoration(
                      labelText: 'Gender',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    items: ['Male', 'Female', 'Other', 'Prefer not to say'].map((g) {
                      return DropdownMenuItem(value: g, child: Text(g));
                    }).toList(),
                    onChanged: (val) => setState(() => _gender = val),
                  ),
                  const SizedBox(height: 20),

                  // Date of Birth
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_dob == null ? 'Select Date of Birth' : 'DOB: ${_dob!.toLocal().toString().split(' ')[0]}'),
                    leading: const Icon(Icons.calendar_today_outlined),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
                        firstDate: DateTime(1990),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _dob = picked);
                      }
                    },
                  ),
                  const Divider(),
                  const SizedBox(height: 20),

                  // Emergency Contact
                  TextFormField(
                    controller: _emergencyContactController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Emergency Contact Number',
                      prefixIcon: Icon(Icons.warning_amber_rounded),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
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
