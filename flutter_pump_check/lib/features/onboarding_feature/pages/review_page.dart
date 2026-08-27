import 'package:flutter/material.dart';
import 'package:flutter_pump_check/features/onboarding_feature/widgets/onboarding_gaps.dart';
import 'package:flutter_pump_check/features/onboarding_feature/widgets/onboarding_page_shell.dart';
import 'package:flutter_pump_check/features/onboarding_feature/widgets/onboarding_text.dart';
import 'package:flutter_pump_check/theme/app_dimensions.dart';
import 'package:flutter_pump_check/theme/claude_palette.dart';
import 'package:flutter_pump_check/theme/text_sizes.dart';

class ReviewOnboardingPage extends StatelessWidget {
  const ReviewOnboardingPage({
    required this.goal,
    required this.trainingDays,
    required this.trackingMode,
    required this.calorieGoal,
    required this.focusAreas,
    super.key,
  });

  final String? goal;
  final String? trainingDays;
  final String trackingMode;
  final int calorieGoal;
  final Set<String> focusAreas;

  @override
  Widget build(BuildContext context) {
    final spacing = context.dimensions.spacing;

    return OnboardingPageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GapH(spacing.sectionMedium),
          const OnboardingEyebrow('Plan ready'),
          GapH(spacing.lg),
          const OnboardingTitle('Your Burn Camp plan is ready.'),
          GapH(spacing.lg),
          const OnboardingBody(
            'Based on your answers, we built a simple first-week setup to keep tracking clear and consistent.',
          ),
          GapH(spacing.sectionMedium),
          _PlanHeroCard(
            trainingDays: trainingDays,
            calorieGoal: calorieGoal,
            trackingMode: trackingMode,
          ),
          GapH(spacing.xxl),
          ReviewFeatureCard(
            icon: Icons.flag_outlined,
            title: 'Primary goal',
            value: goal ?? 'Build consistency',
          ),
          ReviewFeatureCard(
            icon: Icons.local_fire_department_outlined,
            title: 'Daily target',
            value: '$calorieGoal calories/day',
          ),
          ReviewFeatureCard(
            icon: Icons.calendar_month_outlined,
            title: 'Training rhythm',
            value: trainingDays ?? '3-4 days',
          ),
          ReviewFeatureCard(
            icon: trackingMode == 'appleHealth'
                ? Icons.favorite_outline
                : Icons.edit_note,
            title: 'Tracking style',
            value: trackingModeLabel(trackingMode),
          ),
          ReviewFeatureCard(
            icon: Icons.checklist_rtl,
            title: 'Focus areas',
            value: focusAreas.isEmpty ? 'Consistency' : focusAreas.join(', '),
          ),
          GapH(spacing.xxxl),
          const _ReassuranceCard(),
          GapH(spacing.pageLarge),
        ],
      ),
    );
  }
}

String trackingModeLabel(String mode) {
  return 'Apple Health';
}

class _PlanHeroCard extends StatelessWidget {
  const _PlanHeroCard({
    required this.trainingDays,
    required this.calorieGoal,
    required this.trackingMode,
  });

  final String? trainingDays;
  final int calorieGoal;
  final String trackingMode;

  @override
  Widget build(BuildContext context) {
    final dimensions = context.dimensions;
    final spacing = dimensions.spacing;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(spacing.sectionMedium),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [ClaudePalette.accent, Color(0xFFD88A24)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(dimensions.radii.cardXLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.verified,
                color: ClaudePalette.cream,
                size: dimensions.icons.md,
              ),
              GapW(spacing.md),
              Text(
                'Personalized setup',
                style: TextStyle(
                  color: ClaudePalette.cream,
                  fontSize: context.textSizes.s18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          GapH(spacing.xxl),
          Text(
            '${trainingDays ?? '3-4 days'} · $calorieGoal calories/day',
            style: TextStyle(
              color: ClaudePalette.cream,
              fontSize: context.textSizes.s28,
              height: 1.05,
              fontWeight: FontWeight.w900,
            ),
          ),
          GapH(spacing.md),
          Text(
            'Start with ${trackingModeLabel(trackingMode).toLowerCase()} and build from there.',
            style: TextStyle(
              color: ClaudePalette.cream.withValues(alpha: 0.82),
              fontSize: context.textSizes.s16,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class ReviewFeatureCard extends StatelessWidget {
  const ReviewFeatureCard({
    required this.icon,
    required this.title,
    required this.value,
    super.key,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final dimensions = context.dimensions;
    final spacing = dimensions.spacing;

    return Container(
      margin: EdgeInsets.only(bottom: spacing.md),
      padding: EdgeInsets.all(spacing.xxl),
      decoration: BoxDecoration(
        color: ClaudePalette.charcoalSurface,
        borderRadius: BorderRadius.circular(dimensions.radii.xl),
        border: Border.all(color: ClaudePalette.charcoalBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: ClaudePalette.accent, size: dimensions.icons.md),
          GapW(spacing.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: ClaudePalette.mutedText,
                    fontSize: context.textSizes.s13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                GapH(spacing.xxs),
                Text(
                  value,
                  style: TextStyle(
                    color: ClaudePalette.cream,
                    fontSize: context.textSizes.s17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          GapW(spacing.sm),
          Icon(
            Icons.check_circle,
            color: ClaudePalette.accent,
            size: dimensions.icons.sm,
          ),
        ],
      ),
    );
  }
}

class _ReassuranceCard extends StatelessWidget {
  const _ReassuranceCard();

  @override
  Widget build(BuildContext context) {
    final dimensions = context.dimensions;
    final spacing = dimensions.spacing;

    return Container(
      padding: EdgeInsets.all(spacing.xxl),
      decoration: BoxDecoration(
        color: ClaudePalette.charcoalSurface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(dimensions.radii.xl),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.settings_outlined,
            color: ClaudePalette.accent,
            size: dimensions.icons.sm,
          ),
          GapW(spacing.lg),
          Expanded(
            child: Text(
              'You can reset personalization anytime from Settings.',
              style: TextStyle(
                color: ClaudePalette.mutedText,
                fontSize: context.textSizes.s15,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
