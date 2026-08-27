import 'package:flutter/material.dart';
import 'package:flutter_pump_check/features/onboarding_feature/widgets/onboarding_cards.dart';
import 'package:flutter_pump_check/features/onboarding_feature/widgets/onboarding_gaps.dart';
import 'package:flutter_pump_check/features/onboarding_feature/widgets/onboarding_page_shell.dart';
import 'package:flutter_pump_check/features/onboarding_feature/widgets/onboarding_text.dart';
import 'package:flutter_pump_check/theme/app_dimensions.dart';

class OnboardingFeaturePage extends StatelessWidget {
  const OnboardingFeaturePage({super.key});

  @override
  Widget build(BuildContext context) {
    final spacing = context.dimensions.spacing;

    return OnboardingPageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GapH(spacing.pageLarge),
          const OnboardingEyebrow('How it works'),
          GapH(spacing.lg),
          const OnboardingTitle(
            'Small logs. Clear feedback. More consistent training.',
          ),
          GapH(spacing.sectionLarge),
          const FeatureTile(
            icon: Icons.add_circle_outline,
            title: 'Log workouts fast',
            body:
                'Calories, minutes, workout type, and notes stay lightweight.',
          ),
          const FeatureTile(
            icon: Icons.show_chart,
            title: 'See the trend',
            body:
                'Daily and weekly recaps make progress visible without clutter.',
          ),
          const FeatureTile(
            icon: Icons.groups_outlined,
            title: 'Use accountability',
            body: 'Groups and friends keep motivation closer to the surface.',
          ),
          GapH(spacing.pageLarge),
        ],
      ),
    );
  }
}
