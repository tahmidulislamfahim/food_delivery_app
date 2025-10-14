import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:food_delivery_app/models/product.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(Supabase.instance.client);
});

class ProductRepository {
  final SupabaseClient _client;

  ProductRepository(this._client);

  Future<List<Product>> all({String? category}) async {
    final res = await _client.rpc(
      'get_products',
      params: {'p_category': category},
    );
    final dyn = res as dynamic;
    if (dyn.error != null) throw dyn.error;
    final data = dyn.data as List<dynamic>;
    return data.map((e) => _mapToProduct(e)).toList();
  }

  Future<Product?> getById(String id) async {
    final res = await _client
        .from('products')
        .select()
        .match({'id': id})
        .limit(1);
    final dyn = res as dynamic;
    if (dyn.error != null) throw dyn.error;
    final data = dyn.data as List<dynamic>?;
    if (data == null || data.isEmpty) return null;
    return _mapToProduct(data.first);
  }

  Future<List<Product>> search(String q) async {
    final trimmed = q.trim();
    if (trimmed.isEmpty) return all();
    final res = await _client.rpc('search_products', params: {'p_q': trimmed});
    final dyn = res as dynamic;
    if (dyn.error != null) throw dyn.error;
    final data = dyn.data as List<dynamic>;
    return data.map((e) => _mapToProduct(e)).toList();
  }

  Product _mapToProduct(dynamic e) {
    return Product(
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
    );
  }
}

// FutureProvider family to fetch products (optionally by category)
final productsListProvider = FutureProvider.family<List<Product>, String?>((
  ref,
  category,
) async {
  final repo = ref.read(productRepositoryProvider);
  return repo.all(category: category);
});
