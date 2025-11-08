import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/models/product.dart';
import 'package:food_delivery_app/providers/cart_provider.dart';
import 'package:food_delivery_app/providers/favorites_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ItemDetailsScreen extends ConsumerStatefulWidget {
  final Product product;

  const ItemDetailsScreen({super.key, required this.product});

  @override
  ConsumerState<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends ConsumerState<ItemDetailsScreen> {
  int _quantity = 1;
  bool _isAdding = false;

  void _increment() => setState(() => _quantity++);
  void _decrement() => setState(() {
    if (_quantity > 1) _quantity--;
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final favAsync = ref.watch(favoritesProvider);
              final isFav = favAsync.when(
                data: (list) => list.any((p) => p.id == widget.product.id),
                loading: () => false,
                error: (_, __) => false,
              );
              return IconButton(
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? Colors.redAccent : Colors.black,
                ),
                onPressed: () async {
                  await ref
                      .read(favoritesProvider.notifier)
                      .toggleFavorite(widget.product);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isFav ? 'Removed from favorites' : 'Added to favorites',
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Product image area
          Container(
            height: 260,
            color: Colors.grey.shade200,
            child: widget.product.imageUrl != null
                ? Image.network(
                    widget.product.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(
                        Icons.broken_image,
                        size: 80,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : const Center(
                    child: Icon(Icons.image, size: 80, color: Colors.grey),
                  ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _decrement,
                  icon: const Icon(Icons.remove_circle_outline),
                  color: Colors.redAccent,
                  iconSize: 32,
                ),
                const SizedBox(width: 12),
                Text(
                  '$_quantity',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _increment,
                  icon: const Icon(Icons.add_circle_outline),
                  color: Colors.redAccent,
                  iconSize: 32,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Product title & price
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '\$${(widget.product.price * _quantity).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Extra details (calories, time)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                _buildInfoChip(
                  Icons.local_fire_department,
                  '${widget.product.calories != null ? widget.product.calories.toString() : '-'} cal',
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  Icons.timer,
                  widget.product.cookTimeMinutes != null
                      ? '${widget.product.cookTimeMinutes} min'
                      : '-',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Details section
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Details',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.subtitle,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Quality',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(
                      5,
                      (i) =>
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          // Add to cart
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isAdding
                  ? null
                  : () async {
                      setState(() => _isAdding = true);
                      try {
                        // ensure user is authenticated before calling RPC
                        final user = Supabase.instance.client.auth.currentUser;
                        if (user == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please log in to add items to cart',
                              ),
                            ),
                          );
                          return;
                        }

                        // add to cart via Supabase-backed provider (pass product id)
                        await ref
                            .read(cartProvider.notifier)
                            .add(widget.product.id, _quantity);

                        final totalItems = ref
                            .read(cartProvider)
                            .items
                            .fold<int>(0, (s, i) => s + i.quantity);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added to cart ($totalItems items)'),
                          ),
                        );
                      } catch (e, st) {
                        // Show a friendly error and log to console
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to add to cart: $e'),
                            ),
                          );
                        }
                        // ignore: avoid_print
                        print('add to cart error: $e\n$st');
                      } finally {
                        if (mounted) setState(() => _isAdding = false);
                      }
                    },
              child: Text(
                'Add to cart - \$${(widget.product.price * _quantity).toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.redAccent),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
        ],
      ),
    );
  }
}
