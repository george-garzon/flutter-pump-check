import 'package:flutter/material.dart';
import 'package:flutter_pump_check/features/onboarding_feature/widgets/onboarding_page_shell.dart';
import 'package:flutter_pump_check/features/onboarding_feature/widgets/onboarding_text.dart';
import 'package:flutter_pump_check/theme/claude_palette.dart';

class PaywallOnboardingPage extends StatelessWidget {
  const PaywallOnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingPageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 42),
          const OnboardingEyebrow('Free trial'),
          const SizedBox(height: 12),
          const OnboardingTitle('Try Premium for 7 days.'),
          const SizedBox(height: 12),
          const OnboardingBody(
            'Unlock deeper recaps, advanced streak settings, and premium accountability tools. Groups and bots stay free.',
          ),
          const SizedBox(height: 26),
          const _TimelineRow('Today', 'Start your free trial'),
          const _TimelineRow('Day 5', 'We remind you before the trial ends'),
          const _TimelineRow(
            'Day 7',
            'Continue with Premium or keep the free app',
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: ClaudePalette.accent,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Row(
              children: [
                Icon(Icons.workspace_premium, color: ClaudePalette.charcoal),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '\$4.99/month after trial',
                    style: TextStyle(
                      color: ClaudePalette.charcoal,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 42),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 72,
            padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: BoxDecoration(
              color: ClaudePalette.charcoalSurface,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: ClaudePalette.accent,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: OnboardingBody(value)),
        ],
      ),
    );
  }
}
