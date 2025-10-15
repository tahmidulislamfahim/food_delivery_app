import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/providers/supabase_provider.dart';
import 'package:food_delivery_app/providers/admin_provider.dart';
import 'package:food_delivery_app/admin/admin_produts_screen.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(supabaseUserProvider);
    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const Center(
            child: Text('Not logged in', style: TextStyle(fontSize: 16)),
          );
        }

        final metadata = user.userMetadata ?? {};
        final name = metadata['name'] ?? '';
        final address = metadata['address'] ?? '';
        final phone = metadata['phone'] ?? '';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // 🔸 Profile Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.orange.shade200,
                      child: Text(
                        (name.isNotEmpty ? name[0] : user.email?[0] ?? '?')
                            .toUpperCase(),
                        style: const TextStyle(
                          fontSize: 28,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Name & Email
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.isNotEmpty ? name : 'User',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 🔸 Information Section
              _buildInfoTile(Icons.person, 'Name', name),
              const SizedBox(height: 8),
              _buildInfoTile(Icons.phone, 'Phone', phone),
              const SizedBox(height: 8),
              _buildInfoTile(Icons.home, 'Address', address),
              const SizedBox(height: 8),
              _buildInfoTile(Icons.email, 'Email', user.email ?? ''),

              const SizedBox(height: 32),

              // 🔸 Admin Button (only if admin)
              Consumer(
                builder: (context, ref, _) {
                  final adminAsync = ref.watch(isAdminProvider);
                  return adminAsync.when(
                    data: (isAdmin) {
                      if (!isAdmin) return const SizedBox();
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AdminProductsScreen(),
                            ),
                          ),
                          icon: const Icon(Icons.admin_panel_settings),
                          label: const Text(
                            'Admin Panel',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    },
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                  );
                },
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.orange.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value.isNotEmpty ? value : 'Not set',
            style: TextStyle(
              color: value.isNotEmpty ? Colors.black87 : Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
