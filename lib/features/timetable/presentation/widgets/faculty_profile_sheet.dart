import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/faculty_model.dart';
import '../../data/repositories/faculty_repository.dart';

class FacultyProfileSheet extends StatefulWidget {
  final String nameOrCode;
  final String fallbackName;

  const FacultyProfileSheet({
    super.key,
    required this.nameOrCode,
    this.fallbackName = 'Professor',
  });

  static void show(BuildContext context, {required String nameOrCode, String? fallbackName}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FacultyProfileSheet(
        nameOrCode: nameOrCode,
        fallbackName: fallbackName ?? nameOrCode,
      ),
    );
  }

  @override
  State<FacultyProfileSheet> createState() => _FacultyProfileSheetState();
}

class _FacultyProfileSheetState extends State<FacultyProfileSheet> {
  final _repository = FacultyRepository();
  FacultyModel? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final res = await _repository.getFacultyProfile(widget.nameOrCode);
    if (mounted) {
      setState(() {
        _profile = res;
        _isLoading = false;
      });
    }
  }

  void _copyText(String label, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard!'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = _profile ?? FacultyModel(
      id: 'fallback',
      name: widget.fallbackName,
      subjectCode: '',
      subjectName: 'REC Faculty Member',
      officeRoom: 'CSBS Department Staff Block — Academic Block C',
      contactNumber: '+91 44 2680 1999',
      email: '${widget.fallbackName.toLowerCase().replaceAll(' ', '.')}@rajalakshmi.edu.in',
    );

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                child: Text(
                  p.name.isNotEmpty ? p.name[0].toUpperCase() : 'P',
                  style: AppTypography.headlineMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        p.subjectName.isNotEmpty ? p.subjectName : 'Faculty Directory',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (_isLoading)
            const Center(child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ))
          else ...[
            _buildInfoCard(
              icon: LucideIcons.building2,
              title: 'Office Room & Location',
              value: p.officeRoom,
              onTapCopy: () => _copyText('Office Location', p.officeRoom),
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: LucideIcons.phone,
              title: 'Contact Phone Number',
              value: p.contactNumber,
              onTapCopy: () => _copyText('Phone Number', p.contactNumber),
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: LucideIcons.mail,
              title: 'Official Email Address',
              value: p.email,
              onTapCopy: () => _copyText('Email Address', p.email),
            ),
          ],

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTapCopy,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(value, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              ],
            ),
          ),
          IconButton(
            onPressed: onTapCopy,
            icon: const Icon(LucideIcons.copy, size: 18, color: AppColors.textSecondary),
            tooltip: 'Copy $title',
          ),
        ],
      ),
    );
  }
}
