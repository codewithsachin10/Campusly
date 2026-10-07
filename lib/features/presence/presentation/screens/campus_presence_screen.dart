import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/presence_model.dart';
import '../../data/location_repository.dart';
import '../../../connect/presentation/providers/connections_provider.dart';

final campusPresenceStreamProvider =
    StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
      final user = ref.watch(authControllerProvider).value;
      if (user == null) return Stream.empty();
      return ref.watch(locationRepositoryProvider).streamCampusPresence(user);
    });

class CampusPresenceScreen extends ConsumerStatefulWidget {
  const CampusPresenceScreen({super.key});

  @override
  ConsumerState<CampusPresenceScreen> createState() =>
      _CampusPresenceScreenState();
}

class _CampusPresenceScreenState extends ConsumerState<CampusPresenceScreen> {
  String _selectedLocation = 'Library';
  String _selectedVisibility = 'Classmates';
  String _selectedDuration = '1 Hour';

  final List<String> _locations = [
    'Library',
    'CS Block',
    'EC Block',
    'Canteen',
    'Sports Ground',
    'Auditorium',
  ];
  final List<String> _visibilities = [
    'Ghost Mode',
    'Friends',
    'Classmates',
    'Department',
    'Campus',
  ];
  final List<String> _durations = [
    '1 Hour',
    'End of Day',
    'Until I Leave Campus',
    'Manual',
  ];

  void _checkIn() async {
    final user = ref.read(authControllerProvider).value;
    if (user == null) return;

    DateTime expiresAt;
    final now = DateTime.now();
    if (_selectedDuration == '1 Hour') {
      expiresAt = now.add(Duration(hours: 1));
    } else if (_selectedDuration == 'End of Day') {
      expiresAt = DateTime(now.year, now.month, now.day, 23, 59, 59);
    } else if (_selectedDuration == 'Until I Leave Campus') {
      expiresAt = now.add(Duration(hours: 4)); // Approximation
    } else {
      expiresAt = now.add(
        Duration(days: 365),
      ); // Manual - arbitrarily long
    }

    final presence = PresenceModel(
      userId: user.id,
      location: _selectedLocation,
      visibility: _selectedVisibility,
      expiresAt: expiresAt,
      updatedAt: now,
      onlineStatus: 'Online',
    );

    await ref.read(locationRepositoryProvider).checkIn(presence);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Checked into $_selectedLocation!')),
      );
    }
  }

  void _checkOut() async {
    final user = ref.read(authControllerProvider).value;
    if (user == null) return;
    await ref.read(locationRepositoryProvider).clearCheckIn(user.id);
  }

  @override
  Widget build(BuildContext context) {
    final presenceAsync = ref.watch(campusPresenceStreamProvider);
    final user = ref.watch(authControllerProvider).value;
    final connections = ref.watch(connectionsStreamProvider).value ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Campus Now',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Check In Card
          Container(
            color: AppColors.surface,
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Share your location',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16.h),
                DropdownButtonFormField<String>(
                  initialValue: _selectedLocation,
                  decoration: InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                  ),
                  items: _locations
                      .map(
                        (loc) => DropdownMenuItem(value: loc, child: Text(loc)),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _selectedLocation = val!),
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _selectedVisibility,
                        decoration: InputDecoration(
                          labelText: 'Who can see',
                          border: OutlineInputBorder(),
                        ),
                        items: _visibilities
                            .map(
                              (vis) => DropdownMenuItem(
                                value: vis,
                                child: Text(vis, overflow: TextOverflow.ellipsis),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedVisibility = val!),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _selectedDuration,
                        decoration: InputDecoration(
                          labelText: 'Duration',
                          border: OutlineInputBorder(),
                        ),
                        items: _durations
                            .map(
                              (dur) => DropdownMenuItem(
                                value: dur,
                                child: Text(dur, overflow: TextOverflow.ellipsis),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedDuration = val!),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.location_on_rounded),
                        label: Text('Check In'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
                        onPressed: _checkIn,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error),
                        padding: EdgeInsets.symmetric(
                          vertical: 12.h,
                          horizontal: 24.w,
                        ),
                      ),
                      onPressed: _checkOut,
                      child: Text('Clear'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 8.h),

          // Tree View
          Expanded(
            child: presenceAsync.when(
              data: (presences) {
                // Filter and Group
                // In a real app, we'd fetch User objects for each presence to check connections/class.
                // For demonstration, we simulate visibility filtering loosely.
                final Map<String, List<Map<String, dynamic>>> grouped = {};
                for (var loc in _locations) {
                  grouped[loc] = [];
                }

                for (var p in presences) {
                  final loc = p['location'] as String;
                  final userId = p['userId'] as String;
                  final vis = p['visibility'] as String;

                  bool canSee = false;
                  if (vis == 'Everyone' || userId == user?.id) {
                    canSee = true;
                  } else if (vis == 'Friends' &&
                      connections.any(
                        (c) =>
                            c.requesterId == userId || c.receiverId == userId,
                      )) {
                    canSee = true;
                  } else if (vis == 'Classmates') {
                    // Assuming class check is complex, default to visible for prototype, or we'd fetch their user profile.
                    canSee = true;
                  }

                  if (canSee) {
                    if (grouped.containsKey(loc)) {
                      grouped[loc]!.add(p);
                    } else {
                      grouped[loc] = [p];
                    }
                  }
                }

                return ListView(
                  cacheExtent: 300,
                  padding: EdgeInsets.all(16.w),
                  children: grouped.entries.map((entry) {
                    if (entry.value.isEmpty) return SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        ...entry.value.map(
                          (p) => Padding(
                            padding: EdgeInsets.only(left: 16.w, bottom: 8.h),
                            child: Row(
                              children: [
                                Text(
                                  '├── ',
                                  style: TextStyle(color: AppColors.outline),
                                ),
                                Icon(
                                  Icons.person_rounded,
                                  size: 16,
                                  color: AppColors.onSurfaceVariant,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  p['userId'] == user?.id
                                      ? 'You'
                                      : 'User ${p['userId'].toString().length >= 4 ? p['userId'].toString().substring(0, 4) : p['userId']}',
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),
                      ],
                    );
                  }).toList(),
                );
              },
              loading: () => Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
