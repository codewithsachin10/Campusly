import 'package:supabase/supabase.dart';

void main() async {
  final supabase = SupabaseClient(
    'https://jvrxoyswzjuhsofqnqym.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp2cnhveXN3emp1aHNvZnFucXltIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODU5MjU3NDMsImV4cCI6MjEwMTUwMTc0M30.ulsZel_C1qz2BvTxgSoZNiuDBPNC-a8UP42_aAYXvqc',
  );

  try {
    print('Signing up dummy user...');
    final authRes = await supabase.auth.signUp(
      email: 'testagent12345@example.com',
      password: 'Password123!',
    );
    print('User signed up: ${authRes.user?.id}');

    print('Fetching curriculum_subjects...');
    final data = await supabase.from('curriculum_subjects').select().limit(1);
    print('Data: $data');

    print('Fetching subject_details...');
    final subjectData = await supabase.from('subject_details').select().limit(1);
    print('Subject Data: $subjectData');

  } catch (e) {
    print('Error: $e');
  }
}
