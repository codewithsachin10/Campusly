import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/note_model.dart';
import '../providers/notes_provider.dart';

class SubjectNotesHubSheet extends ConsumerStatefulWidget {
  final String subjectCode;
  final String subjectName;

  const SubjectNotesHubSheet({
    super.key,
    required this.subjectCode,
    required this.subjectName,
  });

  static void show(BuildContext context, {required String subjectCode, required String subjectName}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SubjectNotesHubSheet(
        subjectCode: subjectCode,
        subjectName: subjectName,
      ),
    );
  }

  @override
  ConsumerState<SubjectNotesHubSheet> createState() => _SubjectNotesHubSheetState();
}

class _SubjectNotesHubSheetState extends ConsumerState<SubjectNotesHubSheet> {
  void _showNoteDialog({NoteModel? existingNote}) {
    final titleCtrl = TextEditingController(text: existingNote?.title ?? '');
    final contentCtrl = TextEditingController(text: existingNote?.content ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          existingNote == null ? 'Create Subject Note' : 'Edit Note',
          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Note Title / Topic',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contentCtrl,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Important Points, Deadlines, or Questions...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleCtrl.text.trim().isEmpty && contentCtrl.text.trim().isEmpty) {
                Navigator.pop(context);
                return;
              }
              final user = ref.read(authControllerProvider).value;
              if (user != null) {
                final key = NotesQueryKey(userId: user.id, subjectCode: widget.subjectCode);
                ref.read(notesProvider(key).notifier).saveNote(
                      existingId: existingNote?.id,
                      title: titleCtrl.text.trim().isEmpty ? 'Untitled Note' : titleCtrl.text.trim(),
                      content: contentCtrl.text.trim(),
                    );
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
            ),
            child: const Text('Save Note'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value;
    if (user == null) return const SizedBox.shrink();

    final key = NotesQueryKey(userId: user.id, subjectCode: widget.subjectCode);
    final asyncNotes = ref.watch(notesProvider(key));

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(LucideIcons.fileText, color: AppColors.primary, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.subjectName,
                      style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Subject Notes & Study Material',
                      style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showNoteDialog(),
                icon: const Icon(LucideIcons.plus, size: 18),
                label: const Text('New Note'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Expanded(
            child: asyncNotes.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (notes) {
                if (notes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.folderPlus, size: 64, color: AppColors.border),
                        const SizedBox(height: 16),
                        Text(
                          'No study notes saved for ${widget.subjectName} yet.',
                          style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap New Note above to jot down important formulas, lab deadlines, or syllabus checklists.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: notes.length,
                  itemBuilder: (context, idx) {
                    final note = notes[idx];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  note.title,
                                  style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () => _showNoteDialog(existingNote: note),
                                    icon: const Icon(LucideIcons.edit2, size: 18, color: AppColors.primary),
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(4),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: () => ref.read(notesProvider(key).notifier).removeNote(note.id),
                                    icon: const Icon(LucideIcons.trash2, size: 18, color: AppColors.error),
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(4),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            note.content,
                            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Updated: ${_formatDate(note.updatedAt)}',
                            style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary.withValues(alpha: 0.7)),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
