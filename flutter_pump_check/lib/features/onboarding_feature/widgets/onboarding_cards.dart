import 'package:flutter/material.dart';
import 'package:flutter_pump_check/theme/claude_palette.dart';

class OnboardingIconBadge extends StatelessWidget {
  const OnboardingIconBadge(this.icon, {super.key});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: ClaudePalette.accent,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Icon(icon, color: ClaudePalette.charcoal, size: 42),
    );
  }
}

class MockMetricCard extends StatelessWidget {
  const MockMetricCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: ClaudePalette.charcoalSurface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: ClaudePalette.charcoalBorder),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'calories today',
            style: TextStyle(color: ClaudePalette.mutedText, fontSize: 17),
          ),
          SizedBox(height: 8),
          Text(
            '500',
            style: TextStyle(
              color: ClaudePalette.cream,
              fontSize: 64,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '45 min trained · streak protected',
            style: TextStyle(color: ClaudePalette.accent, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class FeatureTile extends StatelessWidget {
  const FeatureTile({
    required this.icon,
    required this.title,
    required this.body,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClaudePalette.charcoalSurface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: ClaudePalette.accent, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: ClaudePalette.cream,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(
                    color: ClaudePalette.mutedText,
                    fontSize: 14,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChoiceCard extends StatelessWidget {
  const ChoiceCard({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: selected
                ? ClaudePalette.accent
                : ClaudePalette.charcoalSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? ClaudePalette.accent
                  : ClaudePalette.charcoalBorder,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? ClaudePalette.charcoal
                        : ClaudePalette.cream,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected
                    ? ClaudePalette.charcoal
                    : ClaudePalette.mutedText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TrackingChoiceCard extends StatelessWidget {
  const TrackingChoiceCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: selected
                ? ClaudePalette.accent
                : ClaudePalette.charcoalSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? ClaudePalette.accent
                  : ClaudePalette.charcoalBorder,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: selected
                    ? ClaudePalette.charcoal
                    : ClaudePalette.charcoalBorder,
                child: Icon(
                  icon,
                  color: selected ? ClaudePalette.accent : ClaudePalette.cream,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: selected
                            ? ClaudePalette.charcoal
                            : ClaudePalette.cream,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: selected
                            ? ClaudePalette.charcoal.withValues(alpha: 0.75)
                            : ClaudePalette.mutedText,
                        fontSize: 14,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected
                    ? ClaudePalette.charcoal
                    : ClaudePalette.mutedText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
