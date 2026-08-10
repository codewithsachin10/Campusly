import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  await Supabase.initialize(
    url: 'https://jvrxoyswzjuhsofqnqym.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp2cnhveXN3emp1aHNvZnFucXltIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODU5MjU3NDMsImV4cCI6MjEwMTUwMTc0M30.ulsZel_C1qz2BvTxgSoZNiuDBPNC-a8UP42_aAYXvqc',
  );
  
  final supabase = Supabase.instance.client;
  
  try {
    final memberships = await supabase
          .from('student_timetable_members')
          .select('*, custom_timetables(*)');
    print('Memberships: $memberships');
  } catch(e) {
    print('Error: $e');
  }
  
  exit(0);
}
