import 'package:flutter/material.dart';
import 'package:flutter_pump_check/features/onboarding_feature/widgets/onboarding_page_shell.dart';
import 'package:flutter_pump_check/features/onboarding_feature/widgets/onboarding_text.dart';
import 'package:flutter_pump_check/theme/claude_palette.dart';

class FocusOnboardingPage extends StatelessWidget {
  const FocusOnboardingPage({
    required this.focusAreas,
    required this.calorieGoal,
    required this.onFocusAreaToggled,
    required this.onCalorieGoalChanged,
    super.key,
  });

  static const _options = [
    'Staying consistent',
    'Burning more calories',
    'Training longer',
    'Competing with friends',
    'Remembering to log',
    'Recovering on rest days',
  ];

  final Set<String> focusAreas;
  final int calorieGoal;
  final ValueChanged<String> onFocusAreaToggled;
  final ValueChanged<int> onCalorieGoalChanged;

  @override
  Widget build(BuildContext context) {
    return OnboardingPageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 22),
          const OnboardingEyebrow('Focus'),
          const SizedBox(height: 12),
          const OnboardingTitle('What should Burn Camp help with first?'),
          const SizedBox(height: 10),
          const OnboardingBody(
            'Pick at least one. Your plan summary will reflect these.',
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _options.map((option) {
              final selected = focusAreas.contains(option);
              return FilterChip(
                selected: selected,
                label: Text(option),
                labelStyle: TextStyle(
                  color: selected
                      ? ClaudePalette.charcoal
                      : ClaudePalette.cream,
                  fontWeight: FontWeight.w700,
                ),
                selectedColor: ClaudePalette.accent,
                backgroundColor: ClaudePalette.charcoalSurface,
                checkmarkColor: ClaudePalette.charcoal,
                side: BorderSide(
                  color: selected
                      ? ClaudePalette.accent
                      : ClaudePalette.charcoalBorder,
                ),
                onSelected: (_) => onFocusAreaToggled(option),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
          Text(
            'Daily calorie goal',
            style: TextStyle(color: ClaudePalette.mutedText, fontSize: 15),
          ),
          Slider(
            value: calorieGoal.toDouble(),
            min: 100,
            max: 1200,
            divisions: 22,
            activeColor: ClaudePalette.accent,
            inactiveColor: ClaudePalette.charcoalSurface,
            label: '$calorieGoal cals',
            onChanged: (value) {
              onCalorieGoalChanged((value / 50).round() * 50);
            },
          ),
          Center(
            child: Text(
              '$calorieGoal calories/day',
              style: const TextStyle(
                color: ClaudePalette.cream,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
