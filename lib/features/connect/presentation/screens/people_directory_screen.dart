import 'package:flutter/material.dart';
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
    Future.delayed(const Duration(milliseconds: 500), () {
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
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
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
          tabs: const [
            Tab(text: 'My Class'),
            Tab(text: 'My Dept'),
            Tab(text: 'College'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF1E3A8A)),
                filled: true,
                fillColor: AppColors.surfaceContainerLowest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                ? Center(
                    child: Text(
                      'No students found.',
                      style: AppTypography.textTheme.bodyLarge?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _users.length,
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

                      return _buildStudentCard(
                        context,
                        student,
                        conn,
                        currentUserId,
                      );
                    },
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
    Widget actionWidget = const SizedBox();

    if (connection == null) {
      actionWidget = IconButton(
        icon: const Icon(Icons.person_add_rounded, color: Color(0xFF1E3A8A)),
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
        actionWidget = const Text(
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
          child: const Text('Accept'),
        );
      }
    } else if (connection.status == ConnectionStatus.connected) {
      actionWidget = IconButton(
        icon: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF1E3A8A)),
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
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
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${student.department ?? "Dept"} - ${student.year ?? "Year"} - ${student.section ?? "Sec"}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
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
