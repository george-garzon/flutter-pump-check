import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_pump_check/features/dashboard_feature/screens/dashboard_screen.dart';
import 'package:flutter_pump_check/screens/auth_gate.dart';
import 'login_screen.dart';

import '../../../../gen/assets.gen.dart';
import '../../../../theme/dimens.dart';
import '../../../../theme/theme.dart';
import '../../../../utils/check_device_size.dart';

import '../../../../features/login_feature/data/auth_storage.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.delayed(const Duration(milliseconds: 1500));

    final isLoggedIn = await AuthStorage.isLoggedIn();

    if (!mounted) return;

    if (isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuthGate()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;

    return Scaffold(
      backgroundColor: colors.primary,
      body: SafeArea(
        child: Center(
          child: Assets.images.logoHorizDark.image(
            width: checkVerySmallDeviceSize(context) ? 290 : 390,
          ),
        ),
      ),
    );
  }
}