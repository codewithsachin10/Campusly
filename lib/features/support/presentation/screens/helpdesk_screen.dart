import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:campusly/core/theme/app_colors.dart';
import 'package:campusly/core/theme/app_typography.dart';
import 'package:campusly/core/utils/error_handler.dart';
import 'package:campusly/features/auth/presentation/providers/auth_provider.dart';
import '../providers/support_provider.dart';
import 'my_tickets_screen.dart';

class HelpdeskScreen extends ConsumerStatefulWidget {
  const HelpdeskScreen({super.key});

  @override
  ConsumerState<HelpdeskScreen> createState() => _HelpdeskScreenState();
}

class _CategoryItem {
  final String id;
  final String label;
  final IconData icon;
  final String description;

  const _CategoryItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.description,
  });
}

class _HelpdeskScreenState extends ConsumerState<HelpdeskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _faqSearchController = TextEditingController();

  String _selectedCategory = 'Timetable';
  String _selectedPriority = 'Medium';
  String _faqSearchQuery = '';
  bool _isSubmitting = false;

  final List<_CategoryItem> _categoryList = const [
    _CategoryItem(
      id: 'Timetable',
      label: 'Timetable',
      icon: LucideIcons.calendar,
      description: 'Room & period conflicts',
    ),
    _CategoryItem(
      id: 'Attendance',
      label: 'Attendance',
      icon: LucideIcons.checkSquare,
      description: 'Missing class logs & disputes',
    ),
    _CategoryItem(
      id: 'Academic Information',
      label: 'Academic',
      icon: LucideIcons.graduationCap,
      description: 'Courses, credits & syllabus',
    ),
    _CategoryItem(
      id: 'Assignments',
      label: 'Assignments',
      icon: LucideIcons.fileText,
      description: 'Tasks, LMS & deadlines',
    ),
    _CategoryItem(
      id: 'App / Technical Issue',
      label: 'Tech & App',
      icon: LucideIcons.laptop,
      description: 'App bugs, crashes & sync',
    ),
    _CategoryItem(
      id: 'General & Campus',
      label: 'General',
      icon: LucideIcons.helpCircle,
      description: 'ID cards & campus services',
    ),
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    _faqSearchController.dispose();
    super.dispose();
  }

  void _onCategorySelected(String categoryId) {
    setState(() {
      _selectedCategory = categoryId;
      // Intelligently suggest priority based on selected category
      if (categoryId == 'Attendance' || categoryId == 'App / Technical Issue') {
        _selectedPriority = 'Urgent';
      } else if (categoryId == 'Timetable' || categoryId == 'Assignments') {
        _selectedPriority = 'Medium';
      } else {
        _selectedPriority = 'Normal';
      }
    });
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    String priorityPayload = 'Medium';
    if (_selectedPriority == 'Urgent') {
      priorityPayload = 'High';
    } else if (_selectedPriority == 'Normal') {
      priorityPayload = 'Low';
    } else {
      priorityPayload = 'Medium';
    }

    final success = await ref.read(createTicketProvider.notifier).createTicket(
          subject: '[$_selectedCategory] ${_subjectController.text.trim()}',
          description: _descriptionController.text.trim(),
          priority: priorityPayload,
        );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        AppErrorHandler.showSuccessSnackBar(
          context,
          'Support ticket created successfully! Our team will respond shortly.',
        );
        _subjectController.clear();
        _descriptionController.clear();
        ref.invalidate(myTicketsProvider);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MyTicketsScreen()),
        );
      } else {
        final error = ref.read(createTicketProvider).error;
        AppErrorHandler.showErrorSnackBar(
          context,
          error?.toString() ?? 'Failed to create support ticket.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final faqsAsync = ref.watch(supportFaqsProvider);
    final myTicketsAsync = ref.watch(myTicketsProvider);
    final user = ref.watch(authControllerProvider).value;

    final openTicketCount = myTicketsAsync.maybeWhen(
      data: (tickets) => tickets.where((t) => t.status != 'Resolved' && t.status != 'Closed').length,
      orElse: () => 0,
    );

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Support Hub',
          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // My Tickets Action Pill with Counter Badge
          Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyTicketsScreen()),
                );
              },
              borderRadius: BorderRadius.circular(20.r),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.ticket,
                      size: 16.sp,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      openTicketCount > 0 ? '$openTicketCount Active' : 'Tickets',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero Contact & Availability Card ──
            _buildHeroContactCard(context, isDark),
            SizedBox(height: 24.h),

            // ── My Tickets Tracker Banner (if tickets exist) ──
            if (openTicketCount > 0) ...[
              _buildActiveTicketsBanner(context, openTicketCount),
              SizedBox(height: 24.h),
            ],

            // ── Main Section: Create a Support Ticket ──
            Text(
              'Create Support Request',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'Select a department and describe your query for fast resolution.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            SizedBox(height: 16.h),

            // ── Ticket Composer Form Container ──
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Selection Label
                    Text(
                      'ISSUE CATEGORY',
                      style: AppTypography.labelSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                        letterSpacing: 1.0,
                      ),
                    ),
                    SizedBox(height: 12.h),

                    // Interactive Category Grid
                    _buildCategoryGrid(context),
                    SizedBox(height: 20.h),

                    // Priority Selector
                    Text(
                      'URGENCY / PRIORITY',
                      style: AppTypography.labelSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                        letterSpacing: 1.0,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    _buildPrioritySelector(context),
                    SizedBox(height: 20.h),

                    // Subject Field
                    Text(
                      'SUBJECT / SUMMARY',
                      style: AppTypography.labelSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                        letterSpacing: 1.0,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    TextFormField(
                      controller: _subjectController,
                      style: AppTypography.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'e.g., Attendance mismatch in CS3301 period 3',
                        hintStyle: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary.withValues(alpha: 0.6),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : AppColors.background,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 14.h,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14.r),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14.r),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14.r),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.8,
                          ),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter a brief summary of the issue';
                        }
                        if (val.trim().length < 5) {
                          return 'Subject should be at least 5 characters';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20.h),

                    // Description Field
                    Text(
                      'DETAILED EXPLANATION',
                      style: AppTypography.labelSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                        letterSpacing: 1.0,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 5,
                      style: AppTypography.bodyMedium,
                      decoration: InputDecoration(
                        hintText:
                            'Include relevant course codes, dates, faculty names, or error messages encountered...',
                        hintStyle: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary.withValues(alpha: 0.6),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : AppColors.background,
                        contentPadding: EdgeInsets.all(16.w),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14.r),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14.r),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14.r),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.8,
                          ),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please provide details so we can assist you';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 18.h),

                    // Attachment Placeholder Box
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 16.w),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.03)
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: AppColors.border,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10.w),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Icon(
                              LucideIcons.paperclip,
                              color: AppColors.primary,
                              size: 18.sp,
                            ),
                          ),
                          SizedBox(width: 14.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Attach Screenshots or Logs',
                                  style: AppTypography.titleSmall.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.sp,
                                  ),
                                ),
                                Text(
                                  'PNG, JPG, PDF up to 10 MB (Optional)',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 11.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Diagnostic & Identity Assurance Chip
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        color: AppColors.mint.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: AppColors.mint.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.shieldCheck,
                            size: 18.sp,
                            color: AppColors.mint,
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              user != null
                                  ? 'Verified as ${user.email} · Device diagnostics included'
                                  : 'Authenticated student profile attached automatically',
                              style: AppTypography.labelSmall.copyWith(
                                color: isDark ? Colors.white70 : AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 22.h),

                    // Submit Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 52.h,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submitTicket,
                        icon: _isSubmitting
                            ? SizedBox(
                                width: 18.w,
                                height: 18.w,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(LucideIcons.send, size: 18),
                        label: Text(
                          _isSubmitting ? 'Submitting Ticket...' : 'Submit Support Request',
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 36.h),

            // ── Frequently Asked Questions Section ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Instant Solutions & FAQs',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  'Knowledgebase',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // FAQ Search Input
            TextField(
              controller: _faqSearchController,
              onChanged: (val) => setState(() => _faqSearchQuery = val.trim()),
              style: AppTypography.bodySmall,
              decoration: InputDecoration(
                hintText: 'Search FAQ questions...',
                hintStyle: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary.withValues(alpha: 0.6),
                ),
                prefixIcon: Icon(
                  LucideIcons.search,
                  size: 18.sp,
                  color: AppColors.textSecondary,
                ),
                suffixIcon: _faqSearchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(LucideIcons.x, size: 16),
                        onPressed: () {
                          _faqSearchController.clear();
                          setState(() => _faqSearchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : AppColors.background,
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // FAQs List
            _buildFaqSection(context, faqsAsync),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroContactCard(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.all(22.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.88),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8.w,
                      height: 8.w,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00E676),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'DESK ONLINE & ACTIVE',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 10.sp,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.headphones,
                color: Colors.white.withValues(alpha: 0.8),
                size: 26.sp,
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            'IT & Academic Helpdesk',
            style: AppTypography.headlineSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Official support desk for Rajalakshmi Engineering College campus community.',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.35,
            ),
          ),
          SizedBox(height: 18.h),

          // 2x2 Quick Contact Matrix
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildContactPill(
                        icon: LucideIcons.phoneCall,
                        title: 'Ext: 4400 / 4401',
                        subtitle: 'Campus Telecom',
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: _buildContactPill(
                        icon: LucideIcons.mail,
                        title: 'support@rec.edu.in',
                        subtitle: 'Official Email',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    Expanded(
                      child: _buildContactPill(
                        icon: LucideIcons.mapPin,
                        title: 'Admin Block, R-102',
                        subtitle: 'Help Desk Office',
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: _buildContactPill(
                        icon: LucideIcons.clock,
                        title: '08:30 AM – 05:00 PM',
                        subtitle: 'Working Hours',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactPill({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14.sp, color: Colors.white.withValues(alpha: 0.85)),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 11.sp,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 9.sp,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActiveTicketsBanner(BuildContext context, int count) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MyTicketsScreen()),
        );
      },
      borderRadius: BorderRadius.circular(18.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: AppColors.coral.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: AppColors.coral.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppColors.coral.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.alertCircle,
                size: 18.sp,
                color: AppColors.coral,
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You have $count active ticket${count > 1 ? 's' : ''}',
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.coral,
                    ),
                  ),
                  Text(
                    'Tap to view staff responses and updates',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.arrowRight,
              size: 18.sp,
              color: AppColors.coral,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 12.w) / 2;
        return Wrap(
          spacing: 12.w,
          runSpacing: 10.h,
          children: _categoryList.map((cat) {
            final isSelected = _selectedCategory == cat.id;
            return SizedBox(
              width: itemWidth,
              child: InkWell(
                onTap: () => _onCategorySelected(cat.id),
                borderRadius: BorderRadius.circular(14.r),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.border,
                      width: isSelected ? 1.6 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(
                          cat.icon,
                          size: 16.sp,
                          color: isSelected ? Colors.white : AppColors.primary,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cat.label,
                              style: AppTypography.labelMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              cat.description,
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 9.sp,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildPrioritySelector(BuildContext context) {
    final priorities = [
      {'label': 'Normal', 'color': AppColors.mint, 'desc': 'Routine query'},
      {'label': 'Medium', 'color': Colors.amber.shade700, 'desc': 'Standard issue'},
      {'label': 'Urgent', 'color': AppColors.coral, 'desc': 'Deadline / Attendance'},
    ];

    return Row(
      children: priorities.map((p) {
        final label = p['label'] as String;
        final color = p['color'] as Color;
        final isSelected = _selectedPriority == label;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: InkWell(
              onTap: () => setState(() => _selectedPriority = label),
              borderRadius: BorderRadius.circular(12.r),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.15)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isSelected ? color : AppColors.border,
                    width: isSelected ? 1.6 : 1.0,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8.w,
                          height: 8.w,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          label,
                          style: AppTypography.labelSmall.copyWith(
                            fontWeight: FontWeight.w800,
                            color: isSelected ? color : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFaqSection(
      BuildContext context, AsyncValue<List<Map<String, dynamic>>> faqsAsync) {
    return faqsAsync.when(
      data: (faqs) {
        if (faqs.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Text(
                'No FAQs published yet.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
            ),
          );
        }

        final filteredFaqs = faqs.where((f) {
          if (_faqSearchQuery.isEmpty) return true;
          final q = (f['question'] ?? '').toString().toLowerCase();
          final a = (f['answer'] ?? '').toString().toLowerCase();
          final target = _faqSearchQuery.toLowerCase();
          return q.contains(target) || a.contains(target);
        }).toList();

        if (filteredFaqs.isEmpty) {
          return Container(
            padding: EdgeInsets.all(24.w),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Icon(LucideIcons.searchX, color: AppColors.textSecondary, size: 28.sp),
                SizedBox(height: 8.h),
                Text(
                  'No FAQs matched "$_faqSearchQuery"',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Submit a support ticket above and our staff will help you!',
                  style: AppTypography.labelSmall.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          );
        }

        return Column(
          children: filteredFaqs.map((faq) {
            final question = faq['question'] ?? 'FAQ Question';
            final answer = faq['answer'] ?? 'No answer details available.';

            return Container(
              margin: EdgeInsets.only(bottom: 10.h),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppColors.border),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  iconColor: AppColors.primary,
                  collapsedIconColor: AppColors.textSecondary,
                  tilePadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                  title: Text(
                    question,
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.sp,
                    ),
                  ),
                  childrenPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        answer,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, _) => Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.coral.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Text(
          'Failed to load FAQs: $err',
          style: AppTypography.bodySmall.copyWith(color: AppColors.coral),
        ),
      ),
    );
  }
}
