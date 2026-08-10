import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
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
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MyTicketsScreen()));
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
          gradient: const LinearGradient(colors: [Color(0xFF4285F4), Color(0xFFE91E63)]),
          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF673AB7)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(LucideIcons.ticket, color: Color(0xFF7E57C2), size: 20),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyTicketsScreen()),
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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Contact Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE91E63).withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '🎧',
                        style: TextStyle(fontSize: 64),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'IT & Academic Helpdesk',
                        style: AppTypography.titleMedium.copyWith(color: const Color(0xFF5E35B1)),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Support Available',
                            style: AppTypography.labelMedium.copyWith(color: const Color(0xFF4CAF50), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.mail, size: 14, color: Colors.black54),
                          const SizedBox(width: 6),
                          Text('support@rec.edu.in | Ext: 4400 / 4401', style: AppTypography.bodySmall.copyWith(color: Colors.black87)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.mapPin, size: 14, color: Colors.black54),
                          const SizedBox(width: 6),
                          Text('Admin Block - Room 102', style: AppTypography.bodySmall.copyWith(color: Colors.black87)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('(08:30 AM - 05:00 PM)', style: AppTypography.bodySmall.copyWith(color: Colors.black54)),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Raise Ticket Section
                Text('Raise Support Ticket', style: AppTypography.bodyMedium.copyWith(color: Colors.black87)),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4285F4).withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Issue Category', style: AppTypography.labelMedium.copyWith(color: Colors.black87)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCategory,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF3E5F5))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF3E5F5))),
                          ),
                          items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat, style: AppTypography.bodyMedium))).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedCategory = val);
                          },
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _subjectController,
                          decoration: InputDecoration(
                            hintText: 'Brief Subject / Issue Summary',
                            hintStyle: TextStyle(color: Colors.black38),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF3E5F5))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF3E5F5))),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Please enter subject' : null,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Detailed description of your issue...',
                            hintStyle: TextStyle(color: Colors.black38),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF3E5F5))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF3E5F5))),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Please enter issue details' : null,
                        ),
                        const SizedBox(height: 16),

                        // Attachment Area
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDFBFF),
                            borderRadius: BorderRadius.circular(12),
                            // Create a pseudo dashed border effect using a repeating gradient on the border or just a light solid border if dashed isn't strictly available.
                            border: Border.all(color: const Color(0xFFD1C4E9), width: 1.5),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(LucideIcons.paperclip, color: Color(0xFFAB47BC)),
                              const SizedBox(height: 8),
                              Text('Add screenshot (PNG, JPG • Max 5 MB)', style: AppTypography.bodySmall.copyWith(color: Colors.black87)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4285F4), Color(0xFF9C27B0)],
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF9C27B0).withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: _isSubmitting ? null : _submitTicket,
                            icon: _isSubmitting
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(LucideIcons.send, size: 18, color: Colors.white),
                            label: const Text('Submit Support Ticket', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Campusly automatically includes your student profile and device details with this ticket.',
                          style: AppTypography.labelMedium.copyWith(color: Colors.black54),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // FAQs Section
                Text('Frequently Asked Questions', style: AppTypography.bodyMedium.copyWith(color: Colors.black87)),
                const SizedBox(height: 16),

                faqsAsync.when(
                  data: (faqs) {
                    if (faqs.isEmpty) return const Text('No FAQs available.');
                    return Column(
                      children: faqs.map((faq) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(color: const Color(0xFFE91E63).withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: ExpansionTile(
                            shape: const Border(),
                            collapsedShape: const Border(),
                            iconColor: const Color(0xFF7E57C2),
                            collapsedIconColor: const Color(0xFF7E57C2),
                            title: Text(faq['question'], style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: Colors.black87)),
                            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            children: [
                              Text(faq['answer'], style: AppTypography.bodySmall.copyWith(height: 1.5, color: Colors.black54)),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, st) => Text('Failed to load FAQs: $err'),
                ),

                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'View All FAQs', 
                    style: AppTypography.labelLarge.copyWith(color: const Color(0xFF9C27B0), fontWeight: FontWeight.bold)
                  )
                ),
                const SizedBox(height: 32),

                // Still Need Help
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4285F4).withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text('Still Need Help?', style: AppTypography.bodyMedium.copyWith(color: Colors.black87)),
                      const SizedBox(height: 8),
                      Text('Still need help? Can\'t find what you\'re looking for?', style: AppTypography.bodySmall.copyWith(color: Colors.black54), textAlign: TextAlign.center),
                      const SizedBox(height: 24),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: const Color(0xFFF3E5F5)),
                        ),
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const MyTicketsScreen()));
                          },
                          icon: const Text('🎫'),
                          label: Text('My Support Tickets', style: AppTypography.labelLarge.copyWith(color: Colors.black87)),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            side: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: const Color(0xFFF3E5F5)),
                        ),
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Text('📧'),
                          label: Text('Contact Support', style: AppTypography.labelLarge.copyWith(color: Colors.black87)),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            side: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
