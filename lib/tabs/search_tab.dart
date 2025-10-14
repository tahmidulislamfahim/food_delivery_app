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
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Search for meals, drinks...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (v) async {
              // set loading state
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
        Expanded(
          child: state.when(
            data: (list) {
              if (list.isEmpty) {
                return const Center(child: Text('No results'));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final p = list[index];
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
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }
}
