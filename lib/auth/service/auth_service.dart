import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  Future<void> signUp(
    String email,
    String password,
    String name,
    String address,
    String phone,
  ) async {
    try {
      // Debug log
      // ignore: avoid_print
      print('AuthService.signUp: starting signup for $email');

      final response = await supabase.auth
          .signUp(
            email: email,
            password: password,
            data: {'name': name, 'address': address, 'phone': phone},
          )
          .timeout(const Duration(seconds: 20));

      // ignore: avoid_print
      print('AuthService.signUp: supabase returned, user: ${response.user}');

      if (response.user == null) {
        throw Exception('Signup failed: No user returned');
      }
    } on AuthException catch (e) {
      throw Exception('Signup failed: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<void> login(String email, String password) async {
    try {
      // ignore: avoid_print
      print('AuthService.login: starting login for $email');

      final response = await supabase.auth
          .signInWithPassword(email: email, password: password)
          .timeout(const Duration(seconds: 20));

      // ignore: avoid_print
      print('AuthService.login: supabase returned, user: ${response.user}');

      if (response.user == null) {
        throw Exception('Login failed: No user returned');
      }
    } on AuthException catch (e) {
      throw Exception('Login failed: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<void> logout() async {
    try {
      await supabase.auth.signOut();
    } on AuthException catch (e) {
      throw Exception('Logout failed: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}
