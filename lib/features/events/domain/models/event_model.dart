class TargetAudienceModel {
  final String type; // 'everyone', 'department', 'year', 'section'
  final String? departmentId;
  final String? year;
  final String? sectionId;

  const TargetAudienceModel({
    required this.type,
    this.departmentId,
    this.year,
    this.sectionId,
  });

  factory TargetAudienceModel.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const TargetAudienceModel(type: 'everyone');
    }
    return TargetAudienceModel(
      type: map['type'] as String? ?? 'everyone',
      departmentId: map['departmentId'] as String?,
      year: map['year'] as String?,
      sectionId: map['sectionId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'departmentId': departmentId,
      'year': year,
      'sectionId': sectionId,
    };
  }
}

class RegistrationSettingsModel {
  final bool isOpen;
  final String deadline; // YYYY-MM-DD
  final int maxParticipants;
  final List<String> customFields;

  const RegistrationSettingsModel({
    required this.isOpen,
    required this.deadline,
    required this.maxParticipants,
    required this.customFields,
  });

  factory RegistrationSettingsModel.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const RegistrationSettingsModel(
        isOpen: true,
        deadline: '',
        maxParticipants: 200,
        customFields: [],
      );
    }
    final rawFields = map['customFields'];
    List<String> fields = [];
    if (rawFields is List) {
      fields = rawFields.map((e) => e.toString()).toList();
    }
    return RegistrationSettingsModel(
      isOpen: map['isOpen'] as bool? ?? true,
      deadline: map['deadline'] as String? ?? '',
      maxParticipants: (map['maxParticipants'] as num?)?.toInt() ?? 200,
      customFields: fields,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isOpen': isOpen,
      'deadline': deadline,
      'maxParticipants': maxParticipants,
      'customFields': customFields,
    };
  }
}

class EventModel {
  final String id;
  final String title;
  final String description;
  final String type; // Hackathon, Workshop, Symposium, Club Event, etc.
  final String posterUrl;
  final String organizer;
  final String venue;
  final String date; // YYYY-MM-DD
  final String startTime;
  final String endTime;
  final String
  status; // Draft, Published, Registration Open, Registration Closed, Completed
  final int participantCount;
  final TargetAudienceModel targetAudience;
  final RegistrationSettingsModel registrationSettings;
  final DateTime? updatedAt;

  const EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.posterUrl,
    required this.organizer,
    required this.venue,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.participantCount,
    required this.targetAudience,
    required this.registrationSettings,
    this.updatedAt,
  });

  factory EventModel.fromMap(Map<String, dynamic> data, String docId) {
    DateTime? updated;
    if (data['updatedAt'] != null && data['updatedAt'] is String) {
      updated = DateTime.tryParse(data['updatedAt']);
    } else if (data['updated_at'] != null && data['updated_at'] is String) {
      updated = DateTime.tryParse(data['updated_at']);
    }

    return EventModel(
      id: docId,
      title: data['title'] as String? ?? 'Untitled Event',
      description: data['description'] as String? ?? '',
      type: data['type'] as String? ?? 'Hackathon',
      posterUrl:
          data['posterUrl'] as String? ?? data['poster_url'] as String? ?? '',
      organizer: data['organizer'] as String? ?? 'Campusly Organizer',
      venue: data['venue'] as String? ?? 'TBA',
      date: data['date'] as String? ?? '',
      startTime:
          data['startTime'] as String? ??
          data['start_time'] as String? ??
          '09:00',
      endTime:
          data['endTime'] as String? ?? data['end_time'] as String? ?? '17:00',
      status: data['status'] as String? ?? 'Published',
      participantCount:
          (data['participantCount'] ?? data['participant_count'] as num?)
              ?.toInt() ??
          0,
      targetAudience: TargetAudienceModel.fromMap(
        data['targetAudience'] as Map<String, dynamic>? ??
            data['target_audience'] as Map<String, dynamic>?,
      ),
      registrationSettings: RegistrationSettingsModel.fromMap(
        data['registrationSettings'] as Map<String, dynamic>? ??
            data['registration_settings'] as Map<String, dynamic>?,
      ),
      updatedAt: updated,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'type': type,
      'poster_url': posterUrl,
      'organizer': organizer,
      'venue': venue,
      'date': date,
      'start_time': startTime,
      'end_time': endTime,
      'status': status,
      'participant_count': participantCount,
      'target_audience': targetAudience.toMap(),
      'registration_settings': registrationSettings.toMap(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}

class EventRegistrationModel {
  final String id;
  final String eventId;
  final String eventTitle;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final String? studentRegNo;
  final String? department;
  final String? year;
  final String? sectionId;
  final String status; // 'Registered', 'Cancelled', 'Attended'
  final Map<String, dynamic>? customData;
  final DateTime? registeredAt;

  const EventRegistrationModel({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    this.studentRegNo,
    this.department,
    this.year,
    this.sectionId,
    required this.status,
    this.customData,
    this.registeredAt,
  });

  factory EventRegistrationModel.fromMap(
    Map<String, dynamic> data,
    String docId,
  ) {
    DateTime? regAt;
    if (data['registeredAt'] != null && data['registeredAt'] is String) {
      regAt = DateTime.tryParse(data['registeredAt']);
    } else if (data['registered_at'] != null &&
        data['registered_at'] is String) {
      regAt = DateTime.tryParse(data['registered_at']);
    }

    return EventRegistrationModel(
      id: docId,
      eventId: data['eventId'] ?? data['event_id'] as String? ?? '',
      eventTitle: data['eventTitle'] ?? data['event_title'] as String? ?? '',
      studentId: data['studentId'] ?? data['student_id'] as String? ?? '',
      studentName: data['studentName'] ?? data['student_name'] as String? ?? '',
      studentEmail:
          data['studentEmail'] ?? data['student_email'] as String? ?? '',
      studentRegNo: data['studentRegNo'] ?? data['student_reg_no'] as String?,
      department: data['department'] as String?,
      year: data['year'] as String?,
      sectionId: data['sectionId'] ?? data['section_id'] as String?,
      status: data['status'] as String? ?? 'Registered',
      customData:
          data['customData'] ?? data['custom_data'] as Map<String, dynamic>?,
      registeredAt: regAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'event_id': eventId,
      'event_title': eventTitle,
      'student_id': studentId,
      'student_name': studentName,
      'student_email': studentEmail,
      'student_reg_no': studentRegNo,
      'department': department,
      'year': year,
      'section_id': sectionId,
      'status': status,
      'custom_data': customData,
      'registered_at': DateTime.now().toIso8601String(),
    };
  }
}
