import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/announcements_repository.dart';
import '../../domain/models/announcement_model.dart';

final announcementsRepositoryProvider = Provider<AnnouncementsRepository>((ref) {
  return AnnouncementsRepository();
});

final announcementsStreamProvider = StreamProvider<List<AnnouncementModel>>((ref) {
  final repo = ref.watch(announcementsRepositoryProvider);
  return repo.getAnnouncementsStream();
});
