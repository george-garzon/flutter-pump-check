import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pump_check/features/onboarding_feature/pages/feature_page.dart';
import 'package:flutter_pump_check/features/onboarding_feature/pages/focus_page.dart';
import 'package:flutter_pump_check/features/onboarding_feature/pages/hero_page.dart';
// import 'package:flutter_pump_check/features/onboarding_feature/pages/paywall_page.dart';
import 'package:flutter_pump_check/features/onboarding_feature/pages/review_page.dart';
import 'package:flutter_pump_check/features/onboarding_feature/pages/single_choice_page.dart';
import 'package:flutter_pump_check/features/onboarding_feature/pages/tracking_mode_page.dart';
import 'package:flutter_pump_check/features/onboarding_feature/pages/trusted_app_page.dart';
import 'package:flutter_pump_check/services/apple_health_service.dart';
import 'package:flutter_pump_check/services/onboarding_preferences.dart';
import 'package:flutter_pump_check/theme/app_dimensions.dart';
import 'package:flutter_pump_check/theme/claude_palette.dart';
import 'package:flutter_pump_check/theme/text_sizes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _showPremiumTrialPage = false;
  static const _pageCount = _showPremiumTrialPage ? 10 : 9;
  static const _trackingModePage = 6;

  final _pageController = PageController();

  int _page = 0;
  bool _showPaywallClose = false;
  bool _saving = false;

  String? _goal;
  String? _level;
  String? _trainingDays;
  String _trackingMode = 'appleHealth';
  int _calorieGoal = 500;
  final Set<String> _focusAreas = {};
  bool _requestedAppleHealthAuthorization = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_page == _pageCount - 1) {
      _finish();
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _onPageChanged(int value) {
    setState(() {
      _page = value;
      _showPaywallClose = false;
    });

    if (_showPremiumTrialPage && value == _pageCount - 1) {
      Timer(const Duration(seconds: 3), () {
        if (!mounted || _page != _pageCount - 1) return;
        setState(() => _showPaywallClose = true);
      });
    }

    if (value == _trackingModePage) {
      unawaited(_requestAppleHealthAuthorization());
    }
  }

  bool get _canContinue {
    switch (_page) {
      case 2:
        return _goal != null;
      case 3:
        return _level != null;
      case 4:
        return _trainingDays != null;
      case 5:
        return _focusAreas.isNotEmpty;
      default:
        return true;
    }
  }

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);

    await OnboardingPreferences.save(
      fitnessGoal: _goal ?? 'Build consistency',
      experienceLevel: _level ?? 'Getting started',
      trainingDaysPerWeek: _trainingDays ?? '3-4 days',
      focusAreas: _focusAreas.toList(),
      goalCalories: _calorieGoal,
      workoutTrackingMode: _trackingMode,
    );
    await OnboardingPreferences.syncToCurrentUser();

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (_) => false);
  }

  Future<void> _requestAppleHealthAuthorization() async {
    if (_requestedAppleHealthAuthorization) return;
    _requestedAppleHealthAuthorization = true;

    final service = AppleHealthService();
    if (!service.isAvailableOnDevice) {
      return;
    }

    await service.requestAuthorization();
    if (!mounted) return;

    setState(() => _trackingMode = 'appleHealth');
  }

  void _setTrackingMode(String value) {
    setState(() => _trackingMode = 'appleHealth');
    _requestedAppleHealthAuthorization = false;
    unawaited(_requestAppleHealthAuthorization());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            _OnboardingTopBar(
              page: _page,
              pageCount: _pageCount,
              showPaywallClose: _showPaywallClose,
              onClosePaywall: _finish,
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: _onPageChanged,
                children: [
                  const OnboardingHeroPage(),
                  const OnboardingFeaturePage(),
                  SingleChoiceOnboardingPage(
                    eyebrow: 'Personalize',
                    title: 'What are you training for right now?',
                    subtitle:
                        'Burn Camp will tune goals, reminders, and recaps around this.',
                    options: const [
                      'Lose fat',
                      'Build a workout habit',
                      'Improve conditioning',
                      'Compete with friends',
                    ],
                    selected: _goal,
                    onSelected: (value) => setState(() => _goal = value),
                  ),
                  SingleChoiceOnboardingPage(
                    eyebrow: 'Baseline',
                    title: 'Where is your fitness level today?',
                    subtitle:
                        'No judgment. This changes how aggressive the plan feels.',
                    options: const [
                      'Getting started',
                      'Some momentum',
                      'Consistent trainer',
                      'High output',
                    ],
                    selected: _level,
                    onSelected: (value) => setState(() => _level = value),
                  ),
                  SingleChoiceOnboardingPage(
                    eyebrow: 'Schedule',
                    title: 'How many days do you want to train each week?',
                    subtitle:
                        'We use this to frame streaks around achievable consistency.',
                    options: const ['1-2 days', '3-4 days', '5+ days'],
                    selected: _trainingDays,
                    onSelected: (value) =>
                        setState(() => _trainingDays = value),
                  ),
                  FocusOnboardingPage(
                    focusAreas: _focusAreas,
                    calorieGoal: _calorieGoal,
                    onFocusAreaToggled: _toggleFocusArea,
                    onCalorieGoalChanged: (value) =>
                        setState(() => _calorieGoal = value),
                  ),
                  TrackingModeOnboardingPage(
                    trackingMode: _trackingMode,
                    onTrackingModeChanged: _setTrackingMode,
                  ),
                  ReviewOnboardingPage(
                    goal: _goal,
                    trainingDays: _trainingDays,
                    trackingMode: _trackingMode,
                    calorieGoal: _calorieGoal,
                    focusAreas: _focusAreas,
                  ),
                  const TrustedAppOnboardingPage(),
                  // const PaywallOnboardingPage(),
                ],
              ),
            ),
            _OnboardingBottomCta(
              page: _page,
              canContinue: _canContinue,
              saving: _saving,
              onPressed: _next,
            ),
          ],
        ),
      ),
    );
  }

  void _toggleFocusArea(String option) {
    setState(() {
      _focusAreas.contains(option)
          ? _focusAreas.remove(option)
          : _focusAreas.add(option);
    });
  }
}

class _OnboardingTopBar extends StatelessWidget {
  const _OnboardingTopBar({
    required this.page,
    required this.pageCount,
    required this.showPaywallClose,
    required this.onClosePaywall,
  });

  final int page;
  final int pageCount;
  final bool showPaywallClose;
  final VoidCallback onClosePaywall;

  @override
  Widget build(BuildContext context) {
    final onPaywall = page == pageCount - 1;
    final dimensions = context.dimensions;
    final spacing = dimensions.spacing;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        spacing.sectionSmall,
        spacing.lg,
        spacing.sectionSmall,
        spacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(dimensions.radii.pill),
              child: LinearProgressIndicator(
                value: (page + 1) / pageCount,
                minHeight: dimensions.components.topBarProgressHeight,
                backgroundColor: ClaudePalette.charcoalSurface,
                color: ClaudePalette.accent,
              ),
            ),
          ),
          SizedBox(width: spacing.lg),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            opacity: onPaywall && showPaywallClose ? 1 : 0,
            child: IgnorePointer(
              ignoring: !onPaywall || !showPaywallClose,
              child: IconButton(
                icon: const Icon(Icons.close, color: ClaudePalette.cream),
                onPressed: onClosePaywall,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingBottomCta extends StatelessWidget {
  const _OnboardingBottomCta({
    required this.page,
    required this.canContinue,
    required this.saving,
    required this.onPressed,
  });

  final int page;
  final bool canContinue;
  final bool saving;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final dimensions = context.dimensions;
    final spacing = dimensions.spacing;
    final label = switch (page) {
      0 => 'Get Started',
      8 => saving ? 'Starting...' : 'Start Burn Camp',
      _ => 'Continue',
    };

    return Padding(
      padding: EdgeInsets.fromLTRB(
        spacing.sectionSmall,
        spacing.sm,
        spacing.sectionSmall,
        spacing.sectionMedium,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: dimensions.components.buttonHeight,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: canContinue
                    ? ClaudePalette.accent
                    : ClaudePalette.charcoalSurface,
                foregroundColor: ClaudePalette.cream,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(dimensions.radii.lg),
                ),
              ),
              onPressed: canContinue && !saving ? onPressed : null,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: context.textSizes.s17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          if (_OnboardingScreenState._showPremiumTrialPage && page == 9) ...[
            SizedBox(height: spacing.md),
            Text(
              'Restore · Terms · Privacy',
              style: TextStyle(
                color: ClaudePalette.mutedText,
                fontSize: context.textSizes.s12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
