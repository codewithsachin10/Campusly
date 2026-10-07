import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/event_model.dart';
import '../../data/repositories/events_repository.dart';

final eventsRepositoryProvider = Provider<EventsRepository>((ref) {
  return SupabaseEventsRepository();
});

final eventsStreamProvider = StreamProvider<List<EventModel>>((ref) {
  final repo = ref.watch(eventsRepositoryProvider);
  return repo.getEventsStream();
});

final myRegistrationsProvider =
    StreamProvider.autoDispose<List<EventRegistrationModel>>((ref) {
      final user = ref.watch(authControllerProvider).value;
      final repo = ref.watch(eventsRepositoryProvider);
      if (user == null || user.id.isEmpty) {
        return Stream.value([]);
      }
      return repo.getMyRegistrationsStream(user.id);
    });

class EventsCategoryNotifier extends Notifier<String> {
  @override
  String build() => 'All';

  @override
  set state(String value) => super.state = value;
}

final eventsCategoryFilterProvider =
    NotifierProvider<EventsCategoryNotifier, String>(
      EventsCategoryNotifier.new,
    );

class EventsSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  @override
  set state(String value) => super.state = value;
}

final eventsSearchQueryProvider =
    NotifierProvider<EventsSearchQueryNotifier, String>(
      EventsSearchQueryNotifier.new,
    );

class EventWithRegistrationState {
  final EventModel event;
  final EventRegistrationModel? registration;

  bool get isRegistered =>
      registration != null && registration!.status == 'Registered';

  const EventWithRegistrationState({required this.event, this.registration});
}

final filteredEventsProvider =
    Provider<AsyncValue<List<EventWithRegistrationState>>>((ref) {
      final eventsAsync = ref.watch(eventsStreamProvider);
      final regsAsync = ref.watch(myRegistrationsProvider);
      final category = ref.watch(eventsCategoryFilterProvider);
      final query = ref.watch(eventsSearchQueryProvider).trim().toLowerCase();

      return eventsAsync.whenData((events) {
        final regs = regsAsync.value ?? [];

        // Map registrations by eventId
        final regMap = <String, EventRegistrationModel>{};
        for (final reg in regs) {
          if (reg.status == 'Registered') {
            regMap[reg.eventId] = reg;
          }
        }

        final result = <EventWithRegistrationState>[];
        for (final event in events) {
          // Filter by Category
          if (category != 'All' &&
              event.type.toLowerCase() != category.toLowerCase()) {
            continue;
          }

          // Filter by Search Query
          if (query.isNotEmpty) {
            final matchTitle = event.title.toLowerCase().contains(query);
            final matchDesc = event.description.toLowerCase().contains(query);
            final matchVenue = event.venue.toLowerCase().contains(query);
            final matchOrg = event.organizer.toLowerCase().contains(query);
            if (!matchTitle && !matchDesc && !matchVenue && !matchOrg) {
              continue;
            }
          }

          result.add(
            EventWithRegistrationState(
              event: event,
              registration: regMap[event.id],
            ),
          );
        }

        return result;
      });
    });
