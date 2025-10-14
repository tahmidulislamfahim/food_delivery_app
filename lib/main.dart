import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:food_delivery_app/app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://bdhbiwxtfbvaeqgbbwot.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJkaGJpd3h0ZmJ2YWVxZ2Jid290Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAyNTcxMzUsImV4cCI6MjA3NTgzMzEzNX0.YGtZTKKqPVdQQkxyjdfJth2VCKvDR8kjG92yyDPSxjE',
  );
  runApp(const ProviderScope(child: App()));
}
