import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/providers/product_repository.dart';
import 'package:food_delivery_app/screens/item_details_screen.dart';

class ProductsListScreen extends ConsumerWidget {
  final String? category;

  const ProductsListScreen({super.key, this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsListProvider(category));

    return productsAsync.when(
      data: (filtered) {
        return Scaffold(
          appBar: AppBar(
            title: Text(category == null ? 'All Products' : 'All ${category!}'),
          ),
          body: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final p = filtered[index];
              return ListTile(
                leading: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.image, color: Colors.grey),
                ),
                title: Text(p.title),
                subtitle: Text(p.subtitle),
                trailing: Text(
                  '\$${p.price.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.redAccent),
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ItemDetailsScreen(product: p),
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}
