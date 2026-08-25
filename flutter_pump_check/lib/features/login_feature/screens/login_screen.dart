import 'package:flutter/material.dart';
import '../../../../../../theme/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/auth/auth_provider.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.appColors;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: SizedBox(
          width: 280,
          height: 54,
          child: ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(authServiceProvider).signInWithGoogle();
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Login failed: $e')));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              'Sign in to your account',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.gray,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
