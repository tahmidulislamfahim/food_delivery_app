import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:food_delivery_app/models/product.dart';

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, AsyncValue<List<Product>>>((ref) {
      return FavoritesNotifier();
    });

class FavoritesNotifier extends StateNotifier<AsyncValue<List<Product>>> {
  FavoritesNotifier() : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final client = Supabase.instance.client;
      // Fetch favorites for current user
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        state = const AsyncValue.data([]);
        return;
      }
      final fdata = await client
          .from('favorites')
          .select('product_id')
          .match({'user_id': userId}) as List<dynamic>;
      final ids = fdata.map((e) => e['product_id'].toString()).toList();
      if (ids.isEmpty) {
        state = const AsyncValue.data([]);
        return;
      }
      final products = <Product>[];
      for (final id in ids) {
        final pdata = await client
                .from('products')
                .select()
                .match({'id': id})
                .limit(1) as List<dynamic>;
        if (pdata.isEmpty) continue;
        final e = pdata.first;
        products.add(
          Product(
            id: e['id'] as String,
            title: e['title'] as String? ?? '',
            subtitle: e['subtitle'] as String? ?? '',
            price: (e['price'] is num)
                ? (e['price'] as num).toDouble()
                : double.parse(e['price'].toString()),
            imageUrl: e['image_url'] as String?,
            calories: e['calories'] != null ? (e['calories'] as int) : null,
            cookTimeMinutes: e['cook_time_minutes'] != null
                ? (e['cook_time_minutes'] as int)
                : null,
            category: e['category'] as String?,
          ),
        );
      }
      state = AsyncValue.data(products);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleFavorite(Product product) async {
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      // check existing
      final items = await client
              .from('favorites')
              .select()
              .match({'user_id': userId, 'product_id': product.id})
          as List<dynamic>;
      if (items.isNotEmpty) {
        // remove
        await client
            .from('favorites')
            .delete()
            .match({'user_id': userId, 'product_id': product.id});
      } else {
        // insert
        await client.from('favorites').insert({
          'user_id': userId,
          'product_id': product.id,
        });
      }
      await _load();
    } catch (e) {
      rethrow;
    }
  }
}
