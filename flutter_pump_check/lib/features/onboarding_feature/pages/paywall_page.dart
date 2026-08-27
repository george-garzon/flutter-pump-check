import 'package:flutter/material.dart';
import 'package:flutter_pump_check/features/onboarding_feature/widgets/onboarding_gaps.dart';
import 'package:flutter_pump_check/features/onboarding_feature/widgets/onboarding_page_shell.dart';
import 'package:flutter_pump_check/features/onboarding_feature/widgets/onboarding_text.dart';
import 'package:flutter_pump_check/theme/app_dimensions.dart';
import 'package:flutter_pump_check/theme/claude_palette.dart';
import 'package:flutter_pump_check/theme/text_sizes.dart';

class PaywallOnboardingPage extends StatelessWidget {
  const PaywallOnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dimensions = context.dimensions;
    final spacing = dimensions.spacing;

    return OnboardingPageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GapH(spacing.pageLarge),
          const OnboardingEyebrow('Free trial'),
          GapH(spacing.lg),
          const OnboardingTitle('Try Premium for 7 days.'),
          GapH(spacing.lg),
          const OnboardingBody(
            'Unlock deeper recaps, advanced streak settings, and premium accountability tools. Groups and bots stay free.',
          ),
          GapH(spacing.sectionXLarge),
          const _TimelineRow('Today', 'Start your free trial'),
          const _TimelineRow('Day 5', 'We remind you before the trial ends'),
          const _TimelineRow(
            'Day 7',
            'Continue with Premium or keep the free app',
          ),
          GapH(spacing.sectionLarge),
          Container(
            padding: EdgeInsets.all(spacing.xxxl),
            decoration: BoxDecoration(
              color: ClaudePalette.accent,
              borderRadius: BorderRadius.circular(dimensions.radii.xxl),
            ),
            child: Row(
              children: [
                const Icon(Icons.workspace_premium, color: ClaudePalette.cream),
                GapW(spacing.lg),
                Expanded(
                  child: Text(
                    '\$4.99/month after trial',
                    style: TextStyle(
                      color: ClaudePalette.cream,
                      fontSize: context.textSizes.s20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          GapH(spacing.pageLarge),
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
    final dimensions = context.dimensions;

    return Padding(
      padding: EdgeInsets.only(bottom: dimensions.spacing.xl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: dimensions.components.timelineLabelWidth,
            padding: EdgeInsets.symmetric(
              vertical: dimensions.spacing.sm * 0.875,
            ),
            decoration: BoxDecoration(
              color: ClaudePalette.charcoalSurface,
              borderRadius: BorderRadius.circular(dimensions.radii.pill),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ClaudePalette.accent,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          GapW(dimensions.spacing.lg),
          Expanded(child: OnboardingBody(value)),
        ],
      ),
    );
  }
}
