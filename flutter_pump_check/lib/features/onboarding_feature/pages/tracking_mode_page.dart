import 'package:flutter/material.dart';
import 'package:flutter_pump_check/features/onboarding_feature/widgets/onboarding_cards.dart';
import 'package:flutter_pump_check/features/onboarding_feature/widgets/onboarding_gaps.dart';
import 'package:flutter_pump_check/features/onboarding_feature/widgets/onboarding_page_shell.dart';
import 'package:flutter_pump_check/features/onboarding_feature/widgets/onboarding_text.dart';
import 'package:flutter_pump_check/theme/app_dimensions.dart';

class TrackingModeOnboardingPage extends StatelessWidget {
  const TrackingModeOnboardingPage({
    required this.trackingMode,
    required this.onTrackingModeChanged,
    super.key,
  });

  final String trackingMode;
  final ValueChanged<String> onTrackingModeChanged;

  @override
  Widget build(BuildContext context) {
    final spacing = context.dimensions.spacing;

    return OnboardingPageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GapH(spacing.sectionMedium),
          const OnboardingEyebrow('Tracking style'),
          GapH(spacing.lg),
          const OnboardingTitle('How do you want to track workouts?'),
          GapH(spacing.md),
          const OnboardingBody(
            'Burn Camp uses Apple Health on iPhone to import workout calories and duration automatically.',
          ),
          GapH(spacing.sectionXXLarge),
          TrackingChoiceCard(
            selected: trackingMode == 'appleHealth',
            icon: Icons.favorite_outline,
            title: 'Apple Health',
            subtitle:
                'Sync workouts from Apple Health on iPhone when permissions are enabled.',
            onTap: () => onTrackingModeChanged('appleHealth'),
          ),
          GapH(spacing.sectionSmall),
          const OnboardingBody(
            'You’ll be prompted to allow HealthKit access when this screen opens.',
          ),
        ],
      ),
    );
  }
}
