enum ReleasePriority {
  normal,
  recommended,
  important,
  critical,
}

enum ReleaseChannel {
  stable,
  beta,
  internal,
}

enum NoteCategory {
  newFeature,
  improved,
  fixed,
  security,
  performance,
  design,
}

ReleasePriority _priorityFromString(String value) {
  switch (value) {
    case 'CRITICAL':
      return ReleasePriority.critical;
    case 'IMPORTANT':
      return ReleasePriority.important;
    case 'RECOMMENDED':
      return ReleasePriority.recommended;
    default:
      return ReleasePriority.normal;
  }
}

ReleaseChannel _channelFromString(String value) {
  switch (value) {
    case 'BETA':
      return ReleaseChannel.beta;
    case 'INTERNAL':
      return ReleaseChannel.internal;
    default:
      return ReleaseChannel.stable;
  }
}

NoteCategory _categoryFromString(String value) {
  switch (value) {
    case 'IMPROVED':
      return NoteCategory.improved;
    case 'FIXED':
      return NoteCategory.fixed;
    case 'SECURITY':
      return NoteCategory.security;
    case 'PERFORMANCE':
      return NoteCategory.performance;
    case 'DESIGN':
      return NoteCategory.design;
    case 'NEW':
    default:
      return NoteCategory.newFeature;
  }
}

class ReleaseNote {
  final String id;
  final String releaseId;
  final NoteCategory category;
  final String? title;
  final String description;
  final int sortOrder;

  ReleaseNote({
    required this.id,
    required this.releaseId,
    required this.category,
    this.title,
    required this.description,
    this.sortOrder = 0,
  });

  factory ReleaseNote.fromJson(Map<String, dynamic> json) {
    return ReleaseNote(
      id: json['id'] as String,
      releaseId: json['release_id'] as String,
      category: _categoryFromString(json['category'] as String? ?? 'NEW'),
      title: json['title'] as String?,
      description: json['description'] as String? ?? '',
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }
}

class AppRelease {
  final String id;
  final String version;
  final int buildNumber;
  final String title;
  final String? description;
  final ReleasePriority priority;
  final ReleaseChannel channel;
  final String minimumSupportedVersion;
  final String status;
  final bool isPublished;
  final DateTime? publishedAt;
  final String downloadUrl;
  final int? fileSizeBytes;
  final List<ReleaseNote> releaseNotes;

  AppRelease({
    required this.id,
    required this.version,
    required this.buildNumber,
    required this.title,
    this.description,
    required this.priority,
    required this.channel,
    required this.minimumSupportedVersion,
    required this.status,
    required this.isPublished,
    this.publishedAt,
    required this.downloadUrl,
    this.fileSizeBytes,
    this.releaseNotes = const [],
  });

  factory AppRelease.fromJson(Map<String, dynamic> json) {
    var notesJson = json['release_notes'] as List<dynamic>?;
    List<ReleaseNote> parsedNotes = [];
    if (notesJson != null) {
      parsedNotes = notesJson
          .map((e) => ReleaseNote.fromJson(e as Map<String, dynamic>))
          .toList();
      parsedNotes.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }

    return AppRelease(
      id: json['id'] as String,
      version: json['version'] as String? ?? '1.0.0',
      buildNumber: json['build_number'] as int? ?? 1,
      title: json['title'] as String? ?? 'Release',
      description: json['description'] as String?,
      priority: _priorityFromString(json['priority'] as String? ?? 'NORMAL'),
      channel: _channelFromString(json['channel'] as String? ?? 'STABLE'),
      minimumSupportedVersion: json['minimum_supported_version'] as String? ?? '1.0.0',
      status: json['status'] as String? ?? 'DRAFT',
      isPublished: json['is_published'] as bool? ?? false,
      publishedAt: json['published_at'] != null
          ? DateTime.parse(json['published_at'] as String)
          : null,
      downloadUrl: json['apk_url'] as String? ?? json['download_url'] as String? ?? '',
      fileSizeBytes: json['apk_size'] as int? ?? json['file_size_bytes'] as int?,
      releaseNotes: parsedNotes,
    );
  }
}
