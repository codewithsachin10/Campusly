import 'dart:convert';
import 'dart:io';

void main() async {
  final url = Uri.parse('https://jvrxoyswzjuhsofqnqym.supabase.co/rest/v1/?apikey=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp2cnhveXN3emp1aHNvZnFucXltIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODU5MjU3NDMsImV4cCI6MjEwMTUwMTc0M30.ulsZel_C1qz2BvTxgSoZNiuDBPNC-a8UP42_aAYXvqc');
  final request = await HttpClient().getUrl(url);
  
  try {
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    if (response.statusCode == 200) {
      final json = jsonDecode(responseBody);
      final defs = json['definitions'] ?? {};
      if (defs.containsKey('subjects')) {
         print('SUBJECTS SCHEMA:');
         print(jsonEncode(defs['subjects']));
      } else {
         print('Subjects not in definitions. Available definitions: ${defs.keys.toList()}');
      }
      if (defs.containsKey('curriculum')) {
         print('CURRICULUM SCHEMA:');
         print(jsonEncode(defs['curriculum']));
      }
      // Check for anything semester related
      final tablesWithSemester = defs.keys.where((k) {
         final props = defs[k]?['properties'] ?? {};
         return props.containsKey('semester') || props.containsKey('sem');
      }).toList();
      print('TABLES WITH SEMESTER: $tablesWithSemester');
    } else {
      print('Failed: ${response.statusCode} - $responseBody');
    }
  } catch (e) {
    print('Error: $e');
  }
}
