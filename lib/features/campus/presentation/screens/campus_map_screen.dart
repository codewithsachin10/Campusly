import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../presence/domain/models/presence_model.dart';
import '../../domain/models/campus_event.dart';
import '../widgets/campus_search_bar.dart';

class CampusMapScreen extends ConsumerStatefulWidget {
  const CampusMapScreen({super.key});

  @override
  ConsumerState<CampusMapScreen> createState() => _CampusMapScreenState();
}

class _CampusMapScreenState extends ConsumerState<CampusMapScreen> {
  final MapController _mapController = MapController();
  final LatLng _campusCenter = LatLng(
    13.00831,
    80.00331,
  ); // Rajalakshmi Engineering College
  List<PresenceModel> _presences = [];
  Map<String, Map<String, dynamic>> _userProfiles = {};
  List<CampusEvent> _events = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  String _searchQuery = '';
  final List<String> _filters = ['All', 'Friends', 'Events', 'Places'];

  @override
  void initState() {
    super.initState();
    _fetchMapData();
  }

  Future<void> _fetchMapData() async {
    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final presencesData = await supabase.from('campus_presence').select();
      final presences = presencesData
          .map((doc) => PresenceModel.fromJson(doc))
          .toList();

      final Map<String, Map<String, dynamic>> profiles = {};
      for (var p in presences) {
        if (!profiles.containsKey(p.userId)) {
          final userDoc = await supabase
              .from('users')
              .select()
              .eq('id', p.userId)
              .maybeSingle();
          if (userDoc != null) {
            profiles[p.userId] = {
              'name': userDoc['name'] ?? 'Unknown',
              'color':
                  Colors.primaries[p.userId.hashCode % Colors.primaries.length],
            };
          } else {
            profiles[p.userId] = {'name': 'Unknown', 'color': Colors.grey};
          }
        }
      }

      if (mounted) {
        setState(() {
          _presences = presences;
          _userProfiles = profiles;
          _events = [
            CampusEvent(
              id: 'event_1',
              title: 'Hackathon 2026',
              locationName: 'CS Block, Seminar Hall',
              latitude: 13.00850,
              longitude: 80.00350,
              startTime: DateTime.now().add(Duration(hours: 2)),
              endTime: DateTime.now().add(Duration(hours: 24)),
              category: 'Tech',
            ),
            CampusEvent(
              id: 'event_2',
              title: 'Basketball Finals',
              locationName: 'Sports Ground',
              latitude: 13.00750,
              longitude: 80.00250,
              startTime: DateTime.now().add(Duration(hours: 5)),
              endTime: DateTime.now().add(Duration(hours: 7)),
              category: 'Sports',
            ),
          ];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _moveToFriend(PresenceModel presence) {
    if (presence.latitude != null && presence.longitude != null) {
      _mapController.move(
        LatLng(presence.latitude!, presence.longitude!),
        17.0,
      );
      _showProfileCard(presence);
    }
  }

  void _showProfileCard(PresenceModel presence) {
    final profile =
        _userProfiles[presence.userId] ??
        {'name': 'Unknown', 'color': Colors.grey};
    final name = profile['name'] as String;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: profile['color'] as Color,
              child: Text(
                name[0],
                style: TextStyle(fontSize: 32.sp, color: Colors.white),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              name,
              style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.h),
            Text(
              '📍 ${presence.location}',
              style: TextStyle(fontSize: 16.sp, color: Colors.grey),
            ),
            SizedBox(height: 24.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Message'),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    child: Text('View Profile'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  List<Marker> _buildMarkers() {
    if (_selectedFilter == 'Events' || _selectedFilter == 'Places') return [];

    final Map<String, List<PresenceModel>> grouped = {};
    for (var p in _presences) {
      if (_searchQuery.isNotEmpty) {
        final profile = _userProfiles[p.userId] ?? {'name': 'Unknown'};
        final name = profile['name'] as String;
        if (!name.toLowerCase().contains(_searchQuery.toLowerCase())) {
          continue;
        }
      }
      if (p.latitude != null && p.longitude != null) {
        final key = '${p.latitude}_${p.longitude}';
        grouped.putIfAbsent(key, () => []).add(p);
      }
    }

    return grouped.entries.map((entry) {
      final list = entry.value;
      final first = list.first;
      final point = LatLng(first.latitude!, first.longitude!);

      if (list.length == 1) {
        final profile =
            _userProfiles[first.userId] ?? {'name': '?', 'color': Colors.grey};
        return Marker(
          point: point,
          width: 60.w,
          height: 60.h,
          child: GestureDetector(
            onTap: () => _moveToFriend(first),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: profile['color'] as Color,
                  child: Text(
                    (profile['name'] as String)[0],
                    style: TextStyle(color: Colors.white, fontSize: 14.sp),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: 2.h),
                  padding: EdgeInsets.symmetric(
                    horizontal: 4.w,
                    vertical: 2.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    profile['name'] as String,
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        return Marker(
          point: point,
          width: 60.w,
          height: 60.h,
          child: GestureDetector(
            onTap: () {
              // Zoom in on cluster
              _mapController.move(point, _mapController.camera.zoom + 1);
            },
            child: CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primary,
              child: Text(
                '👥 ${list.length}',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      }
    }).toList();
  }

  List<Marker> _buildEventMarkers() {
    if (_selectedFilter == 'Friends' || _selectedFilter == 'Places') return [];

    return _events.where((event) {
      if (_searchQuery.isNotEmpty) {
        return event.title.toLowerCase().contains(_searchQuery.toLowerCase()) || 
               event.locationName.toLowerCase().contains(_searchQuery.toLowerCase());
      }
      return true;
    }).map((event) {
      return Marker(
        point: LatLng(event.latitude, event.longitude),
        width: 100.w,
        height: 60.h,
        child: GestureDetector(
          onTap: () {
            _showEventCard(event);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(Icons.event, color: Colors.white, size: 20),
              ),
              Container(
                margin: EdgeInsets.only(top: 2.h),
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.r),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 2),
                  ],
                ),
                child: Text(
                  event.title,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  void _showEventCard(CampusEvent event) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Icon(
                    Icons.event,
                    color: Colors.orange,
                    size: 32,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        event.category ?? 'Event',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.grey, size: 20),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    event.locationName,
                    style: TextStyle(fontSize: 16.sp),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.grey, size: 20),
                SizedBox(width: 8.w),
                Text(
                  '${event.startTime.hour}:${event.startTime.minute.toString().padLeft(2, '0')} - ${event.endTime.hour}:${event.endTime.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 16.sp),
                ),
              ],
            ),
            if (event.description != null) ...[
              SizedBox(height: 16.h),
              Text(
                event.description!,
                style: TextStyle(fontSize: 16.sp, color: Colors.grey),
              ),
            ],
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                child: Text(
                  'View Event Details',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _campusCenter,
              initialZoom: 15.5,
              maxZoom: 19.0,
              minZoom: 10.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.campusly.app',
              ),
              MarkerLayer(
                markers: [..._buildEventMarkers(), ..._buildMarkers()],
              ),
            ],
          ),

          // Top Search Bar and Filters
          SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 16.h, left: 16.w, right: 16.w),
                  child: CampusSearchBar(
                    onSearch: (query) {
                      setState(() => _searchQuery = query);
                    },
                  ),
                ),
                SizedBox(height: 12.h),
                SizedBox(
                  height: 40.h,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    itemCount: _filters.length,
                    itemBuilder: (context, index) {
                      final filter = _filters[index];
                      final isSelected = filter == _selectedFilter;
                      return Padding(
                        padding: EdgeInsets.only(right: 8.w),
                        child: FilterChip(
                          selected: isSelected,
                          label: Text(
                            filter,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          backgroundColor: Colors.white,
                          selectedColor: AppColors.primary,
                          checkmarkColor: Colors.white,
                          onSelected: (selected) {
                            setState(() => _selectedFilter = filter);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Top Right Action Buttons
          Positioned(
            top: 100.h,
            right: 16.w,
            child: Column(
              children: [
                InkWell(
                  onTap: () {},
                  child: Container(
                    width: 48.w,
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.layers_outlined,
                      color: Colors.black87,
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                InkWell(
                  onTap: () {
                    _mapController.move(_campusCenter, 16.5);
                  },
                  child: Container(
                    width: 48.w,
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(Icons.my_location, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          if (_isLoading)
            Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0.w),
                  child: CircularProgressIndicator(),
                ),
              ),
            ),

          // Bottom Info Area
          Positioned(
            bottom: 0.h,
            left: 0.w,
            right: 0.w,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Next Class Floating Card
                  Container(
                    margin: EdgeInsets.only(
                      left: 16.w,
                      right: 16.w,
                      bottom: 16.h,
                    ),
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(Icons.class_, color: Colors.white),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'NEXT CLASS IN 15 MINS',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                'Operating Systems Lab',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.sp,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'CS Block • Lab 3',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13.sp,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Text(
                            'Directions',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // "YOU ARE AT" Card
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 16.w),
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(24.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 15,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16.r),
                          child: Container(
                            width: 60.w,
                            height: 60.h,
                            color: Colors.blue[50],
                            child: Icon(
                              Icons.business,
                              color: AppColors.primary,
                              size: 32,
                            ),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8.w,
                                    height: 8.h,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: 6.w),
                                  Text(
                                    'YOU ARE AT',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'Main Science Libr...',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.sp,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                'Level 1 • Deep Focus Zone',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 44.w,
                          height: 44.h,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                          child: Icon(
                            Icons.directions,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // "Friends Nearby" label
                  Transform.translate(
                    offset: Offset(32, -12),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'Friends Nearby',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.sp,
                        ),
                      ),
                    ),
                  ),

                  // Friends List
                  if (_presences.isNotEmpty) ...[
                    SizedBox(
                      height: 100.h,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        itemCount: _presences.length,
                        itemBuilder: (context, index) {
                          final p = _presences[index];
                          final profile =
                              _userProfiles[p.userId] ??
                              {'name': '?', 'color': Colors.grey};
                          final name = profile['name'] as String;
                          final color = profile['color'] as Color;

                          return Container(
                            margin: EdgeInsets.only(right: 16.w),
                            width: 70.w,
                            child: Column(
                              children: [
                                Stack(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(3.w),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.primary,
                                          width: 2.w,
                                        ),
                                      ),
                                      child: CircleAvatar(
                                        radius: 26,
                                        backgroundColor: color,
                                        child: Text(
                                          name.isNotEmpty
                                              ? name[0].toUpperCase()
                                              : '?',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 24.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 0.w,
                                      bottom: 0.h,
                                      child: Container(
                                        padding: EdgeInsets.all(4.w),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black12,
                                              blurRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.coffee,
                                          size: 12,
                                          color: Colors.brown,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.sp,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ] else ...[
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 32.w,
                        vertical: 8.h,
                      ),
                      child: Text(
                        'No friends nearby right now.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                  SizedBox(height: 16.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
