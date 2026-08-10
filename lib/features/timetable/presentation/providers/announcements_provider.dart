import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/announcements_repository.dart';
import '../../domain/models/announcement_model.dart';

final announcementsRepositoryProvider =
    Provider<SupabaseAnnouncementsRepository>((ref) {
      return SupabaseAnnouncementsRepository();
    });

final announcementsStreamProvider = StreamProvider<List<AnnouncementModel>>((
  ref,
) {
  final repo = ref.watch(announcementsRepositoryProvider);
  return repo.getAnnouncementsStream();
});
