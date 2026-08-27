import 'package:flutter/material.dart';
import 'package:flutter_pump_check/features/onboarding_feature/widgets/onboarding_cards.dart';
import 'package:flutter_pump_check/features/onboarding_feature/widgets/onboarding_page_shell.dart';
import 'package:flutter_pump_check/features/onboarding_feature/widgets/onboarding_text.dart';

class SingleChoiceOnboardingPage extends StatelessWidget {
  const SingleChoiceOnboardingPage({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.options,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return OnboardingPageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 22),
          OnboardingEyebrow(eyebrow),
          const SizedBox(height: 12),
          OnboardingTitle(title),
          const SizedBox(height: 10),
          OnboardingBody(subtitle),
          const SizedBox(height: 28),
          ...options.map(
            (option) => ChoiceCard(
              label: option,
              selected: selected == option,
              onTap: () => onSelected(option),
            ),
          ),
        ],
      ),
    );
  }
}
