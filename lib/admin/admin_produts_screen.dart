import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/auth/login_screen.dart';
import 'package:food_delivery_app/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'product_form.dart';

class AdminProductsScreen extends ConsumerStatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  ConsumerState<AdminProductsScreen> createState() =>
      _AdminProductsScreenState();
}

class _AdminProductsScreenState extends ConsumerState<AdminProductsScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final client = Supabase.instance.client;

    try {
      final res = await client.from('products').select('*');
      final data = res as List<dynamic>;
      setState(() {
        _items = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _loading = false;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Load failed: $error')));
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    // Ask the admin for confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete product'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final client = Supabase.instance.client;

    try {
      // Call the RPC; it now safely deletes the product and all related rows
      await client.rpc('delete_product', params: {'p_id': item['id']});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted successfully')),
        );
        await _load(); // Refresh the product list
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Delete failed: $error')));
      }
    }
  }

  Future<void> _openForm([Map<String, dynamic>? initial]) async {
    final res = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ProductForm(initial: initial)));
    if (res == true) await _load();
  }

  Future<void> _logout() async {
    try {
      final auth = ref.read(authControllerProvider);
      await auth.logout();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Logout failed: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.redAccent,
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),

      // ✅ Floating add button
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.redAccent,
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Product', style: TextStyle(color: Colors.white)),
      ),

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? const Center(
              child: Text(
                'No products found',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _items.length,
                itemBuilder: (context, i) {
                  final p = _items[i];
                  final imageUrl = p['image_url'] as String?;
                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: (imageUrl != null && imageUrl.isNotEmpty)
                            ? Image.network(
                                imageUrl,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 64,
                                height: 64,
                                color: Colors.grey.shade200,
                                child: const Icon(
                                  Icons.image_outlined,
                                  color: Colors.grey,
                                ),
                              ),
                      ),
                      title: Text(
                        p['title'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        '\$${(p['price'] ?? 0).toString()}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: PopupMenuButton(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 18),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text('Delete'),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (v) {
                          if (v == 'edit') _openForm(p);
                          if (v == 'delete') _delete(p);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
