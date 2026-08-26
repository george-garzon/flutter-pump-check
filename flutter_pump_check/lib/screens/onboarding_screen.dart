import 'dart:async';

import 'package:flutter/material.dart';

import '../services/onboarding_preferences.dart';
import '../theme/claude_palette.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();

  int _page = 0;
  bool _showPaywallClose = false;
  bool _saving = false;

  String? _goal;
  String? _level;
  String? _trainingDays;
  String _trackingMode = 'manual';
  int _calorieGoal = 500;
  final Set<String> _focusAreas = {};

  static const _pageCount = 10;

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

    if (value == _pageCount - 1) {
      Timer(const Duration(seconds: 3), () {
        if (!mounted || _page != _pageCount - 1) return;
        setState(() => _showPaywallClose = true);
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: _onPageChanged,
                children: [
                  _heroPage(),
                  _featurePage(),
                  _singleChoicePage(
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
                  _singleChoicePage(
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
                  _singleChoicePage(
                    eyebrow: 'Schedule',
                    title: 'How many days do you want to train each week?',
                    subtitle:
                        'We use this to frame streaks around achievable consistency.',
                    options: const ['1-2 days', '3-4 days', '5+ days'],
                    selected: _trainingDays,
                    onSelected: (value) =>
                        setState(() => _trainingDays = value),
                  ),
                  _focusPage(),
                  _trackingModePage(),
                  _reviewPage(),
                  _trustedAppPage(),
                  _paywallPage(),
                ],
              ),
            ),
            _bottomCta(),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    final onPaywall = _page == _pageCount - 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: (_page + 1) / _pageCount,
                minHeight: 6,
                backgroundColor: ClaudePalette.charcoalSurface,
                color: ClaudePalette.accent,
              ),
            ),
          ),
          const SizedBox(width: 12),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            opacity: onPaywall && _showPaywallClose ? 1 : 0,
            child: IgnorePointer(
              ignoring: !onPaywall || !_showPaywallClose,
              child: IconButton(
                icon: const Icon(Icons.close, color: ClaudePalette.cream),
                onPressed: _finish,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroPage() {
    return _pageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 42),
          _iconBadge(Icons.local_fire_department_outlined),
          const SizedBox(height: 26),
          _title('Welcome to Burn Camp.'),
          const SizedBox(height: 14),
          _body(
            'Track calories, protect your streak, and turn workouts into friendly accountability.',
          ),
          const SizedBox(height: 28),
          _mockMetricCard(),
          const SizedBox(height: 42),
        ],
      ),
    );
  }

  Widget _featurePage() {
    return _pageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 42),
          _eyebrow('How it works'),
          const SizedBox(height: 12),
          _title('Small logs. Clear feedback. More consistent training.'),
          const SizedBox(height: 24),
          _featureTile(
            Icons.add_circle_outline,
            'Log workouts fast',
            'Calories, minutes, workout type, and notes stay lightweight.',
          ),
          _featureTile(
            Icons.show_chart,
            'See the trend',
            'Daily and weekly recaps make progress visible without clutter.',
          ),
          _featureTile(
            Icons.groups_outlined,
            'Use accountability',
            'Groups and friends keep motivation closer to the surface.',
          ),
          const SizedBox(height: 42),
        ],
      ),
    );
  }

  Widget _singleChoicePage({
    required String eyebrow,
    required String title,
    required String subtitle,
    required List<String> options,
    required String? selected,
    required ValueChanged<String> onSelected,
  }) {
    return _pageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 22),
          _eyebrow(eyebrow),
          const SizedBox(height: 12),
          _title(title),
          const SizedBox(height: 10),
          _body(subtitle),
          const SizedBox(height: 28),
          ...options.map(
            (option) => _choiceCard(
              label: option,
              selected: selected == option,
              onTap: () => onSelected(option),
            ),
          ),
        ],
      ),
    );
  }

  Widget _focusPage() {
    const options = [
      'Staying consistent',
      'Burning more calories',
      'Training longer',
      'Competing with friends',
      'Remembering to log',
      'Recovering on rest days',
    ];

    return _pageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 22),
          _eyebrow('Focus'),
          const SizedBox(height: 12),
          _title('What should Burn Camp help with first?'),
          const SizedBox(height: 10),
          _body('Pick at least one. Your plan summary will reflect these.'),
          const SizedBox(height: 22),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: options.map((option) {
              final selected = _focusAreas.contains(option);
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
                onSelected: (_) {
                  setState(() {
                    selected
                        ? _focusAreas.remove(option)
                        : _focusAreas.add(option);
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
          Text(
            'Daily calorie goal',
            style: TextStyle(color: ClaudePalette.mutedText, fontSize: 15),
          ),
          Slider(
            value: _calorieGoal.toDouble(),
            min: 100,
            max: 1200,
            divisions: 22,
            activeColor: ClaudePalette.accent,
            inactiveColor: ClaudePalette.charcoalSurface,
            label: '$_calorieGoal cals',
            onChanged: (value) {
              setState(() => _calorieGoal = (value / 50).round() * 50);
            },
          ),
          Center(
            child: Text(
              '$_calorieGoal calories/day',
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

  Widget _reviewPage() {
    return _pageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 22),
          _eyebrow('Plan ready'),
          const SizedBox(height: 12),
          _title('Your Burn Camp plan is ready.'),
          const SizedBox(height: 12),
          _body(
            'Based on your answers, we built a simple first-week setup to keep tracking clear and consistent.',
          ),
          const SizedBox(height: 22),
          _planHeroCard(),
          const SizedBox(height: 16),
          _reviewFeatureCard(
            Icons.flag_outlined,
            'Primary goal',
            _goal ?? 'Build consistency',
          ),
          _reviewFeatureCard(
            Icons.local_fire_department_outlined,
            'Daily target',
            '$_calorieGoal calories/day',
          ),
          _reviewFeatureCard(
            Icons.calendar_month_outlined,
            'Training rhythm',
            _trainingDays ?? '3-4 days',
          ),
          _reviewFeatureCard(
            _trackingMode == 'appleHealth'
                ? Icons.favorite_outline
                : Icons.edit_note,
            'Tracking style',
            _trackingModeLabel(_trackingMode),
          ),
          _reviewFeatureCard(
            Icons.checklist_rtl,
            'Focus areas',
            _focusAreas.isEmpty ? 'Consistency' : _focusAreas.join(', '),
          ),
          const SizedBox(height: 18),
          _reassuranceCard(),
          const SizedBox(height: 42),
        ],
      ),
    );
  }

  Widget _trackingModePage() {
    return _pageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 22),
          _eyebrow('Tracking style'),
          const SizedBox(height: 12),
          _title('How do you want to track workouts?'),
          const SizedBox(height: 10),
          _body(
            'Manual is selected by default. You can switch later in Settings.',
          ),
          const SizedBox(height: 28),
          _trackingChoiceCard(
            mode: 'manual',
            icon: Icons.edit_note,
            title: 'Manual tracking',
            subtitle:
                'Type calories burned and minutes trained after each workout.',
          ),
          _trackingChoiceCard(
            mode: 'appleHealth',
            icon: Icons.favorite_outline,
            title: 'Apple Health',
            subtitle:
                'Sync workouts from Apple Health on iPhone when permissions are enabled.',
          ),
          const SizedBox(height: 20),
          _body('Recommended: Manual for the cleanest first setup.'),
        ],
      ),
    );
  }

  Widget _paywallPage() {
    return _pageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 42),
          _eyebrow('Free trial'),
          const SizedBox(height: 12),
          _title('Try Premium for 7 days.'),
          const SizedBox(height: 12),
          _body(
            'Unlock deeper recaps, advanced streak settings, and premium accountability tools. Groups and bots stay free.',
          ),
          const SizedBox(height: 26),
          _timelineRow('Today', 'Start your free trial'),
          _timelineRow('Day 5', 'We remind you before the trial ends'),
          _timelineRow('Day 7', 'Continue with Premium or keep the free app'),
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

  Widget _trustedAppPage() {
    return _pageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 22),
          _eyebrow('Trusted app'),
          const SizedBox(height: 12),
          _title('Built to feel credible before you commit.'),
          const SizedBox(height: 12),
          _body(
            'A quick trust check before the trial screen. This mirrors the social-proof moment from the reference onboarding.',
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Image.asset(
              'assets/images/trusted_app_onboarding.png',
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 42),
        ],
      ),
    );
  }

  Widget _bottomCta() {
    final label = switch (_page) {
      0 => 'Get Started',
      8 => 'Continue to trial',
      9 => _saving ? 'Starting...' : 'Try for Free',
      _ => 'Continue',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _canContinue
                    ? ClaudePalette.accent
                    : ClaudePalette.charcoalSurface,
                foregroundColor: ClaudePalette.charcoal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: _canContinue && !_saving ? _next : null,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          if (_page == _pageCount - 1) ...[
            const SizedBox(height: 10),
            Text(
              'Restore · Terms · Privacy',
              style: TextStyle(color: ClaudePalette.mutedText, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _pageShell({required Widget child}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 8),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.sizeOf(context).height - 180,
        ),
        child: child,
      ),
    );
  }

  Widget _choiceCard({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
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

  Widget _mockMetricCard() {
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

  Widget _featureTile(IconData icon, String title, String body) {
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

  Widget _trackingChoiceCard({
    required String mode,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final selected = _trackingMode == mode;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => setState(() => _trackingMode = mode),
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

  Widget _planHeroCard() {
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
            '${_trainingDays ?? '3-4 days'} · $_calorieGoal calories/day',
            style: const TextStyle(
              color: ClaudePalette.charcoal,
              fontSize: 28,
              height: 1.05,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Start with ${_trackingModeLabel(_trackingMode).toLowerCase()} and build from there.',
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

  Widget _reviewFeatureCard(IconData icon, String title, String value) {
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

  Widget _reassuranceCard() {
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

  String _trackingModeLabel(String mode) {
    return mode == 'appleHealth' ? 'Apple Health' : 'Manual tracking';
  }

  Widget _timelineRow(String label, String value) {
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
          Expanded(child: _body(value)),
        ],
      ),
    );
  }

  Widget _iconBadge(IconData icon) {
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

  Widget _eyebrow(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: ClaudePalette.accent,
        fontSize: 13,
        letterSpacing: 1.4,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _title(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: ClaudePalette.cream,
        fontSize: 36,
        height: 1.02,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _body(String text) {
    return Text(
      text,
      style: TextStyle(
        color: ClaudePalette.mutedText,
        fontSize: 18,
        height: 1.35,
      ),
    );
  }
}
