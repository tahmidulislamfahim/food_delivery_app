import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/auth/login_screen.dart';
import 'package:food_delivery_app/providers/auth_provider.dart';
import 'package:food_delivery_app/providers/tabs_provider.dart';
import 'package:food_delivery_app/providers/supabase_provider.dart';
import 'package:food_delivery_app/tabs/home_tab.dart';
import 'package:food_delivery_app/tabs/favorites_tab.dart';
import 'package:food_delivery_app/tabs/search_tab.dart';
import 'package:food_delivery_app/tabs/cart_tab.dart';
import 'package:food_delivery_app/tabs/profile_tab.dart';

class TabsScreen extends ConsumerStatefulWidget {
  const TabsScreen({super.key});

  @override
  ConsumerState<TabsScreen> createState() => _TabsScreenState();
}

class _TabsScreenState extends ConsumerState<TabsScreen> {
  void _onItemTapped(int index) {
    // update provider so other widgets can also change active tab
    ref.read(selectedTabProvider.notifier).state = index;
  }

  Future<void> _logout(BuildContext context) async {
    try {
      final auth = ref.read(authControllerProvider);
      await auth.logout();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $error')));
    }
  }

  final List<Widget> _tabs = const [
    HomeTab(),
    FavoritesTab(),
    SearchTab(),
    ProfileTab(),
    CartTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(selectedTabProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFFDF5F3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Consumer(
          builder: (context, ref, _) {
            final userAsync = ref.watch(supabaseUserProvider);
            return userAsync.when(
              data: (user) {
                final metadata = user?.userMetadata;
                final address = metadata?['address'] as String?;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: Colors.black,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        address ?? '',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Text(
                'Loading...',
                style: TextStyle(color: Colors.black),
              ),
              error: (_, __) => const Text(
                'Error loading address',
                style: TextStyle(color: Colors.black),
              ),
            );
          },
        ),
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout, color: Colors.black),
          ),
        ],
      ),
      body: IndexedStack(index: selectedIndex, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.redAccent,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            label: 'Carts',
          ),
        ],
      ),
    );
  }
}
