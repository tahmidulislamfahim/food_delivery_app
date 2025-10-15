import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final isAdminProvider = FutureProvider<bool>((ref) async {
  final client = Supabase.instance.client;
  try {
    final result = await client.rpc('is_current_user_admin');

    // result is expected to be either true, false, or 't'/'f' as a string
    if (result is bool) return result;
    if (result is String) return result == 't' || result == 'true';
    return false;
  } catch (e) {
    // Error checking admin: $e
    return false;
  }
});
