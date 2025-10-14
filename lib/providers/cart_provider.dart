import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CartState {
  final String? cartId;
  final List<CartItemView> items;
  final double total;

  CartState({this.cartId, required this.items, required this.total});

  factory CartState.empty() => CartState(cartId: null, items: [], total: 0);
}

class CartItemView {
  final String productId;
  final String title;
  final int quantity;
  final double unitPrice;

  CartItemView({
    required this.productId,
    required this.title,
    required this.quantity,
    required this.unitPrice,
  });
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(CartState.empty()) {
    refresh();
  }

  Future<void> refresh() async {
    final client = Supabase.instance.client;
    final res = await client.rpc('get_active_cart');
    final dyn = res as dynamic;
    if (dyn.error != null) throw dyn.error;
    final data = dyn.data as dynamic;
    if (data == null) {
      state = CartState.empty();
      return;
    }
    final cartId = data['cart_id']?.toString();
    final itemsRaw = data['items'] as List<dynamic>? ?? [];
    final items = itemsRaw
        .map(
          (i) => CartItemView(
            productId: i['product_id'].toString(),
            title: i['title'] ?? '',
            quantity: (i['quantity'] as num).toInt(),
            unitPrice: (i['unit_price'] as num).toDouble(),
          ),
        )
        .toList();
    final total = (data['total'] is num)
        ? (data['total'] as num).toDouble()
        : double.parse(data['total'].toString());
    state = CartState(cartId: cartId, items: items, total: total);
  }

  Future<void> add(String productId, int quantity) async {
    final client = Supabase.instance.client;
    final res = await client.rpc(
      'add_item_to_cart',
      params: {'p_product_id': productId, 'p_quantity': quantity},
    );
    final dyn = res as dynamic;
    if (dyn.error != null) throw dyn.error;
    await refresh();
  }

  Future<void> setQuantity(String productId, int quantity) async {
    final client = Supabase.instance.client;
    final res = await client.rpc(
      'set_cart_item_quantity',
      params: {'p_product_id': productId, 'p_quantity': quantity},
    );
    final dyn = res as dynamic;
    if (dyn.error != null) throw dyn.error;
    await refresh();
  }

  Future<void> remove(String productId) async {
    final client = Supabase.instance.client;
    final res = await client.rpc(
      'remove_item_from_cart',
      params: {'p_product_id': productId},
    );
    final dyn = res as dynamic;
    if (dyn.error != null) throw dyn.error;
    await refresh();
  }

  Future<String> placeOrder() async {
    final client = Supabase.instance.client;
    final res = await client.rpc('place_order_from_cart');
    final dyn = res as dynamic;
    if (dyn.error != null) throw dyn.error;
    final orderId = dyn.data as String;
    await refresh();
    return orderId;
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});
