import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/error_handler.dart';
import '../providers/support_provider.dart';
import '../widgets/gradient_text.dart';
import 'my_tickets_screen.dart';

class HelpdeskScreen extends ConsumerStatefulWidget {
  const HelpdeskScreen({super.key});

  @override
  ConsumerState<HelpdeskScreen> createState() => _HelpdeskScreenState();
}

class _HelpdeskScreenState extends ConsumerState<HelpdeskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'Campusly Account';

  bool _isSubmitting = false;

  final List<String> _categories = [
    'Campusly Account',
    'Academic Information',
    'Timetable',
    'Attendance',
    'Assignments',
    'Exams',
    'Notifications',
    'App / Technical Issue',
    'Other'
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    String priority = 'Low';
    if (['Campusly Account', 'Timetable', 'Attendance', 'Exams'].contains(_selectedCategory)) {
      priority = 'High';
    } else if (['Academic Information', 'Assignments'].contains(_selectedCategory)) {
      priority = 'Medium';
    }

    final success = await ref.read(createTicketProvider.notifier).createTicket(
          subject: _subjectController.text.trim(),
          description: _descriptionController.text.trim(),
          priority: priority,
        );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        AppErrorHandler.showSuccessSnackBar(context, 'Ticket created successfully!');
        _subjectController.clear();
        _descriptionController.clear();
        Navigator.push(context, MaterialPageRoute(builder: (_) => MyTicketsScreen()));
      } else {
        final error = ref.read(createTicketProvider).error;
        AppErrorHandler.showErrorSnackBar(context, error ?? 'Failed to create ticket');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final faqsAsync = ref.watch(supportFaqsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: GradientText(
          'Student Helpdesk',
          gradient: LinearGradient(colors: [Color(0xFF4285F4), Color(0xFFE91E63)]),
          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: Color(0xFF673AB7)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16.w, top: 8.h, bottom: 8.h),
            decoration: BoxDecoration(
              color: Color(0xFFF3E5F5),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: IconButton(
              icon: Icon(LucideIcons.ticket, color: Color(0xFF7E57C2), size: 20),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => MyTicketsScreen()),
                );
              },
            ),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Contact Card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(color: Colors.white, width: 2.w),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFFE91E63).withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        '🎧',
                        style: TextStyle(fontSize: 64.sp),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'IT & Academic Helpdesk',
                        style: AppTypography.titleMedium.copyWith(color: Color(0xFF5E35B1)),
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 10.w,
                            height: 10.h,
                            decoration: BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'Support Available',
                            style: AppTypography.labelMedium.copyWith(color: Color(0xFF4CAF50), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.mail, size: 14, color: Colors.black54),
                          SizedBox(width: 6.w),
                          Flexible(
                            child: Text(
                              'support@rec.edu.in | Ext: 4400 / 4401', 
                              style: AppTypography.bodySmall.copyWith(color: Colors.black87),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.mapPin, size: 14, color: Colors.black54),
                          SizedBox(width: 6.w),
                          Flexible(
                            child: Text(
                              'Admin Block - Room 102', 
                              style: AppTypography.bodySmall.copyWith(color: Colors.black87),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      Text('(08:30 AM - 05:00 PM)', style: AppTypography.bodySmall.copyWith(color: Colors.black54)),
                    ],
                  ),
                ),
                SizedBox(height: 32.h),

                // Raise Ticket Section
                Text('Raise Support Ticket', style: AppTypography.bodyMedium.copyWith(color: Colors.black87)),
                SizedBox(height: 16.h),

                Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: Colors.white, width: 2.w),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF4285F4).withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Issue Category', style: AppTypography.labelMedium.copyWith(color: Colors.black87)),
                        SizedBox(height: 8.h),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: _selectedCategory,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: Color(0xFFF3E5F5))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: Color(0xFFF3E5F5))),
                          ),
                          items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat, style: AppTypography.bodyMedium))).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedCategory = val);
                          },
                        ),
                        SizedBox(height: 16.h),

                        TextFormField(
                          controller: _subjectController,
                          decoration: InputDecoration(
                            hintText: 'Brief Subject / Issue Summary',
                            hintStyle: TextStyle(color: Colors.black38),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: Color(0xFFF3E5F5))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: Color(0xFFF3E5F5))),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Please enter subject' : null,
                        ),
                        SizedBox(height: 16.h),

                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Detailed description of your issue...',
                            hintStyle: TextStyle(color: Colors.black38),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: Color(0xFFF3E5F5))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: Color(0xFFF3E5F5))),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Please enter issue details' : null,
                        ),
                        SizedBox(height: 16.h),

                        // Attachment Area
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 24.h),
                          decoration: BoxDecoration(
                            color: Color(0xFFFDFBFF),
                            borderRadius: BorderRadius.circular(12.r),
                            // Create a pseudo dashed border effect using a repeating gradient on the border or just a light solid border if dashed isn't strictly available.
                            border: Border.all(color: Color(0xFFD1C4E9), width: 1.5.w),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.paperclip, color: Color(0xFFAB47BC)),
                              SizedBox(height: 8.h),
                              Text('Add screenshot (PNG, JPG • Max 5 MB)', style: AppTypography.bodySmall.copyWith(color: Colors.black87)),
                            ],
                          ),
                        ),
                        SizedBox(height: 24.h),

                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF4285F4), Color(0xFF9C27B0)],
                            ),
                            borderRadius: BorderRadius.circular(30.r),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF9C27B0).withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: _isSubmitting ? null : _submitTicket,
                            icon: _isSubmitting
                                ? SizedBox(width: 16.w, height: 16.h, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : Icon(LucideIcons.send, size: 18, color: Colors.white),
                            label: Text('Submit Support Ticket', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: EdgeInsets.symmetric(vertical: 16.h),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'Campusly automatically includes your student profile and device details with this ticket.',
                          style: AppTypography.labelMedium.copyWith(color: Colors.black54),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 32.h),

                // FAQs Section
                Text('Frequently Asked Questions', style: AppTypography.bodyMedium.copyWith(color: Colors.black87)),
                SizedBox(height: 16.h),

                faqsAsync.when(
                  data: (faqs) {
                    if (faqs.isEmpty) return Text('No FAQs available.');
                    return Column(
                      children: faqs.map((faq) {
                        return Container(
                          margin: EdgeInsets.only(bottom: 12.h),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(color: Colors.white, width: 2.w),
                            boxShadow: [
                              BoxShadow(color: Color(0xFFE91E63).withValues(alpha: 0.05), blurRadius: 10, offset: Offset(0, 4)),
                            ],
                          ),
                          child: ExpansionTile(
                            shape: Border(),
                            collapsedShape: Border(),
                            iconColor: Color(0xFF7E57C2),
                            collapsedIconColor: Color(0xFF7E57C2),
                            title: Text(faq['question'], style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: Colors.black87)),
                            childrenPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                            children: [
                              Text(faq['answer'], style: AppTypography.bodySmall.copyWith(height: 1.5.h, color: Colors.black54)),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => Center(child: CircularProgressIndicator()),
                  error: (err, st) => Text('Failed to load FAQs: $err'),
                ),

                SizedBox(height: 16.h),
                Center(
                  child: Text(
                    'View All FAQs', 
                    style: AppTypography.labelLarge.copyWith(color: Color(0xFF9C27B0), fontWeight: FontWeight.bold)
                  )
                ),
                SizedBox(height: 32.h),

                // Still Need Help
                Container(
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: Colors.white, width: 2.w),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF4285F4).withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text('Still Need Help?', style: AppTypography.bodyMedium.copyWith(color: Colors.black87)),
                      SizedBox(height: 8.h),
                      Text('Still need help? Can\'t find what you\'re looking for?', style: AppTypography.bodySmall.copyWith(color: Colors.black54), textAlign: TextAlign.center),
                      SizedBox(height: 24.h),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30.r),
                          border: Border.all(color: Color(0xFFF3E5F5)),
                        ),
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => MyTicketsScreen()));
                          },
                          icon: Text('🎫'),
                          label: Text('My Support Tickets', style: AppTypography.labelLarge.copyWith(color: Colors.black87)),
                          style: OutlinedButton.styleFrom(
                            minimumSize: Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
                            side: BorderSide.none,
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30.r),
                          border: Border.all(color: Color(0xFFF3E5F5)),
                        ),
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: Text('📧'),
                          label: Text('Contact Support', style: AppTypography.labelLarge.copyWith(color: Colors.black87)),
                          style: OutlinedButton.styleFrom(
                            minimumSize: Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
                            side: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
