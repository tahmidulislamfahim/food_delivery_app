import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/providers/favorites_provider.dart';
import 'package:food_delivery_app/screens/item_details_screen.dart';

class FavoritesTab extends ConsumerWidget {
  const FavoritesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favAsync = ref.watch(favoritesProvider);
    return favAsync.when(
      data: (favorites) {
        if (favorites.isEmpty) {
          return Center(
            child: Text(
              'No favorites yet',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(12),
          children: favorites.map((product) {
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
              title: Text(product.title),
              subtitle: Text(product.subtitle),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => ref
                    .read(favoritesProvider.notifier)
                    .toggleFavorite(product),
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ItemDetailsScreen(product: product),
                ),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }
}
