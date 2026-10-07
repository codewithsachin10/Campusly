import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../data/repositories/support_repository.dart';
import '../../data/models/support_ticket.dart';

final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  return SupportRepository();
});

final myTicketsProvider = FutureProvider.autoDispose<List<SupportTicket>>((ref) async {
  final repository = ref.watch(supportRepositoryProvider);
  return await repository.getMyTickets();
});

final ticketMessagesStreamProvider = StreamProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, ticketId) {
  final repository = ref.watch(supportRepositoryProvider);
  return repository.subscribeToMessages(ticketId);
});

final supportFaqsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(supportRepositoryProvider);
  return await repository.getFAQs();
});

class CreateTicketNotifier extends AsyncNotifier<void> {
  late SupportRepository _repository;

  @override
  FutureOr<void> build() {
    _repository = ref.watch(supportRepositoryProvider);
    return null;
  }

  Future<bool> createTicket({
    required String subject,
    required String description,
    required String priority,
    String? categoryId,
  }) async {
    state = const AsyncLoading();
    try {
      String appVer = '1.1.0';
      try {
        final info = await PackageInfo.fromPlatform();
        appVer = '${info.version}+${info.buildNumber}';
      } catch (_) {}

      await _repository.createTicket(
        subject: subject,
        description: description,
        priority: priority,
        categoryId: categoryId,
        appVersion: appVer, 
        platform: 'Flutter Android',
      );
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final createTicketProvider = AsyncNotifierProvider<CreateTicketNotifier, void>(() {
  return CreateTicketNotifier();
});
