import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/auth/login_screen.dart';
import 'package:food_delivery_app/providers/auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  String _name = '';
  String _email = '';
  String _phone = '';
  String _address = '';
  String _password = '';

  bool isLoading = false;

  Future<void> _signUp() async {
    // Validate the form first
    if (!_formKey.currentState!.validate()) return;

    // Save the values from form fields
    _formKey.currentState!.save();

    setState(() {
      isLoading = true;
    });

    try {
      final auth = ref.read(authControllerProvider);
      // Add a timeout so the UI doesn't hang indefinitely if the network/backend
      // doesn't respond. 15s is a reasonable default; adjust as needed.
      await auth
          .signUp(_email, _password, _name, _address, _phone)
          .timeout(const Duration(seconds: 15));

      // Debug log for developers
      // ignore: avoid_print
      print('Signup succeeded for $_email');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign up successful! Please verify your email.'),
        ),
      );

      // Navigate to login
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (error) {
      // Distinguish timeout errors to provide clearer feedback
      if (error is TimeoutException) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request timed out. Please try again.')),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $error')));
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 163, 163, 165),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  margin: const EdgeInsets.only(
                    top: 30,
                    bottom: 20,
                    right: 20,
                    left: 20,
                  ),
                  width: 150,
                  child: Image.asset('assets/images/food_delivery.png'),
                ),
                Card(
                  margin: const EdgeInsets.all(16.0),
                  elevation: 8.0,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextFormField(
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                labelText: 'Name',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your Name';
                                }
                                return null;
                              },
                              onSaved: (value) => _name = value!.trim(),
                            ),
                            const SizedBox(height: 16.0),
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your email';
                                }
                                final emailRegex = RegExp(
                                  r'^[^@]+@[^@]+\.[^@]+$',
                                );
                                if (!emailRegex.hasMatch(value.trim())) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                              onSaved: (value) => _email = value!.trim(),
                            ),
                            const SizedBox(height: 16.0),
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Phone Number',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your phone number';
                                }
                                return null;
                              },
                              onSaved: (value) => _phone = value!.trim(),
                            ),
                            const SizedBox(height: 16.0),
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Address',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your address';
                                }
                                return null;
                              },
                              onSaved: (value) => _address = value!.trim(),
                            ),
                            const SizedBox(height: 16.0),
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Password',
                                border: OutlineInputBorder(),
                              ),
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters long';
                                }
                                return null;
                              },
                              onSaved: (value) => _password = value!.trim(),
                            ),
                            const SizedBox(height: 24.0),
                            if (isLoading)
                              const CircularProgressIndicator()
                            else
                              ElevatedButton(
                                onPressed: _signUp,
                                child: const Text('Sign Up'),
                              ),
                            const SizedBox(height: 16.0),
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                'Already have an account? Log in',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
