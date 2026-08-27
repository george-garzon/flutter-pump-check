import 'package:flutter/material.dart';
import 'package:flutter_pump_check/features/onboarding_feature/widgets/onboarding_cards.dart';
import 'package:flutter_pump_check/features/onboarding_feature/widgets/onboarding_page_shell.dart';
import 'package:flutter_pump_check/features/onboarding_feature/widgets/onboarding_text.dart';

class OnboardingHeroPage extends StatelessWidget {
  const OnboardingHeroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const OnboardingPageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 42),
          OnboardingIconBadge(Icons.local_fire_department_outlined),
          SizedBox(height: 26),
          OnboardingTitle('Welcome to Burn Camp.'),
          SizedBox(height: 14),
          OnboardingBody(
            'Track calories, protect your streak, and turn workouts into friendly accountability.',
          ),
          SizedBox(height: 28),
          MockMetricCard(),
          SizedBox(height: 42),
        ],
      ),
    );
  }
}
