import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/screens/item_details_screen.dart';
import 'package:food_delivery_app/providers/product_repository.dart';
import 'package:food_delivery_app/providers/categories_provider.dart';
import 'package:food_delivery_app/screens/products_list_screen.dart';
import 'package:food_delivery_app/providers/tabs_provider.dart';

class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔸 Promo Banner (gradient background)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.redAccent, Colors.orange.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.redAccent.withValues(alpha: 50),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'The Fastest In\nDelivery Food',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          ref.read(selectedTabProvider.notifier).state = 4;
                        },
                        child: const Text(
                          'Order Now',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Placeholder image
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Image.asset(
                    'assets/images/homepage_order_now.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 🔸 Category Selector
          Consumer(
            builder: (context, ref, _) {
              final catsAsync = ref.watch(categoriesProvider);
              return catsAsync.when(
                data: (cats) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    // allow shadows to paint outside the scroll viewport
                    clipBehavior: Clip.none,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        _buildCategoryItem(
                          'All',
                          _selectedCategory == null,
                          () => setState(() => _selectedCategory = null),
                        ),
                        const SizedBox(width: 8),
                        for (final c in cats) ...[
                          _buildCategoryItem(
                            c,
                            _selectedCategory == c,
                            () => setState(() => _selectedCategory = c),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (e, st) =>
                    Center(child: Text('Error loading categories: $e')),
              );
            },
          ),

          const SizedBox(height: 24),

          // 🔸 Popular Now header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Popular Now 🍔',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          ProductsListScreen(category: _selectedCategory),
                    ),
                  );
                },
                child: Text(
                  'View All →',
                  style: TextStyle(
                    color: Colors.redAccent.shade200,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 🔸 Products Grid
          Consumer(
            builder: (context, ref, _) {
              final productsAsync = ref.watch(
                productsListProvider(_selectedCategory),
              );
              return productsAsync.when(
                data: (products) {
                  if (products.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(
                        child: Text(
                          'No items in this category',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  }
                  return GridView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.72,
                        ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ItemDetailsScreen(product: product),
                          ),
                        ),
                        child: _buildPopularItem(
                          title: product.title,
                          subtitle: product.subtitle,
                          price: product.price,
                          imageUrl: product.imageUrl ?? '',
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Error: $e')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(
    String label,
    bool selected,
    void Function()? onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.redAccent : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? Colors.redAccent : Colors.grey.shade300,
            width: selected ? 0 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? Colors.redAccent.withValues(alpha: 0.18)
                  : Colors.black.withValues(alpha: 0.06),
              blurRadius: selected ? 10 : 8,
              spreadRadius: selected ? 0 : 0,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildPopularItem({
    required String title,
    required String subtitle,
    required double price,
    required String imageUrl,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 50),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: Image.network(
              imageUrl,
              height: 130,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 130,
                color: Colors.grey.shade200,
                child: const Icon(Icons.broken_image, size: 40),
              ),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 130,
                  color: Colors.grey.shade200,
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  '\$${price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
