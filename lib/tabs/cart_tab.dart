import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/providers/cart_provider.dart';

class CartTab extends ConsumerStatefulWidget {
  const CartTab({super.key});

  @override
  ConsumerState<CartTab> createState() => _CartTabState();
}

class _CartTabState extends ConsumerState<CartTab> {
  bool _processing = false;

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);

    if (cart.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              'Your cart is empty',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: cart.items.length,
            itemBuilder: (context, index) {
              final cartItem = cart.items[index];

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Image placeholder (can replace with real product image)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 70,
                          height: 70,
                          color: const Color.fromARGB(255, 255, 255, 255),
                          child: const Icon(
                            Icons.fastfood,
                            color: Colors.grey,
                            size: 30,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Title + Price
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cartItem.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '\$${(cartItem.unitPrice * cartItem.quantity).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Delete controls
                      Row(
                        children: [
                          IconButton(
                            onPressed: cartItem.quantity > 1
                                ? () => ref
                                      .read(cartProvider.notifier)
                                      .setQuantity(
                                        cartItem.productId,
                                        cartItem.quantity - 1,
                                      )
                                : null,
                            icon: const Icon(Icons.remove_circle_outline),
                            color: Colors.redAccent,
                          ),
                          Text(
                            '${cartItem.quantity}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          IconButton(
                            onPressed: () => ref
                                .read(cartProvider.notifier)
                                .setQuantity(
                                  cartItem.productId,
                                  cartItem.quantity + 1,
                                ),
                            icon: const Icon(Icons.add_circle_outline),
                            color: Colors.redAccent,
                          ),
                          IconButton(
                            onPressed: () => ref
                                .read(cartProvider.notifier)
                                .remove(cartItem.productId),
                            icon: const Icon(Icons.delete_outline),
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // 🧾 Bottom checkout summary
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 50),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Total section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${cart.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              // Checkout button
              SizedBox(
                width: 150,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _processing
                      ? null
                      : () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: const Text('Confirm payment'),
                              content: const Text('Pay via Cash on Delivery?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(c).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(c).pop(true),
                                  child: const Text('Accept'),
                                ),
                              ],
                            ),
                          );

                          if (ok != true) return;

                          setState(() => _processing = true);
                          try {
                            final orderId = await ref
                                .read(cartProvider.notifier)
                                .placeOrder();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Order placed (ID: $orderId)'),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Checkout failed: $e')),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _processing = false);
                          }
                        },
                  child: _processing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Checkout',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
