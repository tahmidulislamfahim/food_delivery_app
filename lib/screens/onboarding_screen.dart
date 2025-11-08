import 'dart:async';

import 'package:flutter/material.dart';
import 'package:food_delivery_app/auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _pageIndex = 0;
  // index used for the bottom card (title/body/dots) animation
  int _displayIndex = 0;
  Timer? _autoPlayTimer;
  static const Duration _autoPlayDelay = Duration(seconds: 4);

  final List<Map<String, String>> _pages = [
    {
      'image': 'assets/images/onboarding_top.png',
      'title': 'The Fastest In Delivery Food',
      'body':
          'Our job is to filling your tummy with delicious food and fast delivery.',
    },
    {
      'image': 'assets/images/onboarding_top.png',
      'title': 'Fresh & Tasty',
      'body':
          'Quality ingredients, expertly prepared meals delivered to your door.',
    },
    {
      'image': 'assets/images/onboarding_top.png',
      'title': 'Live Tracking',
      'body':
          'Follow your order from the kitchen to your doorstep in real-time.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  @override
  void dispose() {
    _stopAutoPlay();
    _controller.dispose();
    super.dispose();
  }

  void _goNext() {
    final int currentMax = _pageIndex > _displayIndex
        ? _pageIndex
        : _displayIndex;
    final int next = (currentMax < _pages.length - 1)
        ? currentMax + 1
        : _pages.length - 1;
    if (next < _pages.length) {
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.ease,
      );
      setState(() {
        _pageIndex = next;
        _displayIndex = next;
      });
      _resetAutoPlay();
    } else {
      _finish();
    }
  }

  void _finish() {
    _stopAutoPlay();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // PageView with images/content
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) {
                  // user swiped the image; sync the bottom card and reset autoplay
                  setState(() {
                    _pageIndex = i;
                    _displayIndex = i;
                  });
                  _resetAutoPlay();
                },
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Column(
                    children: [
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          color: Colors.white,
                          child: Image.asset(page['image']!, fit: BoxFit.cover),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Bottom card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 22),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                gradient: LinearGradient(
                  colors: [Color(0xFFFF5A00), Color(0xFFE60000)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title (animated)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 450),
                    transitionBuilder: (child, anim) =>
                        FadeTransition(opacity: anim, child: child),
                    child: Text(
                      _pages[_displayIndex]['title']!,
                      key: ValueKey('title-$_displayIndex'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Body (animated) — fixed height for two lines so container doesn't resize
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 450),
                    transitionBuilder: (child, anim) => SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.12),
                        end: Offset.zero,
                      ).animate(anim),
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: SizedBox(
                      key: ValueKey('body-box-$_displayIndex'),
                      height: 44,
                      child: Center(
                        child: Text(
                          _pages[_displayIndex]['body']!,
                          key: ValueKey('body-$_displayIndex'),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Dots and actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Skip
                      TextButton(
                        onPressed: _finish,
                        child: const Text(
                          'Skip',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),

                      // Dots (reflect display index)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _pages.length,
                          (i) => _dot(i == _displayIndex),
                        ),
                      ),

                      // Next / Get Started
                      TextButton(
                        onPressed: () {
                          if (_displayIndex == _pages.length - 1) {
                            _finish();
                          } else {
                            _goNext();
                          }
                        },
                        child: Text(
                          _displayIndex == _pages.length - 1
                              ? 'Get Started'
                              : 'Next',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startAutoPlay() {
    _stopAutoPlay();
    _autoPlayTimer = Timer.periodic(_autoPlayDelay, (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_displayIndex < _pages.length - 1) {
        setState(() => _displayIndex++);
      } else {
        // stop autoplay on the last page so user can interact with Get Started
        t.cancel();
      }
    });
  }

  void _stopAutoPlay() {
    if (_autoPlayTimer != null) {
      _autoPlayTimer!.cancel();
      _autoPlayTimer = null;
    }
  }

  void _resetAutoPlay() {
    // restart the timer whenever the user interacts (swipe or manual nav)
    _startAutoPlay();
  }

  Widget _dot(bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 12 : 8,
      height: active ? 12 : 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? Colors.white : Colors.white30,
      ),
    );
  }
}
