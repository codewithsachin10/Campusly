import 'dart:math';

class AttendanceLog {
  final String dateString; // e.g., '2026-07-20'
  final String status; // 'present', 'absent', 'cancelled'

  const AttendanceLog({required this.dateString, required this.status});

  factory AttendanceLog.fromJson(Map<String, dynamic> json) {
    return AttendanceLog(
      dateString: json['dateString'] as String? ?? '',
      status: json['status'] as String? ?? 'present',
    );
  }

  Map<String, dynamic> toJson() => {
    'dateString': dateString,
    'status': status,
  };
}

class AttendanceModel {
  final String subjectCode;
  final String subjectName;
  final int presentCount;
  final int totalCount;
  final List<AttendanceLog> history;

  const AttendanceModel({
    required this.subjectCode,
    required this.subjectName,
    this.presentCount = 0,
    this.totalCount = 0,
    this.history = const [],
  });

  double get percentage {
    if (totalCount <= 0) return 100.0;
    return (presentCount / totalCount) * 100.0;
  }

  int get safeBunkClasses {
    if (totalCount <= 0) return 0;
    final maxTotalForSafe = (presentCount / 0.75).floor();
    final safe = maxTotalForSafe - totalCount;
    return max(0, safe);
  }

  bool get willDropBelowIfMissedNext {
    if (totalCount <= 0) return false;
    final nextPercentage = (presentCount / (totalCount + 1)) * 100.0;
    return nextPercentage < 75.0;
  }

  AttendanceModel copyWith({
    String? subjectCode,
    String? subjectName,
    int? presentCount,
    int? totalCount,
    List<AttendanceLog>? history,
  }) {
    return AttendanceModel(
      subjectCode: subjectCode ?? this.subjectCode,
      subjectName: subjectName ?? this.subjectName,
      presentCount: presentCount ?? this.presentCount,
      totalCount: totalCount ?? this.totalCount,
      history: history ?? this.history,
    );
  }

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    final historyList = (json['history'] as List<dynamic>? ?? [])
        .map((e) => AttendanceLog.fromJson(e as Map<String, dynamic>))
        .toList();
    return AttendanceModel(
      subjectCode: json['subjectCode'] as String? ?? '',
      subjectName: json['subjectName'] as String? ?? '',
      presentCount: json['presentCount'] as int? ?? 0,
      totalCount: json['totalCount'] as int? ?? 0,
      history: historyList,
    );
  }

  Map<String, dynamic> toJson() => {
    'subjectCode': subjectCode,
    'subjectName': subjectName,
    'presentCount': presentCount,
    'totalCount': totalCount,
    'history': history.map((e) => e.toJson()).toList(),
  };
}
