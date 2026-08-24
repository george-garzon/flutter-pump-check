import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_pump_check/screens/auth_gate.dart';

import '../../../../gen/assets.gen.dart';
import '../../../../utils/check_device_size.dart';

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

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AuthGate()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Assets.images.logoHorizDark.image(
            width: checkVerySmallDeviceSize(context) ? 230 : 300,
          ),
        ),
      ),
    );
  }
}
