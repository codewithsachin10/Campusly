import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/connections_provider.dart';
import '../../domain/models/connection_model.dart';
import '../../data/connections_repository.dart';
import 'package:go_router/go_router.dart';

class ConnectionsScreen extends ConsumerWidget {
  const ConnectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionsAsync = ref.watch(connectionsStreamProvider);
    final user = ref.watch(authControllerProvider).value;

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
          'My Connections',
          style: AppTypography.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
      ),
      body: connectionsAsync.when(
        data: (connections) {
          final pending = connections
              .where(
                (c) =>
                    c.status == ConnectionStatus.pending &&
                    c.receiverId == user?.id,
              )
              .toList();
          final friends = connections
              .where((c) => c.status == ConnectionStatus.connected)
              .toList();

          return ListView(
            padding: EdgeInsets.all(16.w),
            children: [
              if (pending.isNotEmpty) ...[
                Text(
                  'Pending Requests (${pending.length})',
                  style: AppTypography.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 12.h),
                ...pending.map(
                  (c) => _ConnectionItem(connection: c, isPending: true),
                ),
                SizedBox(height: 24.h),
                Divider(),
                SizedBox(height: 24.h),
              ],
              Text(
                'My Friends (${friends.length})',
                style: AppTypography.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 12.h),
              if (friends.isEmpty)
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0.w),
                    child: Text(
                      'No connections yet.\nGo to the directory to find friends!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                ),
              ...friends.map(
                (c) => _ConnectionItem(connection: c, isPending: false),
              ),
            ],
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error loading connections: $e')),
      ),
    );
  }
}

class _ConnectionItem extends ConsumerWidget {
  final ConnectionModel connection;
  final bool isPending;

  const _ConnectionItem({required this.connection, required this.isPending});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authControllerProvider).value;
    final otherUserId = connection.requesterId == currentUser?.id
        ? connection.receiverId
        : connection.requesterId;

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
            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
            child: Icon(Icons.person, color: AppColors.primary),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'User $otherUserId', // In real app, fetch user details or cache them locally
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  isPending ? 'Wants to connect' : 'Connected',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12.sp),
                ),
              ],
            ),
          ),
          if (isPending)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.close, color: Colors.red),
                  onPressed: () {
                    // reject/delete
                  },
                ),
                IconButton(
                  icon: Icon(Icons.check, color: Colors.green),
                  onPressed: () {
                    ref
                        .read(connectionsRepositoryProvider)
                        .updateStatus(
                          connection.id,
                          ConnectionStatus.connected,
                        );
                  },
                ),
              ],
            )
          else
            IconButton(
              icon: Icon(Icons.message, color: AppColors.primary),
              onPressed: () {
                context.push('/inbox');
              },
            ),
        ],
      ),
    );
  }
}
