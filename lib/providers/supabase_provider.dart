import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseUserProvider = FutureProvider<User?>((ref) async {
  final client = Supabase.instance.client;
  try {
    final session = client.auth.currentSession;
    if (session == null) return null;
    // currentUser is available on the client
    final user = client.auth.currentUser;
    return user;
  } catch (e) {
    return null;
  }
});
