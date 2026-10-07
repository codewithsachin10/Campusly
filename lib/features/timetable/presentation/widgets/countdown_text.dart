import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/timetable_item.dart';
import '../providers/timetable_provider.dart';

/// Isolated countdown ticker widget that consumes [liveTickerProvider].
/// Prevents parent cards from rebuilding on every second tick.
class CountdownText extends ConsumerWidget {
  final TimetableItem item;

  const CountdownText({super.key, required this.item});

  static String _getDayStr(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'mon';
      case DateTime.tuesday:
        return 'tue';
      case DateTime.wednesday:
        return 'wed';
      case DateTime.thursday:
        return 'thu';
      case DateTime.friday:
        return 'fri';
      case DateTime.saturday:
        return 'sat';
      case DateTime.sunday:
        return 'sun';
      default:
        return 'mon';
    }
  }

  static String _getDayLabel(String day) {
    switch (day.toLowerCase()) {
      case 'mon':
        return 'Monday';
      case 'tue':
        return 'Tuesday';
      case 'wed':
        return 'Wednesday';
      case 'thu':
        return 'Thursday';
      case 'fri':
        return 'Friday';
      case 'sat':
        return 'Saturday';
      case 'sun':
        return 'Sunday';
      default:
        return day;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only this isolated widget listens to liveTickerProvider
    ref.watch(liveTickerProvider);

    final now = DateTime.now();
    final currentSecs = now.hour * 3600 + now.minute * 60 + now.second;
    final startSecs = item.startHour * 3600 + item.startMinute * 60;
    final isToday = item.dayOfWeek.toLowerCase() == _getDayStr(now.weekday);
    final diffSecs = startSecs - currentSecs;

    final isCountdown = isToday && diffSecs > 0;
    final String timerOrDateDisplay;
    if (isCountdown) {
      final h = (diffSecs ~/ 3600).toString().padLeft(2, '0');
      final m = ((diffSecs % 3600) ~/ 60).toString().padLeft(2, '0');
      final s = (diffSecs % 60).toString().padLeft(2, '0');
      timerOrDateDisplay = '$h:$m:$s';
    } else {
      timerOrDateDisplay =
          '${_getDayLabel(item.dayOfWeek).toUpperCase()} • ${item.startTime}';
    }

    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isCountdown ? 'NEXT CLASS IN' : 'UPCOMING CLASS ON',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.primary.withValues(alpha: 0.7),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            timerOrDateDisplay,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              fontSize: isCountdown ? 20.sp : 15.sp,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
