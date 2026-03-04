import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final signInProvider = StateProvider<bool>((ref) => false);

final loginProvider = FutureProvider<void>((ref) async {
  final authService = ref.read(authServiceProvider);
  await authService.signInWithGoogle();
});