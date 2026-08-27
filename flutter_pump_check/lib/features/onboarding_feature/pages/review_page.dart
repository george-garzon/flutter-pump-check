import 'package:flutter/material.dart';
import 'package:flutter_pump_check/features/onboarding_feature/widgets/onboarding_page_shell.dart';
import 'package:flutter_pump_check/features/onboarding_feature/widgets/onboarding_text.dart';
import 'package:flutter_pump_check/theme/claude_palette.dart';

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
    return OnboardingPageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 22),
          const OnboardingEyebrow('Plan ready'),
          const SizedBox(height: 12),
          const OnboardingTitle('Your Burn Camp plan is ready.'),
          const SizedBox(height: 12),
          const OnboardingBody(
            'Based on your answers, we built a simple first-week setup to keep tracking clear and consistent.',
          ),
          const SizedBox(height: 22),
          _PlanHeroCard(
            trainingDays: trainingDays,
            calorieGoal: calorieGoal,
            trackingMode: trackingMode,
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 18),
          const _ReassuranceCard(),
          const SizedBox(height: 42),
        ],
      ),
    );
  }
}

String trackingModeLabel(String mode) {
  return mode == 'appleHealth' ? 'Apple Health' : 'Manual tracking';
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [ClaudePalette.accent, Color(0xFFD88A24)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.verified, color: ClaudePalette.charcoal, size: 28),
              SizedBox(width: 10),
              Text(
                'Personalized setup',
                style: TextStyle(
                  color: ClaudePalette.charcoal,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${trainingDays ?? '3-4 days'} · $calorieGoal calories/day',
            style: const TextStyle(
              color: ClaudePalette.charcoal,
              fontSize: 28,
              height: 1.05,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Start with ${trackingModeLabel(trackingMode).toLowerCase()} and build from there.',
            style: TextStyle(
              color: ClaudePalette.charcoal.withValues(alpha: 0.75),
              fontSize: 16,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClaudePalette.charcoalSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ClaudePalette.charcoalBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: ClaudePalette.accent, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: ClaudePalette.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: ClaudePalette.cream,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.check_circle, color: ClaudePalette.accent),
        ],
      ),
    );
  }
}

class _ReassuranceCard extends StatelessWidget {
  const _ReassuranceCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClaudePalette.charcoalSurface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.settings_outlined, color: ClaudePalette.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'You can reset personalization and switch tracking style anytime from Settings.',
              style: TextStyle(
                color: ClaudePalette.mutedText,
                fontSize: 15,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
