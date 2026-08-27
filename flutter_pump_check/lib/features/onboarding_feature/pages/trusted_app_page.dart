import 'package:flutter/material.dart';
import 'package:flutter_pump_check/features/onboarding_feature/widgets/onboarding_page_shell.dart';
import 'package:flutter_pump_check/features/onboarding_feature/widgets/onboarding_text.dart';
import 'package:flutter_pump_check/theme/claude_palette.dart';

class TrustedAppOnboardingPage extends StatelessWidget {
  const TrustedAppOnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const OnboardingPageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 22),
          OnboardingEyebrow('Trusted app'),
          SizedBox(height: 12),
          OnboardingTitle('Built to feel credible before you commit.'),
          SizedBox(height: 12),
          OnboardingBody(
            'A quick trust check before the trial screen. This mirrors the social-proof moment from the reference onboarding.',
          ),
          SizedBox(height: 20),
          TrustedAppContentCard(),
          SizedBox(height: 42),
        ],
      ),
    );
  }
}

class TrustedAppContentCard extends StatelessWidget {
  const TrustedAppContentCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: ClaudePalette.charcoalSurface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: ClaudePalette.charcoalBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Help us grow',
            style: TextStyle(
              color: ClaudePalette.cream,
              fontSize: 38,
              height: 1.05,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          const StarRow(size: 34),
          const SizedBox(height: 28),
          const _AvatarStack(),
          const SizedBox(height: 24),
          Text(
            'Join 100,000+ Blackjack players training from their phones',
            style: TextStyle(
              color: ClaudePalette.cream.withValues(alpha: 0.86),
              fontSize: 25,
              height: 1.18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 24),
          const _TestimonialCard(
            initials: 'AR',
            name: 'Albert R.',
            quote:
                '“I used to just hit or split everything. Now I actually know when to double or split.”',
            color: Color(0xFF7E5A32),
          ),
          const SizedBox(height: 14),
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
  const StarRow({this.size = 22, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (index) => Padding(
          padding: EdgeInsets.only(right: index == 4 ? 0 : size * 0.12),
          child: Icon(Icons.star, color: ClaudePalette.goal, size: size),
        ),
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  const _AvatarStack();

  @override
  Widget build(BuildContext context) {
    const avatarSize = 62.0;
    const overlap = 42.0;
    const avatars = [
      ('JD', Color(0xFF727A7F)),
      ('BK', Color(0xFF75613F)),
      ('TR', Color(0xFF8C756A)),
      ('DM', Color(0xFF3F6E80)),
      ('LW', Color(0xFF365B4E)),
    ];

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
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.black, width: 5),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ClaudePalette.charcoal.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ClaudePalette.charcoalBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TrustAvatar(initials: initials, color: color, size: 54),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: ClaudePalette.cream,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const StarRow(size: 22),
                const SizedBox(height: 14),
                Text(
                  quote,
                  style: TextStyle(
                    color: ClaudePalette.cream.withValues(alpha: 0.82),
                    fontSize: 18,
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
