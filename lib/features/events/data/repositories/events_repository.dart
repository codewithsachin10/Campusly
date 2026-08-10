import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/event_model.dart';

abstract class EventsRepository {
  Stream<List<EventModel>> getEventsStream();
  Stream<List<EventRegistrationModel>> getMyRegistrationsStream(
    String studentId,
  );
  Future<EventRegistrationModel?> checkRegistration(
    String eventId,
    String studentId,
  );
  Future<void> registerForEvent({
    required EventModel event,
    required String studentId,
    required String studentName,
    required String studentEmail,
    String? studentRegNo,
    String? department,
    String? year,
    String? sectionId,
    Map<String, dynamic>? customData,
  });
  Future<void> cancelRegistration({
    required String registrationId,
    required String eventId,
  });
}

class SupabaseEventsRepository implements EventsRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Stream<List<EventModel>> getEventsStream() {
    return _supabase.from('events').stream(primaryKey: ['id']).map((data) {
      final list = data
          .map((doc) => _mapRowToEventModel(doc))
          .where((e) => e.status != 'Draft') // Hide drafts from student app
          .toList();
      // Sort descending by date/time
      list.sort((a, b) {
        final cmp = b.date.compareTo(a.date);
        if (cmp != 0) return cmp;
        return b.startTime.compareTo(a.startTime);
      });
      return list;
    });
  }

  @override
  Stream<List<EventRegistrationModel>> getMyRegistrationsStream(
    String studentId,
  ) {
    if (studentId.isEmpty) return Stream.value([]);
    return _supabase
        .from('event_registrations')
        .stream(primaryKey: ['id'])
        .eq('studentId', studentId)
        .map(
          (data) => data.map((doc) => _mapRowToRegistrationModel(doc)).toList(),
        );
  }

  @override
  Future<EventRegistrationModel?> checkRegistration(
    String eventId,
    String studentId,
  ) async {
    if (eventId.isEmpty || studentId.isEmpty) return null;
    final response = await _supabase
        .from('event_registrations')
        .select()
        .eq('eventId', eventId)
        .eq('studentId', studentId)
        .maybeSingle();

    if (response == null) return null;
    return _mapRowToRegistrationModel(response);
  }

  @override
  Future<void> registerForEvent({
    required EventModel event,
    required String studentId,
    required String studentName,
    required String studentEmail,
    String? studentRegNo,
    String? department,
    String? year,
    String? sectionId,
    Map<String, dynamic>? customData,
  }) async {
    // Check if already registered
    final existing = await checkRegistration(event.id, studentId);
    if (existing != null) {
      return;
    }

    final regModel = EventRegistrationModel(
      id: '',
      eventId: event.id,
      eventTitle: event.title,
      studentId: studentId,
      studentName: studentName,
      studentEmail: studentEmail,
      studentRegNo: studentRegNo,
      department: department,
      year: year,
      sectionId: sectionId,
      status: 'Registered',
      customData: customData,
    );

    // Write registration record
    await _supabase.from('event_registrations').insert(regModel.toMap());

    // We can handle participantCount via a Postgres trigger or function in the future.
  }

  @override
  Future<void> cancelRegistration({
    required String registrationId,
    required String eventId,
  }) async {
    await _supabase
        .from('event_registrations')
        .delete()
        .eq('id', registrationId);
  }

  EventModel _mapRowToEventModel(Map<String, dynamic> row) {
    return EventModel.fromMap(row, row['id'].toString());
  }

  EventRegistrationModel _mapRowToRegistrationModel(Map<String, dynamic> row) {
    return EventRegistrationModel.fromMap(row, row['id'].toString());
  }
}
