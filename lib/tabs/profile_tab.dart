import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/providers/supabase_provider.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(supabaseUserProvider);
    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const Center(child: Text('Not logged in'));
        }

        final metadata = user.userMetadata ?? {};
        final name = metadata['name'] ?? '';
        final address = metadata['address'] ?? '';
        final phone = metadata['phone'] ?? '';

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Email: ${user.email ?? ''}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text('Name: $name', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Text('Phone: $phone', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Text('Address: $address', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }
}
