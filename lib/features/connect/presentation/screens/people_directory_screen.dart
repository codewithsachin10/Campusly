import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/connections_repository.dart';
import '../../../chat/data/chat_repository.dart';
import '../../../auth/domain/models/user_model.dart';
import '../providers/connections_provider.dart';
import '../../domain/models/connection_model.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/services/app_haptics.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../../../core/widgets/fade_slide_in.dart';
import '../../../../core/widgets/animated_state_switcher.dart';
import '../../../../core/widgets/empty_state.dart';

class PeopleDirectoryScreen extends ConsumerStatefulWidget {
  const PeopleDirectoryScreen({super.key});

  @override
  ConsumerState<PeopleDirectoryScreen> createState() =>
      _PeopleDirectoryScreenState();
}

class _PeopleDirectoryScreenState extends ConsumerState<PeopleDirectoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  List<UserModel> _users = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);

    // Fetch initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchUsers();
    });
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      AppHaptics.selectionClick();
      _fetchUsers();
    }
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);

    final repo = ref.read(connectionsRepositoryProvider);
    final user = ref.read(authControllerProvider).value;

    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    List<UserModel> results = [];

    try {
      if (_tabController.index == 0) {
        // My Class (Year + Dept + Section)
        results = await repo.searchDirectory(
          department: user.department,
          year: user.year,
          section: user.section,
          searchQuery: _searchQuery,
        );
      } else if (_tabController.index == 1) {
        // My Department
        results = await repo.searchDirectory(
          department: user.department,
          searchQuery: _searchQuery,
        );
      } else {
        // Entire College
        results = await repo.searchDirectory(searchQuery: _searchQuery);
      }

      // Filter out self
      results.removeWhere((u) => u.id == user.id);
    } catch (e) {
      debugPrint('Error fetching directory: $e');
    }

    if (mounted) {
      setState(() {
        _users = results;
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String val) {
    _searchQuery = val;
    // Simple debounce
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted && _searchQuery == val) {
        _fetchUsers();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final connectionsAsync = ref.watch(connectionsStreamProvider);
    final currentUserId = ref.watch(authControllerProvider).value?.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'People Directory',
          style: AppTypography.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.onSurfaceVariant,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: 'My Class'),
            Tab(text: 'My Dept'),
            Tab(text: 'College'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0.w),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                prefixIcon: Icon(Icons.search, color: Color(0xFF1E3A8A)),
                filled: true,
                fillColor: AppColors.surfaceContainerLowest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 16.h),
              ),
            ),
          ),
          Expanded(
            child: AnimatedStateSwitcher(
              child: _isLoading
                  ? KeyedSubtree(
                      key: const ValueKey('people_loading'),
                      child: AppShimmer(
                        child: ListView.separated(
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                          itemCount: 8,
                          separatorBuilder: (context, index) =>
                              SizedBox(height: 10.h),
                          itemBuilder: (context, index) =>
                              const SkeletonListTile(),
                        ),
                      ),
                    )
                  : _users.isEmpty
                  ? KeyedSubtree(
                      key: const ValueKey('people_empty'),
                      child: const EmptyState(
                        icon: LucideIcons.users,
                        title: 'No students found',
                        subtitle: 'Try searching with a different name or checking another tab.',
                      ),
                    )
                  : KeyedSubtree(
                      key: const ValueKey('people_list'),
                      child: ListView.separated(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                        itemCount: _users.length,
                        separatorBuilder: (context, index) =>
                            SizedBox(height: 10.h),
                        itemBuilder: (context, index) {
                          final student = _users[index];

                          // Determine connection status
                          ConnectionModel? conn;
                          connectionsAsync.whenData((list) {
                            try {
                              conn = list.firstWhere(
                                (c) =>
                                    c.requesterId == student.id ||
                                    c.receiverId == student.id,
                              );
                            } catch (_) {}
                          });

                          return FadeSlideIn(
                            index: index,
                            child: _buildStudentCard(
                              context,
                              student,
                              conn,
                              currentUserId,
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(
    BuildContext context,
    UserModel student,
    ConnectionModel? connection,
    String? currentUserId,
  ) {
    Widget actionWidget = SizedBox();

    if (connection == null) {
      actionWidget = IconButton(
        icon: Icon(Icons.person_add_rounded, color: Color(0xFF1E3A8A)),
        onPressed: () {
          if (currentUserId != null) {
            ref
                .read(connectionsRepositoryProvider)
                .sendRequest(currentUserId, student.id);
          }
        },
      );
    } else if (connection.status == ConnectionStatus.pending) {
      if (connection.requesterId == currentUserId) {
        actionWidget = Text(
          'Requested',
          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
        );
      } else {
        actionWidget = TextButton(
          onPressed: () {
            ref
                .read(connectionsRepositoryProvider)
                .updateStatus(connection.id, ConnectionStatus.connected);
          },
          child: Text('Accept'),
        );
      }
    } else if (connection.status == ConnectionStatus.connected) {
      actionWidget = IconButton(
        icon: Icon(Icons.chat_bubble_rounded, color: Color(0xFF1E3A8A)),
        onPressed: () async {
          if (currentUserId != null) {
            final chatId = await ref
                .read(chatRepositoryProvider)
                .createOrGetPrivateChat(currentUserId, student.id);
            if (context.mounted) {
              context.push(
                '/chat/$chatId?title=${Uri.encodeComponent(student.name)}',
              );
            }
          }
        },
      );
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
            child: Text(
              student.name.isNotEmpty ? student.name[0].toUpperCase() : 'S',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${student.department ?? "Dept"} - ${student.year ?? "Year"} - ${student.section ?? "Sec"}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12.sp),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          actionWidget,
        ],
      ),
    );
  }
}
