import 'package:flutter/material.dart';
import 'package:flutter_pump_check/features/onboarding_feature/widgets/onboarding_cards.dart';
import 'package:flutter_pump_check/features/onboarding_feature/widgets/onboarding_page_shell.dart';
import 'package:flutter_pump_check/features/onboarding_feature/widgets/onboarding_text.dart';

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
    return OnboardingPageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 22),
          const OnboardingEyebrow('Tracking style'),
          const SizedBox(height: 12),
          const OnboardingTitle('How do you want to track workouts?'),
          const SizedBox(height: 10),
          const OnboardingBody(
            'Manual is selected by default. You can switch later in Settings.',
          ),
          const SizedBox(height: 28),
          TrackingChoiceCard(
            selected: trackingMode == 'manual',
            icon: Icons.edit_note,
            title: 'Manual tracking',
            subtitle:
                'Type calories burned and minutes trained after each workout.',
            onTap: () => onTrackingModeChanged('manual'),
          ),
          TrackingChoiceCard(
            selected: trackingMode == 'appleHealth',
            icon: Icons.favorite_outline,
            title: 'Apple Health',
            subtitle:
                'Sync workouts from Apple Health on iPhone when permissions are enabled.',
            onTap: () => onTrackingModeChanged('appleHealth'),
          ),
          const SizedBox(height: 20),
          const OnboardingBody(
            'Recommended: Manual for the cleanest first setup.',
          ),
        ],
      ),
    );
  }
}
