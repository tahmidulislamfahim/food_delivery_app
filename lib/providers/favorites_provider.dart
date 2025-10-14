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
      final favRes = await client.from('favorites').select('product_id').match({
        'user_id': userId,
      });
      final dyn = favRes as dynamic;
      if (dyn.error != null) throw dyn.error;
      final fdata = dyn.data as List<dynamic>;
      final ids = fdata.map((e) => e['product_id'].toString()).toList();
      if (ids.isEmpty) {
        state = const AsyncValue.data([]);
        return;
      }
      final products = <Product>[];
      for (final id in ids) {
        final pRes = await client
            .from('products')
            .select()
            .match({'id': id})
            .limit(1);
        final pDyn = pRes as dynamic;
        if (pDyn.error != null) continue;
        final pdata = pDyn.data as List<dynamic>?;
        if (pdata == null || pdata.isEmpty) continue;
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
      final check = await client.from('favorites').select().match({
        'user_id': userId,
        'product_id': product.id,
      });
      final cDyn = check as dynamic;
      if (cDyn.error != null) throw cDyn.error;
      final items = cDyn.data as List<dynamic>;
      if (items.isNotEmpty) {
        // remove
        final del = await client.from('favorites').delete().match({
          'user_id': userId,
          'product_id': product.id,
        });
        final dDyn = del as dynamic;
        if (dDyn.error != null) throw dDyn.error;
      } else {
        // insert
        final ins = await client.from('favorites').insert({
          'user_id': userId,
          'product_id': product.id,
        });
        final iDyn = ins as dynamic;
        if (iDyn.error != null) throw iDyn.error;
      }
      await _load();
    } catch (e) {
      rethrow;
    }
  }
}
