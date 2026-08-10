import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/curriculum_repository.dart';
import '../../domain/models/curriculum_item.dart';

import '../../domain/models/curriculum_data.dart';

// Provider for the repository
final curriculumRepositoryProvider = Provider<CurriculumRepository>((ref) {
  return CurriculumRepository(Supabase.instance.client);
});

class SelectedSemesterNotifier extends Notifier<int> {
  @override
  int build() => 1; // Assuming default to semester 1, but we could make it dynamic based on current semester

  void setSemester(int semester) {
    state = semester;
  }
}

final selectedSemesterProvider = NotifierProvider<SelectedSemesterNotifier, int>(() {
  return SelectedSemesterNotifier();
});

// Future provider that fetches curriculum data based on the selected semester
final curriculumProvider = FutureProvider<CurriculumData?>((ref) async {
  final semester = ref.watch(selectedSemesterProvider);
  final repository = ref.watch(curriculumRepositoryProvider);
  return repository.getCurriculumBySemester(semester);
});
