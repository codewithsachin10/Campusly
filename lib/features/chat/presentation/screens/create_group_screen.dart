import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../connect/presentation/providers/connections_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/chat_repository.dart';
import '../../../connect/domain/models/connection_model.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final Set<String> _selectedUserIds = {};
  bool _isLoading = false;

  void _createGroup() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a name and select at least 1 member'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authControllerProvider).value;
      if (user != null) {
        final repo = ref.read(chatRepositoryProvider);
        await repo.createGroupChat(user.id, name, _selectedUserIds.toList());
        if (mounted) {
          // Navigate to the new group chat
          // context.replace('/chat/$chatId');
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectionsAsync = ref.watch(connectionsStreamProvider);
    final user = ref.watch(authControllerProvider).value;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Create Group',
          style: TextStyle(color: AppColors.primary),
        ),
        leading: BackButton(color: AppColors.primary),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createGroup,
            child: _isLoading
                ? SizedBox(
                    width: 20.w,
                    height: 20.h,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Create',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0.w),
            child: TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Group Name',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Divider(),
          Padding(
            padding: EdgeInsets.all(16.0.w),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Select Members (${_selectedUserIds.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: connectionsAsync.when(
              data: (connections) {
                final friends = connections
                    .where((c) => c.status == ConnectionStatus.connected)
                    .toList();

                if (friends.isEmpty) {
                  return Center(
                    child: Text('You need connections to create a group.'),
                  );
                }

                return ListView.builder(
                  itemCount: friends.length,
                  itemBuilder: (context, index) {
                    final connection = friends[index];
                    final friendId = connection.requesterId == user?.id
                        ? connection.receiverId
                        : connection.requesterId;

                    final isSelected = _selectedUserIds.contains(friendId);

                    return CheckboxListTile(
                      title: Text(
                        'User $friendId',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ), // Real app should join with user profiles
                      value: isSelected,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedUserIds.add(friendId);
                          } else {
                            _selectedUserIds.remove(friendId);
                          }
                        });
                      },
                    );
                  },
                );
              },
              loading: () => Center(child: CircularProgressIndicator()),
              error: (e, st) =>
                  Center(child: Text('Error loading connections: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
