import 'package:flutter/material.dart';
import 'package:flutter_pump_check/features/onboarding_feature/widgets/onboarding_gaps.dart';
import 'package:flutter_pump_check/theme/app_dimensions.dart';
import 'package:flutter_pump_check/theme/claude_palette.dart';
import 'package:flutter_pump_check/theme/text_sizes.dart';

class OnboardingIconBadge extends StatelessWidget {
  const OnboardingIconBadge(this.icon, {super.key});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final dimensions = context.dimensions;

    return Container(
      width: dimensions.components.iconBadge,
      height: dimensions.components.iconBadge,
      decoration: BoxDecoration(
        color: ClaudePalette.accent,
        borderRadius: BorderRadius.circular(dimensions.radii.card),
      ),
      child: Icon(
        icon,
        color: ClaudePalette.charcoal,
        size: dimensions.icons.xxl,
      ),
    );
  }
}

class MockMetricCard extends StatelessWidget {
  const MockMetricCard({super.key});

  @override
  Widget build(BuildContext context) {
    final dimensions = context.dimensions;
    final spacing = dimensions.spacing;

    return Container(
      padding: EdgeInsets.all(spacing.sectionMedium),
      decoration: BoxDecoration(
        color: ClaudePalette.charcoalSurface,
        borderRadius: BorderRadius.circular(dimensions.radii.cardLarge),
        border: Border.all(color: ClaudePalette.charcoalBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'calories today',
            style: TextStyle(
              color: ClaudePalette.mutedText,
              fontSize: context.textSizes.s17,
            ),
          ),
          GapH(spacing.sm),
          Text(
            '500',
            style: TextStyle(
              color: ClaudePalette.cream,
              fontSize: context.textSizes.s64,
              fontWeight: FontWeight.w900,
            ),
          ),
          GapH(spacing.sm),
          Text(
            '45 min trained · streak protected',
            style: TextStyle(
              color: ClaudePalette.accent,
              fontSize: context.textSizes.s16,
            ),
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
    final dimensions = context.dimensions;
    final spacing = dimensions.spacing;

    return Container(
      margin: EdgeInsets.only(bottom: spacing.lg),
      padding: EdgeInsets.all(spacing.xxl),
      decoration: BoxDecoration(
        color: ClaudePalette.charcoalSurface,
        borderRadius: BorderRadius.circular(dimensions.radii.lg),
      ),
      child: Row(
        children: [
          Icon(icon, color: ClaudePalette.accent, size: dimensions.icons.lg),
          GapW(spacing.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: ClaudePalette.cream,
                    fontSize: context.textSizes.s18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                GapH(spacing.xxs),
                Text(
                  body,
                  style: TextStyle(
                    color: ClaudePalette.mutedText,
                    fontSize: context.textSizes.s14,
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
    final dimensions = context.dimensions;
    final spacing = dimensions.spacing;

    return Padding(
      padding: EdgeInsets.only(bottom: spacing.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(dimensions.radii.lg),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(spacing.xxxl),
          decoration: BoxDecoration(
            color: selected
                ? ClaudePalette.accent
                : ClaudePalette.charcoalSurface,
            borderRadius: BorderRadius.circular(dimensions.radii.lg),
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
                    fontSize: context.textSizes.s18,
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
    final dimensions = context.dimensions;
    final spacing = dimensions.spacing;

    return Padding(
      padding: EdgeInsets.only(bottom: spacing.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(dimensions.radii.xl),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(spacing.xxxl),
          decoration: BoxDecoration(
            color: selected
                ? ClaudePalette.accent
                : ClaudePalette.charcoalSurface,
            borderRadius: BorderRadius.circular(dimensions.radii.xl),
            border: Border.all(
              color: selected
                  ? ClaudePalette.accent
                  : ClaudePalette.charcoalBorder,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: dimensions.components.trackingAvatarRadius,
                backgroundColor: selected
                    ? ClaudePalette.charcoal
                    : ClaudePalette.charcoalBorder,
                child: Icon(
                  icon,
                  color: selected ? ClaudePalette.accent : ClaudePalette.cream,
                ),
              ),
              GapW(spacing.xl),
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
                        fontSize: context.textSizes.s18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    GapH(spacing.xs),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: selected
                            ? ClaudePalette.charcoal.withValues(alpha: 0.75)
                            : ClaudePalette.mutedText,
                        fontSize: context.textSizes.s14,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              GapW(spacing.md),
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
