import 'package:supabase/supabase.dart';
import 'package:campusly/core/config/supabase_config.dart';

void main() async {
  final supabase = SupabaseClient(
    SupabaseConfig.url,
    SupabaseConfig.anonKey,
  );

  final res = await supabase.rpc('reload_schema_cache');
  print('RPC result: $res');
}
