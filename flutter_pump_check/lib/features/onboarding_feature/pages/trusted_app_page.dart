import 'package:flutter/material.dart';
import 'package:flutter_pump_check/features/onboarding_feature/widgets/onboarding_gaps.dart';
import 'package:flutter_pump_check/features/onboarding_feature/widgets/onboarding_page_shell.dart';
import 'package:flutter_pump_check/features/onboarding_feature/widgets/onboarding_text.dart';
import 'package:flutter_pump_check/theme/app_dimensions.dart';
import 'package:flutter_pump_check/theme/claude_palette.dart';
import 'package:flutter_pump_check/theme/text_sizes.dart';

class TrustedAppOnboardingPage extends StatelessWidget {
  const TrustedAppOnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final spacing = context.dimensions.spacing;

    return OnboardingPageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GapH(spacing.sectionMedium),
          const OnboardingEyebrow('Trusted app'),
          GapH(spacing.lg),
          const OnboardingTitle('Built to feel credible before you commit.'),
          GapH(spacing.lg),
          const OnboardingBody(
            'A quick trust check before the trial screen. This mirrors the social-proof moment from the reference onboarding.',
          ),
          GapH(spacing.sectionSmall),
          const TrustedAppContentCard(),
          GapH(spacing.pageLarge),
        ],
      ),
    );
  }
}

class TrustedAppContentCard extends StatelessWidget {
  const TrustedAppContentCard({super.key});

  @override
  Widget build(BuildContext context) {
    final dimensions = context.dimensions;
    final spacing = dimensions.spacing;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(spacing.sectionMedium),
      decoration: BoxDecoration(
        color: ClaudePalette.charcoalSurface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(dimensions.radii.cardXLarge),
        border: Border.all(color: ClaudePalette.charcoalBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Help us grow',
            style: TextStyle(
              color: ClaudePalette.cream,
              fontSize: context.textSizes.s38,
              height: 1.05,
              fontWeight: FontWeight.w900,
            ),
          ),
          GapH(spacing.xl),
          StarRow(size: dimensions.icons.xl),
          GapH(spacing.sectionXXLarge),
          const _AvatarStack(),
          GapH(spacing.sectionLarge),
          Text(
            'Join 100,000+ Blackjack players training from their phones',
            style: TextStyle(
              color: ClaudePalette.cream.withValues(alpha: 0.86),
              fontSize: context.textSizes.s25,
              height: 1.18,
              fontWeight: FontWeight.w800,
            ),
          ),
          GapH(spacing.sectionLarge),
          const _TestimonialCard(
            initials: 'AR',
            name: 'Albert R.',
            quote:
                '“I used to just hit or split everything. Now I actually know when to double or split.”',
            color: Color(0xFF7E5A32),
          ),
          GapH(spacing.xl),
          const _TestimonialCard(
            initials: 'MA',
            name: 'Marcel A.',
            quote:
                '“I wasn’t aware of all the mistakes I was making. Good app.”',
            color: Color(0xFF44684A),
          ),
        ],
      ),
    );
  }
}

class StarRow extends StatelessWidget {
  const StarRow({this.size, super.key});

  final double? size;

  @override
  Widget build(BuildContext context) {
    final dimensions = context.dimensions;
    final resolvedSize = size ?? dimensions.icons.sm;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (index) => Padding(
          padding: EdgeInsets.only(
            right: index == 4
                ? 0
                : dimensions.components.starGapFor(resolvedSize),
          ),
          child: Icon(
            Icons.star,
            color: ClaudePalette.goal,
            size: resolvedSize,
          ),
        ),
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  const _AvatarStack();

  @override
  Widget build(BuildContext context) {
    const avatars = [
      ('JD', Color(0xFF727A7F)),
      ('BK', Color(0xFF75613F)),
      ('TR', Color(0xFF8C756A)),
      ('DM', Color(0xFF3F6E80)),
      ('LW', Color(0xFF365B4E)),
    ];
    final dimensions = context.dimensions;
    final avatarSize = dimensions.components.trustAvatarLarge;
    final overlap = dimensions.components.trustAvatarOverlap;

    return SizedBox(
      height: avatarSize,
      width: overlap * (avatars.length - 1) + avatarSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var index = 0; index < avatars.length; index++)
            Positioned(
              left: index * overlap,
              child: TrustAvatar(
                initials: avatars[index].$1,
                color: avatars[index].$2,
                size: avatarSize,
              ),
            ),
        ],
      ),
    );
  }
}

class TrustAvatar extends StatelessWidget {
  const TrustAvatar({
    required this.initials,
    required this.color,
    required this.size,
    super.key,
  });

  final String initials;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final dimensions = context.dimensions;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.black, width: dimensions.spacing.xs),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: ClaudePalette.cream,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  const _TestimonialCard({
    required this.initials,
    required this.name,
    required this.quote,
    required this.color,
  });

  final String initials;
  final String name;
  final String quote;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final dimensions = context.dimensions;
    final spacing = dimensions.spacing;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(spacing.xxxl),
      decoration: BoxDecoration(
        color: ClaudePalette.charcoal.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(dimensions.radii.card),
        border: Border.all(color: ClaudePalette.charcoalBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TrustAvatar(
            initials: initials,
            color: color,
            size: dimensions.components.trustAvatar,
          ),
          GapW(spacing.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: ClaudePalette.cream,
                    fontSize: context.textSizes.s22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                GapH(spacing.xxs),
                StarRow(size: dimensions.icons.sm),
                GapH(spacing.xl),
                Text(
                  quote,
                  style: TextStyle(
                    color: ClaudePalette.cream.withValues(alpha: 0.82),
                    fontSize: context.textSizes.s18,
                    height: 1.28,
                    fontWeight: FontWeight.w700,
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
