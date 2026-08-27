import 'package:flutter/material.dart';
import 'package:flutter_pump_check/features/onboarding_feature/widgets/onboarding_cards.dart';
import 'package:flutter_pump_check/features/onboarding_feature/widgets/onboarding_gaps.dart';
import 'package:flutter_pump_check/features/onboarding_feature/widgets/onboarding_page_shell.dart';
import 'package:flutter_pump_check/features/onboarding_feature/widgets/onboarding_text.dart';
import 'package:flutter_pump_check/theme/app_dimensions.dart';

class OnboardingHeroPage extends StatelessWidget {
  const OnboardingHeroPage({super.key});

  @override
  Widget build(BuildContext context) {
    final spacing = context.dimensions.spacing;

    return OnboardingPageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GapH(spacing.pageLarge),
          const OnboardingIconBadge(Icons.local_fire_department_outlined),
          GapH(spacing.sectionXLarge),
          const OnboardingTitle('Welcome to Burn Camp.'),
          GapH(spacing.xl),
          const OnboardingBody(
            'Track calories, protect your streak, and turn workouts into friendly accountability.',
          ),
          GapH(spacing.sectionXXLarge),
          const MockMetricCard(),
          GapH(spacing.pageLarge),
        ],
      ),
    );
  }
}
