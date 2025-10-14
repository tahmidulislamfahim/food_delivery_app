import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/models/product.dart';
import 'package:food_delivery_app/providers/product_repository.dart';

final searchProvider = StateProvider<AsyncValue<List<Product>>>(
  (ref) => const AsyncValue.loading(),
);

final searchResultsProvider = FutureProvider.family<List<Product>, String>((
  ref,
  query,
) async {
  final repo = ref.read(productRepositoryProvider);
  return repo.search(query);
});
