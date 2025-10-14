import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/auth/service/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authControllerProvider = Provider<AuthController>((ref) {
  final service = ref.read(authServiceProvider);
  return AuthController(service);
});

class AuthController {
  final AuthService _service;

  AuthController(this._service);

  Future<void> signUp(
    String email,
    String password,
    String name,
    String address,
    String phone,
  ) async {
    return _service.signUp(email, password, name, address, phone);
  }

  Future<void> login(String email, String password) async {
    return _service.login(email, password);
  }

  Future<void> logout() async {
    return _service.logout();
  }
}
