import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/notes_repository.dart';
import '../../domain/models/note_model.dart';

final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  return NotesRepository();
});

class NotesQueryKey {
  final String userId;
  final String subjectCode;

  const NotesQueryKey({required this.userId, required this.subjectCode});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotesQueryKey &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          subjectCode == other.subjectCode;

  @override
  int get hashCode => userId.hashCode ^ subjectCode.hashCode;
}

class NotesNotifier extends AsyncNotifier<List<NoteModel>> {
  final NotesQueryKey arg;
  NotesNotifier(this.arg);

  @override
  FutureOr<List<NoteModel>> build() async {
    final repo = ref.read(notesRepositoryProvider);
    return await repo.getNotes(userId: arg.userId, subjectCode: arg.subjectCode);
  }

  Future<void> saveNote({
    String? existingId,
    required String title,
    required String content,
  }) async {
    final repo = ref.read(notesRepositoryProvider);
    await repo.addOrUpdateNote(
      userId: arg.userId,
      subjectCode: arg.subjectCode,
      existingId: existingId,
      title: title,
      content: content,
    );
    state = AsyncData(
      await repo.getNotes(userId: arg.userId, subjectCode: arg.subjectCode),
    );
  }

  Future<void> removeNote(String noteId) async {
    final repo = ref.read(notesRepositoryProvider);
    await repo.deleteNote(
      userId: arg.userId,
      subjectCode: arg.subjectCode,
      noteId: noteId,
    );
    state = AsyncData(
      await repo.getNotes(userId: arg.userId, subjectCode: arg.subjectCode),
    );
  }
}

final notesProvider = AsyncNotifierProvider.family<NotesNotifier, List<NoteModel>, NotesQueryKey>(
  (arg) => NotesNotifier(arg),
);
