import 'package:flutter/material.dart';
import 'package:flutter_pump_check/features/onboarding_feature/widgets/onboarding_cards.dart';
import 'package:flutter_pump_check/features/onboarding_feature/widgets/onboarding_page_shell.dart';
import 'package:flutter_pump_check/features/onboarding_feature/widgets/onboarding_text.dart';

class OnboardingFeaturePage extends StatelessWidget {
  const OnboardingFeaturePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const OnboardingPageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 42),
          OnboardingEyebrow('How it works'),
          SizedBox(height: 12),
          OnboardingTitle(
            'Small logs. Clear feedback. More consistent training.',
          ),
          SizedBox(height: 24),
          FeatureTile(
            icon: Icons.add_circle_outline,
            title: 'Log workouts fast',
            body:
                'Calories, minutes, workout type, and notes stay lightweight.',
          ),
          FeatureTile(
            icon: Icons.show_chart,
            title: 'See the trend',
            body:
                'Daily and weekly recaps make progress visible without clutter.',
          ),
          FeatureTile(
            icon: Icons.groups_outlined,
            title: 'Use accountability',
            body: 'Groups and friends keep motivation closer to the surface.',
          ),
          SizedBox(height: 42),
        ],
      ),
    );
  }
}
