import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/attendance_repository.dart';
import '../../domain/models/attendance_model.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository();
});

class AttendanceQueryKey {
  final String userId;
  final String subjectCode;
  final String subjectName;

  const AttendanceQueryKey({
    required this.userId,
    required this.subjectCode,
    required this.subjectName,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceQueryKey &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          subjectCode == other.subjectCode &&
          subjectName == other.subjectName;

  @override
  int get hashCode => userId.hashCode ^ subjectCode.hashCode ^ subjectName.hashCode;
}

class AttendanceNotifier extends AsyncNotifier<AttendanceModel> {
  final AttendanceQueryKey arg;
  AttendanceNotifier(this.arg);

  @override
  FutureOr<AttendanceModel> build() async {
    final repo = ref.read(attendanceRepositoryProvider);
    return await repo.getAttendance(
      userId: arg.userId,
      subjectCode: arg.subjectCode,
      subjectName: arg.subjectName,
    );
  }

  Future<void> markStatus(String status, {String? dateString}) async {
    final current = state.value;
    if (current == null) return;

    final dateStr = dateString ?? DateTime.now().toIso8601String().split('T')[0];
    final existingIndex = current.history.indexWhere((h) => h.dateString == dateStr);
    
    int newPresent = current.presentCount;
    int newTotal = current.totalCount;
    List<AttendanceLog> newHistory = List.from(current.history);

    if (existingIndex >= 0) {
      final oldStatus = newHistory[existingIndex].status;
      if (oldStatus == 'present') newPresent = (newPresent - 1).clamp(0, 9999);
      if (oldStatus != 'cancelled') newTotal = (newTotal - 1).clamp(0, 9999);
      newHistory.removeAt(existingIndex);
    }

    if (status == 'present') {
      newPresent++;
      newTotal++;
      newHistory.insert(0, AttendanceLog(dateString: dateStr, status: status));
    } else if (status == 'absent') {
      newTotal++;
      newHistory.insert(0, AttendanceLog(dateString: dateStr, status: status));
    } else if (status == 'cancelled') {
      newHistory.insert(0, AttendanceLog(dateString: dateStr, status: status));
    }

    final updated = current.copyWith(
      presentCount: newPresent,
      totalCount: newTotal,
      history: newHistory,
    );

    state = AsyncData(updated);
    final repo = ref.read(attendanceRepositoryProvider);
    await repo.saveAttendance(userId: arg.userId, model: updated);
  }

  Future<void> updateCounts(int present, int total) async {
    final current = state.value;
    if (current == null) return;

    final updated = current.copyWith(
      presentCount: present.clamp(0, total),
      totalCount: total.clamp(0, 9999),
    );

    state = AsyncData(updated);
    final repo = ref.read(attendanceRepositoryProvider);
    await repo.saveAttendance(userId: arg.userId, model: updated);
  }
}

final attendanceProvider = AsyncNotifierProvider.family<AttendanceNotifier, AttendanceModel, AttendanceQueryKey>(
  (arg) => AttendanceNotifier(arg),
);
