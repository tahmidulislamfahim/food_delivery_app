import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:food_delivery_app/app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://vrhuymgpxpcsctugdiyp.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZyaHV5bWdweHBjc2N0dWdkaXlwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI1Nzg1MTcsImV4cCI6MjA3ODE1NDUxN30.ec_ysofqe5oZaXlNuKHM-Cmh6lgyqqdSM3JiFJDkkNY',
  );
  runApp(const ProviderScope(child: App()));
}
