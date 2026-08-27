import 'package:flutter/material.dart';
import 'package:flutter_pump_check/theme/app_dimensions.dart';
import '../../../../../../theme/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/auth/auth_provider.dart';
import 'package:flutter_pump_check/theme/text_sizes.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.appColors;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: SizedBox(
          width: context.dimensions.values.s280,
          height: context.dimensions.values.s54,
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
                borderRadius: BorderRadius.circular(
                  context.dimensions.values.s30,
                ),
              ),
            ),
            child: Text(
              'Sign in to your account',
              style: TextStyle(
                fontSize: context.textSizes.s16,
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
