import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/providers/search_provider.dart';
import 'package:food_delivery_app/screens/item_details_screen.dart';

class SearchTab extends ConsumerStatefulWidget {
  const SearchTab({super.key});

  @override
  ConsumerState<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends ConsumerState<SearchTab> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchProvider);

    return Column(
      children: [
        // 🔸 Search Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.white,
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Search for meals, drinks...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (v) async {
              ref.read(searchProvider.notifier).state =
                  const AsyncValue.loading();
              try {
                final results = await ref.read(searchResultsProvider(v).future);
                ref.read(searchProvider.notifier).state = AsyncValue.data(
                  results,
                );
              } catch (e, st) {
                ref.read(searchProvider.notifier).state = AsyncValue.error(
                  e,
                  st,
                );
              }
            },
          ),
        ),

        // 🔸 Results
        Expanded(
          child: state.when(
            data: (list) {
              if (list.isEmpty) {
                return _buildEmptyState();
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final p = list[index];
                  return GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ItemDetailsScreen(product: p),
                      ),
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // 🖼 Image
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(14),
                              bottomLeft: Radius.circular(14),
                            ),
                            child: p.imageUrl != null
                                ? Image.network(
                                    p.imageUrl!,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              width: 100,
                                              height: 100,
                                              color: Colors.grey.shade200,
                                              child: const Icon(
                                                Icons.broken_image,
                                                color: Colors.grey,
                                              ),
                                            ),
                                  )
                                : Container(
                                    width: 100,
                                    height: 100,
                                    color: Colors.grey.shade200,
                                    child: const Icon(
                                      Icons.fastfood,
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                                  ),
                          ),

                          // 📄 Info
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    p.subtitle,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '\$${p.price.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_rounded, size: 70, color: Colors.orange.shade300),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching for another meal, drink, or snack.',
              style: TextStyle(color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
