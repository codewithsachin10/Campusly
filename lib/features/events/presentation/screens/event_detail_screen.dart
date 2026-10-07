import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/event_model.dart';
import '../../../../core/theme/subject_colors.dart';
import '../providers/events_provider.dart';

class EventDetailScreen extends ConsumerStatefulWidget {
  final EventModel event;

  const EventDetailScreen({super.key, required this.event});

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  bool _isLoading = false;
  final Map<String, TextEditingController> _customFieldControllers = {};

  @override
  void initState() {
    super.initState();
    for (final field in widget.event.registrationSettings.customFields) {
      _customFieldControllers[field] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final ctrl in _customFieldControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _handleRegister(EventRegistrationModel? existingReg) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null || user.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please log in to register for events.')),
      );
      return;
    }

    if (existingReg != null && existingReg.status == 'Registered') {
      // Cancel Registration
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          title: Text('Cancel Registration?'),
          content: Text(
            'Are you sure you want to cancel your registration for "${widget.event.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('No, Keep It'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.onError,
              ),
              child: Text('Yes, Cancel'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        setState(() => _isLoading = true);
        try {
          await ref
              .read(eventsRepositoryProvider)
              .cancelRegistration(
                registrationId: existingReg.id,
                eventId: widget.event.id,
              );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Registration cancelled successfully.'),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error cancelling registration: $e')),
            );
          }
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      }
      return;
    }

    // Check custom fields prompt if needed
    if (widget.event.registrationSettings.customFields.isNotEmpty) {
      final fieldsFilled = await _showCustomFieldsDialog();
      if (!fieldsFilled) return;
    }

    setState(() => _isLoading = true);
    try {
      final customData = <String, dynamic>{};
      for (final entry in _customFieldControllers.entries) {
        if (entry.value.text.trim().isNotEmpty) {
          customData[entry.key] = entry.value.text.trim();
        }
      }

      await ref
          .read(eventsRepositoryProvider)
          .registerForEvent(
            event: widget.event,
            studentId: user.id,
            studentName: user.name,
            studentEmail: user.email,
            department: user.department,
            customData: customData.isNotEmpty ? customData : null,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Row(
              children: [
                Icon(LucideIcons.checkCircle, color: AppColors.onPrimary),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    'You are now registered for "${widget.event.title}"! 🎉',
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error registering for event: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _showCustomFieldsDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            title: Text(
              'Additional Registration Details',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Please fill in the required information requested by ${widget.event.organizer}:',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  ...widget.event.registrationSettings.customFields.map((
                    field,
                  ) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: TextField(
                        controller: _customFieldControllers[field],
                        decoration: InputDecoration(
                          labelText: field,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Validate all fields
                  for (final field
                      in widget.event.registrationSettings.customFields) {
                    if (_customFieldControllers[field]?.text.trim().isEmpty ??
                        true) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text('Please enter $field.')),
                      );
                      return;
                    }
                  }
                  Navigator.pop(ctx, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                ),
                child: Text('Continue to Register'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final myRegsAsync = ref.watch(myRegistrationsProvider);
    final myRegs = myRegsAsync.value ?? [];
    EventRegistrationModel? existingReg;
    for (final r in myRegs) {
      if (r.eventId == widget.event.id && r.status == 'Registered') {
        existingReg = r;
        break;
      }
    }

    final isRegistered = existingReg != null;
    final isOpen =
        widget.event.registrationSettings.isOpen &&
        widget.event.status != 'Registration Closed' &&
        widget.event.status != 'Completed';
    final isFull =
        widget.event.participantCount >=
        widget.event.registrationSettings.maxParticipants;

    final categoryColor = SubjectColors.forCategory(widget.event.type);
    IconData categoryIcon = LucideIcons.calendar;
    switch (widget.event.type.toLowerCase()) {
      case 'hackathon':
        categoryIcon = LucideIcons.code2;
        break;
      case 'workshop':
        categoryIcon = LucideIcons.wrench;
        break;
      case 'cultural event':
        categoryIcon = LucideIcons.music;
        break;
      case 'symposium':
        categoryIcon = LucideIcons.presentation;
        break;
      case 'sports event':
        categoryIcon = LucideIcons.trophy;
        break;
      case 'club event':
        categoryIcon = LucideIcons.users;
        break;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App Bar Banner
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.surfaceContainerLowest,
            leading: IconButton(
              onPressed: () => context.pop(),
              icon: Icon(
                LucideIcons.arrowLeft,
                color: AppColors.onSurface,
              ),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surfaceContainerLowest.withValues(
                  alpha: 0.8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'event-banner-${widget.event.id}',
                child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      categoryColor.withValues(alpha: 0.35),
                      categoryColor.withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        categoryIcon,
                        size: 90,
                        color: categoryColor.withValues(alpha: 0.25),
                      ),
                    ),
                    Positioned(
                      bottom: 20.h,
                      left: 20.w,
                      right: 20.w,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 6.h,
                              ),
                              decoration: BoxDecoration(
                                color: categoryColor,
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    categoryIcon,
                                    size: 14,
                                    color: AppColors.onPrimary,
                                  ),
                                  SizedBox(width: 6.w),
                                  Flexible(
                                    child: Text(
                                      widget.event.type.toUpperCase(),
                                      style: AppTypography.labelSmall.copyWith(
                                        color: AppColors.onPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Flexible(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 6.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: Text(
                                '${widget.event.participantCount}/${widget.event.registrationSettings.maxParticipants} Registered',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.event.title,
                    style: AppTypography.headlineMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  // Organizer Tag
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          LucideIcons.building2,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Organized By',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              widget.event.organizer,
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.onSurface,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),

                  // Info Cards (Date/Time & Venue)
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: AppColors.outlineVariant.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    LucideIcons.calendar,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                  SizedBox(width: 6.w),
                                  Text(
                                    'DATE & TIME',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                widget.event.date,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              Text(
                                '${widget.event.startTime} - ${widget.event.endTime}',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: AppColors.outlineVariant.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    LucideIcons.mapPin,
                                    size: 18,
                                    color: AppColors.secondary,
                                  ),
                                  SizedBox(width: 6.w),
                                  Text(
                                    'VENUE',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                widget.event.venue,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.onSurface,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24.h),
                  // About Section
                  Text(
                    'About This Event',
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    widget.event.description.isNotEmpty
                        ? widget.event.description
                        : 'No detailed description provided for this campus event.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.5.h,
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Registration Deadline Box
                  if (widget
                      .event
                      .registrationSettings
                      .deadline
                      .isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.clock,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'REGISTRATION DEADLINE',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  widget.event.registrationSettings.deadline,
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),
                  ],

                  if (isRegistered) ...[
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: AppColors.success),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            LucideIcons.checkCircle2,
                            color: AppColors.success,
                            size: 36,
                          ),
                          SizedBox(height: 10.h),
                          Text(
                            'You Are Registered!',
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Show your student ID at ${widget.event.venue} on ${widget.event.date}.',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],

                  SizedBox(height: 80.h),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: isRegistered
              ? ElevatedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () => _handleRegister(existingReg),
                  icon: _isLoading
                      ? SizedBox(
                          width: 18.w,
                          height: 18.h,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(LucideIcons.xCircle),
                  label: Text('Cancel My Registration'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error.withValues(alpha: 0.15),
                    foregroundColor: AppColors.error,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    elevation: 0,
                  ),
                )
              : ElevatedButton.icon(
                  onPressed: (_isLoading || !isOpen || isFull)
                      ? null
                      : () => _handleRegister(null),
                  icon: _isLoading
                      ? SizedBox(
                          width: 18.w,
                          height: 18.h,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.onPrimary,
                          ),
                        )
                      : Icon(LucideIcons.clipboardCheck),
                  label: Text(
                    isFull
                        ? 'Registration Full (Capacity Reached)'
                        : (!isOpen
                              ? 'Registration Closed'
                              : 'One-Tap Register Now'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
