import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../timetable/presentation/providers/announcements_provider.dart';

class AnnouncementsScreen extends ConsumerStatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  ConsumerState<AnnouncementsScreen> createState() =>
      _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends ConsumerState<AnnouncementsScreen> {
  String _selectedFilter = 'All';
  String _searchQuery = '';

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final monthStr = months[dt.month - 1];
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    final minuteStr = dt.minute.toString().padLeft(2, '0');
    return '$monthStr ${dt.day}, $hour:$minuteStr $amPm';
  }

  @override
  Widget build(BuildContext context) {
    final announcementsAsync = ref.watch(announcementsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Notice Board & Circulars',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            padding: EdgeInsets.fromLTRB(20, 10, 20, 16),
            color: AppColors.surface,
            child: Column(
              children: [
                TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search official circulars & notices...',
                    prefixIcon: Icon(
                      LucideIcons.search,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceContainerLow,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.r),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                SizedBox(height: 14.h),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children:
                        [
                          'All',
                          'High Priority',
                          'Controller of Exams',
                          'Academic Dean',
                          'Placement Cell',
                        ].map((filter) {
                          final isSelected = _selectedFilter == filter;
                          return Padding(
                            padding: EdgeInsets.only(right: 8.w),
                            child: FilterChip(
                              selected: isSelected,
                              label: Text(
                                filter,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.onSurface,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 12.sp,
                                ),
                              ),
                              onSelected: (_) =>
                                  setState(() => _selectedFilter = filter),
                              backgroundColor: AppColors.surfaceContainerLowest,
                              selectedColor: AppColors.primary,
                              checkmarkColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              side: BorderSide(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.outlineVariant,
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Announcements List
          Expanded(
            child: announcementsAsync.when(
              loading: () => Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text(
                  'Failed to load notices: $err',
                  style: AppTypography.bodyMedium,
                ),
              ),
              data: (list) {
                var filtered = list.where((item) {
                  final queryMatch =
                      item.title.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ||
                      item.message.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ||
                      item.author.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      );

                  if (!queryMatch) return false;
                  if (_selectedFilter == 'All') return true;
                  if (_selectedFilter == 'High Priority') {
                    return item.priority.toLowerCase() == 'high';
                  }
                  return item.author.toLowerCase().contains(
                    _selectedFilter.toLowerCase(),
                  );
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.bellOff,
                          size: 48,
                          color: AppColors.textSecondary.withValues(alpha: 0.5),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'No circulars or notices found',
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(announcementsStreamProvider);
                  },
                  child: ListView.separated(
                    padding: EdgeInsets.all(20.w),
                    itemCount: filtered.length,
                    separatorBuilder: (ctx, idx) => SizedBox(height: 14.h),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final isHigh = item.priority.toLowerCase() == 'high';

                      return Container(
                        padding: EdgeInsets.all(18.w),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: isHigh
                                ? AppColors.error.withValues(alpha: 0.5)
                                : AppColors.outlineVariant.withValues(
                                    alpha: 0.5,
                                  ),
                            width: isHigh ? 1.5 : 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(8.w),
                                        decoration: BoxDecoration(
                                          color: isHigh
                                              ? AppColors.errorContainer
                                              : AppColors.primaryContainer
                                                    .withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(10.r),
                                        ),
                                        child: Icon(
                                          isHigh
                                              ? LucideIcons.alertTriangle
                                              : LucideIcons.megaphone,
                                          color: isHigh
                                              ? AppColors.error
                                              : AppColors.primary,
                                          size: 18,
                                        ),
                                      ),
                                      SizedBox(width: 10.w),
                                      Expanded(
                                        child: Text(
                                          item.author,
                                          style: AppTypography.labelLarge.copyWith(
                                            color: isHigh
                                                ? AppColors.error
                                                : AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Text(
                                  _formatDate(item.createdAt),
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 11.sp,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12.h),
                            Text(
                              item.title,
                              style: AppTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.onSurface,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              item.message,
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.4.h,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
