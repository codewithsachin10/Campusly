import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('Fetch subjects schema', () async {
    final supabase = SupabaseClient(
      'https://jvrxoyswzjuhsofqnqym.supabase.co',
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp2cnhveXN3emp1aHNvZnFucXltIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODU5MjU3NDMsImV4cCI6MjEwMTUwMTc0M30.ulsZel_C1qz2BvTxgSoZNiuDBPNC-a8UP42_aAYXvqc',
    );

    try {
      final res = await supabase.from('subjects').select().limit(1);
      if (res.isNotEmpty) {
        print('SUBJECTS COLUMNS: ${res.first.keys.toList()}');
      } else {
        print('SUBJECTS TABLE IS EMPTY OR DOES NOT EXIST');
      }
    } catch (e) {
      print('ERROR: $e');
    }
  });
}
