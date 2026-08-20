import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final TextEditingController _skillsController = TextEditingController();
  final TextEditingController _interestsController = TextEditingController();
  String _privacySetting = 'public';
  String _locationVisibility = 'Classmates';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authControllerProvider).value;
      if (user != null) {
        _skillsController.text = user.skills.join(', ');
        _interestsController.text = user.interests.join(', ');
        setState(() {
          _privacySetting =
              user.privacySettings['profileVisibility'] ?? 'public';
          _locationVisibility =
              user.privacySettings['locationVisibility'] ?? 'Classmates';
        });
      }
    });
  }

  void _save() async {
    setState(() => _isLoading = true);

    final skills = _skillsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final interests = _interestsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    try {
      await ref
          .read(authControllerProvider.notifier)
          .updateProfile(
            skills: skills,
            interests: interests,
            privacySettings: {
              'profileVisibility': _privacySetting,
              'locationVisibility': _locationVisibility,
            },
          );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Edit Social Profile',
          style: TextStyle(color: AppColors.primary),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: AppColors.primary),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? SizedBox(
                    width: 20.w,
                    height: 20.h,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Save',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0.w),
        children: [
          Text(
            'Skills (comma separated)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8.h),
          TextField(
            controller: _skillsController,
            decoration: InputDecoration(
              hintText: 'e.g. Flutter, Dart, UI/UX',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'Interests (comma separated)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8.h),
          TextField(
            controller: _interestsController,
            decoration: InputDecoration(
              hintText: 'e.g. Hackathons, Coding, Music',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'Profile Visibility',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8.h),
          DropdownButtonFormField<String>(
            initialValue: _privacySetting,
            isExpanded: true,
            decoration: InputDecoration(border: OutlineInputBorder()),
            items: [
              DropdownMenuItem(
                value: 'public',
                child: Text('Public (Everyone in college)'),
              ),
              DropdownMenuItem(value: 'class_only', child: Text('Class Only')),
              DropdownMenuItem(
                value: 'private',
                child: Text('Private (Only friends)'),
              ),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _privacySetting = val);
            },
          ),
          SizedBox(height: 24.h),
          Text(
            'Default Location Visibility',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8.h),
          DropdownButtonFormField<String>(
            initialValue: _locationVisibility,
            isExpanded: true,
            decoration: InputDecoration(border: OutlineInputBorder()),
            items: [
              DropdownMenuItem(
                value: 'Everyone',
                child: Text('Everyone in college'),
              ),
              DropdownMenuItem(value: 'Classmates', child: Text('Classmates')),
              DropdownMenuItem(value: 'Friends', child: Text('Friends Only')),
              DropdownMenuItem(
                value: 'Hidden',
                child: Text('Hidden (Incognito)'),
              ),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _locationVisibility = val);
            },
          ),
        ],
      ),
    );
  }
}
