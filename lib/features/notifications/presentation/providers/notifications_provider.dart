import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../class_join/presentation/providers/class_provider.dart';
import '../../domain/models/notification_item_model.dart';
import '../../data/repositories/notifications_repository.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  return SupabaseNotificationsRepository();
});

final notificationsStreamProvider = StreamProvider<List<NotificationItemModel>>(
  (ref) {
    final repo = ref.watch(notificationsRepositoryProvider);
    return repo.getNotificationsStream();
  },
);

class NotificationsCategoryNotifier extends Notifier<String> {
  @override
  String build() => 'All';

  @override
  set state(String value) => super.state = value;
}

final notificationsCategoryFilterProvider =
    NotifierProvider<NotificationsCategoryNotifier, String>(
      NotificationsCategoryNotifier.new,
    );

final filteredNotificationsProvider =
    Provider<AsyncValue<List<NotificationItemModel>>>((ref) {
      final notifsAsync = ref.watch(notificationsStreamProvider);
      final user = ref.watch(authControllerProvider).value;
      final currentClass = ref.watch(currentClassProvider);
      final category = ref.watch(notificationsCategoryFilterProvider);

      return notifsAsync.whenData((notifs) {
        final result = <NotificationItemModel>[];

        for (final item in notifs) {
          // 1. Check Target Audience Match
          final aud = item.targetAudience;
          bool matchesAudience = false;

          if (aud.type == 'everyone' || aud.type.isEmpty) {
            matchesAudience = true;
          } else if (aud.type == 'department') {
            final userDept = user?.department?.toLowerCase() ?? '';
            final classDept = currentClass?.department.toLowerCase() ?? '';
            final targetDept = aud.departmentId?.toLowerCase() ?? '';
            if (targetDept.isNotEmpty &&
                (userDept == targetDept || classDept == targetDept)) {
              matchesAudience = true;
            }
          } else if (aud.type == 'year') {
            final targetYear = aud.year?.toLowerCase() ?? '';
            final classYear = currentClass?.academicYear.toLowerCase() ?? '';
            if (targetYear.isNotEmpty && classYear.contains(targetYear)) {
              matchesAudience = true;
            }
          } else if (aud.type == 'section') {
            final targetSec = aud.sectionId?.toLowerCase() ?? '';
            final classSec = currentClass?.section.toLowerCase() ?? '';
            if (targetSec.isNotEmpty && classSec.contains(targetSec)) {
              matchesAudience = true;
            }
          } else if (aud.type == 'studentIds') {
            final userId = user?.id ?? '';
            final userEmail = user?.email ?? '';
            if (aud.studentIds.contains(userId) ||
                aud.studentIds.contains(userEmail)) {
              matchesAudience = true;
            }
          }

          if (!matchesAudience) continue;

          // 2. Check Category Filter
          if (category != 'All') {
            if (item.category.toLowerCase() != category.toLowerCase()) {
              continue;
            }
          }

          result.add(item);
        }

        return result;
      });
    });

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifsAsync = ref.watch(filteredNotificationsProvider);
  final user = ref.watch(authControllerProvider).value;
  if (user == null || user.id.isEmpty) return 0;

  return notifsAsync.maybeWhen(
    data: (notifs) {
      return notifs.where((item) => !item.isReadBy(user.id)).length;
    },
    orElse: () => 0,
  );
});
