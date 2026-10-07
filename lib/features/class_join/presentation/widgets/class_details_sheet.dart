import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../class_join/domain/models/class_model.dart';
import '../../../timetable/domain/models/custom_timetable_membership.dart';
import '../../../timetable/presentation/providers/timetable_provider.dart';
import '../../../timetable/domain/models/timetable_item.dart';

class ClassDetailsSheet extends ConsumerStatefulWidget {
  final ClassModel? academicClass;
  final CustomTimetableMembership? customTimetable;

  const ClassDetailsSheet({
    super.key,
    this.academicClass,
    this.customTimetable,
  });

  static void show(
    BuildContext context, {
    ClassModel? academicClass,
    CustomTimetableMembership? customTimetable,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ClassDetailsSheet(
        academicClass: academicClass,
        customTimetable: customTimetable,
      ),
    );
  }

  @override
  ConsumerState<ClassDetailsSheet> createState() => _ClassDetailsSheetState();
}

class _ClassDetailsSheetState extends ConsumerState<ClassDetailsSheet> {
  int _memberCount = 0;
  bool _isLoadingMembers = true;

  @override
  void initState() {
    super.initState();
    if (widget.customTimetable != null) {
      _fetchMemberCount(widget.customTimetable!.timetableId);
    } else {
      _isLoadingMembers = false;
    }
  }

  Future<void> _fetchMemberCount(String timetableId) async {
    try {
      final supabase = Supabase.instance.client;
      final count = await supabase
          .from('student_timetable_members')
          .select('id')
          .eq('timetable_id', timetableId)
          .count();
          
      if (mounted) {
        setState(() {
          _memberCount = count.count;
          _isLoadingMembers = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching member count: $e');
      if (mounted) {
        setState(() => _isLoadingMembers = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.academicClass?.name ?? widget.customTimetable?.title ?? 'Timetable';
    final subtitle = widget.academicClass != null 
        ? '${widget.academicClass!.department} • ${widget.academicClass!.institution}'
        : widget.customTimetable?.hostName ?? 'Custom';
    final code = widget.academicClass?.code ?? widget.customTimetable?.joinCode ?? widget.customTimetable?.timetableId ?? '';
    final fetchCode = widget.academicClass?.code ?? widget.customTimetable?.timetableId ?? '';

    // A localized future provider to fetch the schedule just for this sheet
    final scheduleAsync = ref.watch(_sheetScheduleProvider(fetchCode));

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
          ),
          child: Column(
            children: [
              // Handle
              Center(
                child: Container(
                  margin: EdgeInsets.only(top: 12.h, bottom: 16.h),
                  width: 48.w,
                  height: 6.h,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
                  children: [
                    // Header Section
                    Text(
                      title,
                      style: AppTypography.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      subtitle,
                      style: AppTypography.textTheme.titleMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 32.h),
                    
                    // QR Code Section
                    if (code.isNotEmpty)
                      Center(
                        child: Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 20,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: QrImageView(
                            data: code,
                            version: QrVersions.auto,
                            size: 200.0,
                            backgroundColor: Colors.white,
                            errorCorrectionLevel: QrErrorCorrectLevel.M,
                          ),
                        ),
                      ),
                      
                    SizedBox(height: 24.h),
                    
                    // Code & Members Info Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            icon: Icons.tag_rounded,
                            title: 'Join Code',
                            value: code,
                          ),
                        ),
                        if (widget.customTimetable != null) ...[
                          SizedBox(width: 16.w),
                          Expanded(
                            child: _buildInfoCard(
                              icon: Icons.people_rounded,
                              title: 'Members',
                              value: _isLoadingMembers ? '...' : '$_memberCount',
                              onTap: _showMembersDialog,
                            ),
                          ),
                        ],
                      ],
                    ),
                    
                    SizedBox(height: 40.h),
                    Text(
                      'Full Timetable',
                      style: AppTypography.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    
                    // Timetable Schedule List
                    scheduleAsync.when(
                      data: (items) {
                        if (items.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0.w),
                              child: Text(
                                'No classes scheduled.',
                                style: TextStyle(color: AppColors.onSurfaceVariant),
                              ),
                            ),
                          );
                        }
                        
                        // Group by day for simple rendering
                        final Map<String, List<TimetableItem>> grouped = {};
                        for (final item in items) {
                          grouped.putIfAbsent(item.dayOfWeek, () => []).add(item);
                        }
                        
                        return Column(
                          children: grouped.entries.map((entry) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.0.h),
                                  child: Text(
                                    entry.key.toUpperCase(),
                                    style: AppTypography.textTheme.labelLarge?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                ...entry.value.map((item) {
                                  return Card(
                                    margin: EdgeInsets.only(bottom: 8.h),
                                    elevation: 0,
                                    color: AppColors.surfaceContainerLowest,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                      side: BorderSide(
                                        color: AppColors.outlineVariant.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: ListTile(
                                      title: Text(
                                        item.title,
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Text(
                                        '${item.startHour.toString().padLeft(2, '0')}:${item.startMinute.toString().padLeft(2, '0')} - ${item.endHour.toString().padLeft(2, '0')}:${item.endMinute.toString().padLeft(2, '0')} • ${item.room}',
                                      ),
                                      trailing: item.isBreak 
                                          ? Icon(Icons.free_breakfast_rounded)
                                          : null,
                                    ),
                                  );
                                }),
                                SizedBox(height: 16.h),
                              ],
                            );
                          }).toList(),
                        );
                      },
                      loading: () => Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0.w),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (e, _) => Text(
                        'Error loading schedule: $e',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                    SizedBox(height: 48.h),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMembersDialog() {
    if (widget.customTimetable == null) return;
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Joined Members'),
          content: SizedBox(
            width: double.maxFinite,
            height: 350.h,
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchMembersData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SizedBox(
                    height: 100.h,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                
                if (snapshot.hasError) {
                  return Padding(
                    padding: EdgeInsets.all(16.0.w),
                    child: Text('Failed to load members: ${snapshot.error}'),
                  );
                }
                
                final members = snapshot.data ?? [];
                
                if (members.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.all(16.0.w),
                    child: Text('No members found.'),
                  );
                }
                
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final user = members[index];
                    final name = user['name']?.toString() ?? 'Unknown User';
                    final email = user['email']?.toString() ?? '';
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(name),
                      subtitle: email.isNotEmpty ? Text(email) : null,
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchMembersData() async {
    final supabase = Supabase.instance.client;
    
    // 1. Fetch memberships
    final response = await supabase
        .from('student_timetable_members')
        .select('student_id')
        .eq('timetable_id', widget.customTimetable!.timetableId);
        
    if (response.isEmpty) return [];
    
    final studentIds = response.map((row) => row['student_id'].toString()).toList();
    
    // 2. Fetch users
    final usersResponse = await supabase
        .from('students')
        .select('id, name, email')
        .inFilter('id', studentIds);
        
    return List<Map<String, dynamic>>.from(usersResponse);
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onTap,
  }) {
    Widget cardContent = Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              SizedBox(width: 8.w),
              Text(
                title,
                style: AppTypography.textTheme.labelMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: AppTypography.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: cardContent,
        ),
      );
    }
    
    return cardContent;
  }
}

// Temporary localized provider
final _sheetScheduleProvider = FutureProvider.family<List<TimetableItem>, String>((ref, code) async {
  if (code.isEmpty) return [];
  final repository = ref.watch(timetableRepositoryProvider);
  return repository.getWeeklySchedule(code);
});
