import 'package:supabase/supabase.dart';
import 'package:campusly/core/config/supabase_config.dart';

void main() async {
  final supabase = SupabaseClient(
    SupabaseConfig.url,
    SupabaseConfig.serviceRoleKey ?? SupabaseConfig.anonKey, // Try using service key if we have it, else anon might fail RLS
  );

  print('Inserting mock release...');
  try {
    final releaseRes = await supabase.from('app_releases').insert({
      'id': 'd69e4695-15db-44a3-a0ed-b3626359ce9a',
      'version': '2.0.0',
      'build_number': 20,
      'title': 'Campusly 2.0.0: The Big Rewrite',
      'description': 'We rewrote the app to be faster, lighter, and better!',
      'priority': 'RECOMMENDED',
      'channel': 'STABLE',
      'minimum_supported_version': '1.0.0',
      'status': 'PUBLISHED',
      'is_published': true,
      'published_at': DateTime.now().toIso8601String(),
      'download_url': 'https://github.com/campusly/releases/download/v2.0.0/app-release.apk',
      'file_size_bytes': 25000000
    }).select('id');
    
    print('Release inserted: $releaseRes');
    
    final releaseId = releaseRes[0]['id'];
    
    final noteRes = await supabase.from('release_notes').insert([
      {
        'release_id': releaseId,
        'category': 'NEW',
        'title': 'Dark Mode Support',
        'description': 'Enjoy campusly in the dark!',
        'sort_order': 1
      },
      {
        'release_id': releaseId,
        'category': 'IMPROVED',
        'title': 'Faster Load Times',
        'description': 'We optimized the startup sequence.',
        'sort_order': 2
      }
    ]).select();
    
    print('Notes inserted: $noteRes');
  } catch (e) {
    print('Error: $e');
  }
}
