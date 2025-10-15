import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// StreamProvider that emits the current authenticated user and updates when it changes.
final supabaseUserProvider = StreamProvider<User?>((ref) {
  final client = Supabase.instance.client;

  // Emit current user immediately and then poll every 1s for changes.
  final controller = StreamController<User?>();

  void emitUser() => controller.add(client.auth.currentUser);

  // Emit initial value
  emitUser();

  final timer = Timer.periodic(const Duration(seconds: 1), (_) => emitUser());

  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream.distinct((a, b) => a?.id == b?.id);
});
