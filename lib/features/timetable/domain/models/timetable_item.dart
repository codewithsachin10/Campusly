class TimetableItem {
  final String id;
  final String title;
  final String shortTitle;
  final String dayOfWeek; // 'mon', 'tue', 'wed', 'thu', 'fri'
  final String startTime; // e.g. '08:00 AM'
  final String endTime; // e.g. '09:40 AM'
  final int startHour; // 24h format
  final int startMinute;
  final int endHour; // 24h format
  final int endMinute;
  final String category; // 'Lab', 'Major', 'Elective', 'Lecture', 'Studio', 'Break'
  final String room; // e.g. 'ANEW101-A'
  final String instructor; // e.g. 'Rajammal K'
  final double progressPercentage; // e.g. 68.0
  final bool isBreak;
  final bool sharedSlot;
  final String? sharedSlotGroup;
  final String? subjectCode;

  const TimetableItem({
    required this.id,
    required this.title,
    required this.shortTitle,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.category,
    required this.room,
    required this.instructor,
    this.progressPercentage = 0.0,
    this.isBreak = false,
    this.sharedSlot = false,
    this.sharedSlotGroup,
    this.subjectCode,
  });

  String get timeRange => '$startTime — $endTime';

  TimetableItem copyWith({
    String? id,
    String? title,
    String? shortTitle,
    String? dayOfWeek,
    String? startTime,
    String? endTime,
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
    String? category,
    String? room,
    String? instructor,
    double? progressPercentage,
    bool? isBreak,
    bool? sharedSlot,
    String? sharedSlotGroup,
    String? subjectCode,
  }) {
    return TimetableItem(
      id: id ?? this.id,
      title: title ?? this.title,
      shortTitle: shortTitle ?? this.shortTitle,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      startHour: startHour ?? this.startHour,
      startMinute: startMinute ?? this.startMinute,
      endHour: endHour ?? this.endHour,
      endMinute: endMinute ?? this.endMinute,
      category: category ?? this.category,
      room: room ?? this.room,
      instructor: instructor ?? this.instructor,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      isBreak: isBreak ?? this.isBreak,
      sharedSlot: sharedSlot ?? this.sharedSlot,
      sharedSlotGroup: sharedSlotGroup ?? this.sharedSlotGroup,
      subjectCode: subjectCode ?? this.subjectCode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'shortTitle': shortTitle,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'startHour': startHour,
      'startMinute': startMinute,
      'endHour': endHour,
      'endMinute': endMinute,
      'category': category,
      'room': room,
      'instructor': instructor,
      'progressPercentage': progressPercentage,
      'isBreak': isBreak,
      'sharedSlot': sharedSlot,
      'sharedSlotGroup': sharedSlotGroup,
      'subjectCode': subjectCode,
    };
  }

  factory TimetableItem.fromJson(Map<String, dynamic> json) {
    final titleVal = json['title'] as String? ?? json['subjectName'] as String? ?? 'Class';
    final shortTitleVal = json['shortTitle'] as String? ?? json['subjectCode'] as String? ?? 'CLS';
    final dayVal = _normalizeDayOfWeek(json['dayOfWeek'] as String? ?? 'mon');
    
    final rawStartTime = json['startTime'] as String? ?? '08:00 AM';
    final rawEndTime = json['endTime'] as String? ?? '09:00 AM';
    
    final formattedStart = _formatTimeStr(rawStartTime);
    final formattedEnd = _formatTimeStr(rawEndTime);

    final startH = json['startHour'] as int? ?? _parseHour(rawStartTime, 8);
    final startM = json['startMinute'] as int? ?? _parseMinute(rawStartTime, 0);
    final endH = json['endHour'] as int? ?? _parseHour(rawEndTime, 9);
    final endM = json['endMinute'] as int? ?? _parseMinute(rawEndTime, 0);

    return TimetableItem(
      id: json['id'] as String? ?? '',
      title: titleVal,
      shortTitle: shortTitleVal,
      dayOfWeek: dayVal,
      startTime: formattedStart,
      endTime: formattedEnd,
      startHour: startH,
      startMinute: startM,
      endHour: endH,
      endMinute: endM,
      category: _normalizeCategory(json['category'] as String? ?? json['type'] as String?),
      room: json['room'] as String? ?? json['classroom'] as String? ?? 'TBA',
      instructor: json['instructor'] as String? ?? json['faculty'] as String? ?? 'Faculty',
      progressPercentage: (json['progressPercentage'] as num?)?.toDouble() ?? 0.0,
      isBreak: json['isBreak'] as bool? ?? (json['category'] == 'Break' || json['type'] == 'Break'),
      sharedSlot: json['sharedSlot'] as bool? ?? false,
      sharedSlotGroup: json['sharedSlotGroup'] as String?,
      subjectCode: json['subjectCode'] as String?,
    );
  }

  static String _normalizeDayOfWeek(String day) {
    final d = day.trim().toLowerCase();
    if (d.startsWith('mon')) return 'mon';
    if (d.startsWith('tue')) return 'tue';
    if (d.startsWith('wed')) return 'wed';
    if (d.startsWith('thu')) return 'thu';
    if (d.startsWith('fri')) return 'fri';
    if (d.startsWith('sat')) return 'sat';
    if (d.startsWith('sun')) return 'sun';
    return 'mon';
  }

  static String _normalizeCategory(String? cat) {
    if (cat == null || cat.isEmpty) return 'Lecture';
    final lower = cat.trim().toLowerCase();
    if (lower == 'lab') return 'Lab';
    if (lower == 'lecture') return 'Lecture';
    if (lower == 'major') return 'Major';
    if (lower == 'elective') return 'Elective';
    if (lower == 'studio') return 'Studio';
    if (lower == 'break') return 'Break';
    return cat[0].toUpperCase() + cat.substring(1);
  }

  static int _parseHour(String? timeStr, int defaultHour) {
    if (timeStr == null || timeStr.isEmpty) return defaultHour;
    try {
      final clean = timeStr.trim();
      final parts = clean.split(' ')[0].split(':');
      if (parts.isNotEmpty) {
        int h = int.parse(parts[0]);
        if (clean.toUpperCase().contains('PM') && h < 12) h += 12;
        if (clean.toUpperCase().contains('AM') && h == 12) h = 0;
        return h;
      }
    } catch (_) {}
    return defaultHour;
  }

  static int _parseMinute(String? timeStr, int defaultMinute) {
    if (timeStr == null || timeStr.isEmpty) return defaultMinute;
    try {
      final clean = timeStr.trim();
      final parts = clean.split(' ')[0].split(':');
      if (parts.length > 1) {
        return int.parse(parts[1]);
      }
    } catch (_) {}
    return defaultMinute;
  }

  static String _formatTimeStr(String timeStr) {
    if (timeStr.toUpperCase().contains('AM') || timeStr.toUpperCase().contains('PM')) {
      return timeStr;
    }
    try {
      final parts = timeStr.trim().split(':');
      if (parts.length == 2) {
        int h = int.parse(parts[0]);
        final mStr = parts[1].padLeft(2, '0');
        final period = h >= 12 ? 'PM' : 'AM';
        int displayH = h % 12;
        if (displayH == 0) displayH = 12;
        return '${displayH.toString().padLeft(2, '0')}:$mStr $period';
      }
    } catch (_) {}
    return timeStr;
  }
}
