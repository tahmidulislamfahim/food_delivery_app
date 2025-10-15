import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final categoriesProvider = FutureProvider<List<String>>((ref) async {
  final client = Supabase.instance.client;
  final data =
      await client.from('products').select('category') as List<dynamic>;
  final cats = data
      .map((e) => (e as Map<String, dynamic>)['category'] as String?)
      .where((c) => c != null && c.trim().isNotEmpty)
      .map((c) => c!.trim())
      .toSet()
      .toList();
  cats.sort();
  return cats;
});
