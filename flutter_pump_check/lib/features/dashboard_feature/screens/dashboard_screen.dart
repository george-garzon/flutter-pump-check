import 'dart:async';
import 'dart:math' as math;
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pump_check/theme/app_dimensions.dart';
import 'package:flutter/rendering.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_pump_check/features/onboarding_feature/screens/onboarding_screen.dart';
import 'package:flutter_pump_check/services/apple_health_service.dart';
import 'package:flutter_pump_check/services/auth/auth_service.dart';
import 'package:flutter_pump_check/services/onboarding_preferences.dart';
import 'package:flutter_pump_check/services/workout_service.dart';
import 'package:flutter_pump_check/features/dashboard_feature/widgets/dashboard_detail_page.dart';
import 'package:flutter_pump_check/features/dashboard_feature/widgets/dashboard_sections.dart';
import 'package:flutter_pump_check/features/dashboard_feature/widgets/dashboard_settings_row.dart';
import 'package:flutter_pump_check/features/dashboard_feature/widgets/dashboard_web_drawer.dart';
import 'package:flutter_pump_check/features/dashboard_feature/widgets/dashboard_weekday_label.dart';
import 'package:flutter_pump_check/theme/app_theme_mode.dart';
import 'package:flutter_pump_check/theme/claude_palette.dart';
import 'package:flutter_pump_check/utils/messages.dart' as preset_messages;
import 'package:flutter_pump_check/widgets/ad_supported_app_shell.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_pump_check/theme/text_sizes.dart';
import 'package:url_launcher/url_launcher.dart';

part 'dashboard_models.dart';
part 'stats_share_screen.dart';
part 'settings_tab.dart';
part 'history_tab.dart';
part 'social_activity_tab.dart';
part 'leaderboard_groups.dart';
part 'dashboard_helpers.dart';

enum MetricPeriod { today, yesterday, week, month }

enum HistoryRange { day, week, month, calendar }

double _adAwareBottomPadding(BuildContext context, double basePadding) {
  final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
  final adBarInset = AdSupportedAppInsets.bottomAdHeightOf(context);
  return math.max(keyboardInset, adBarInset) + basePadding;
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  static const _accent = ClaudePalette.accent;
  static const _goalLime = ClaudePalette.goal;
  static const _freeGroupLimit = 5;

  bool get _isLight => Theme.of(context).brightness == Brightness.light;
  Color get _background =>
      _isLight ? ClaudePalette.cream : ClaudePalette.charcoal;
  Color get _selectedSurface =>
      _isLight ? const Color(0xFFFFEFE5) : ClaudePalette.selectedSurface;
  Color get _surface =>
      _isLight ? const Color(0xFFFFFFFF) : ClaudePalette.charcoalSurface;
  Color get _divider =>
      _isLight ? const Color(0xFFE6D8CA) : ClaudePalette.charcoalBorder;
  Color get _muted =>
      _isLight ? ClaudePalette.lightMutedText : ClaudePalette.mutedText;
  Color get _cream => _isLight ? ClaudePalette.charcoal : ClaudePalette.cream;
  Color get _onAccent => ClaudePalette.cream;

  int _selectedIndex = 0;
  MetricPeriod _period = MetricPeriod.today;
  HistoryRange _historyRange = HistoryRange.week;
  bool _historyShowsAverage = true;
  bool _showFriends = true;
  int _settingsRefresh = 0;
  bool _syncingAppleHealth = false;
  bool _checkedAppleHealthOnLaunch = false;
  late final TabController _tabController;
  final TextEditingController _friendUsernameController =
      TextEditingController();

  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_syncSelectedTabIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_checkAppleHealthPermissionsAfterOnboarding());
    });
  }

  void _syncSelectedTabIndex() {
    if (_tabController.index != _selectedIndex) {
      setState(() => _selectedIndex = _tabController.index);
    }
  }

  void _selectTab(int index) {
    if (index == _selectedIndex) return;

    setState(() => _selectedIndex = index);
    _tabController.animateTo(index);
  }

  void _updateState(VoidCallback update) => setState(update);

  @override
  void dispose() {
    _tabController
      ..removeListener(_syncSelectedTabIndex)
      ..dispose();
    _friendUsernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const navHeight = 85.0;
    final bottomAdHeight = AdSupportedAppInsets.bottomAdHeightOf(context);
    final navBottomMargin = context.dimensions.values.s4;
    final navBottomOffset = bottomAdHeight + navBottomMargin;
    final screens = [
      _homeTab(),
      _historyTab(),
      _socialTab(),
      _activityTab(),
      _settingsTab(),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.only(bottom: navBottomOffset),
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: screens,
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: navBottomOffset),
              child: CNTabBar(
                backgroundColor: Colors.transparent,
                items: const [
                  CNTabBarItem(
                    label: '',
                    icon: CNSymbol('house.fill', size: 20),
                  ),
                  CNTabBarItem(
                    label: '',
                    icon: CNSymbol('chart.bar.fill', size: 20),
                  ),
                  CNTabBarItem(
                    label: '',
                    icon: CNSymbol('person.2.fill', size: 20),
                  ),
                  CNTabBarItem(
                    label: '',
                    icon: CNSymbol('bell.fill', size: 20),
                  ),
                  CNTabBarItem(
                    label: '',
                    icon: CNSymbol('gearshape.fill', size: 20),
                  ),
                ],
                currentIndex: _selectedIndex,
                tint: _accent,
                height: navHeight,
                onTap: _selectTab,
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _sheetBottomPadding(BuildContext context, double basePadding) {
    return _adAwareBottomPadding(context, basePadding);
  }

  double _contentBottomPadding(BuildContext context, double basePadding) {
    const navHeight = 85.0;
    final bottomAdHeight = AdSupportedAppInsets.bottomAdHeightOf(context);
    return bottomAdHeight + navHeight + basePadding;
  }

  Future<void> _checkAppleHealthPermissionsAfterOnboarding() async {
    if (_checkedAppleHealthOnLaunch) return;
    _checkedAppleHealthOnLaunch = true;

    final onboardingCompleted = await OnboardingPreferences.isCompleted();
    if (!onboardingCompleted || !mounted) return;

    final settings = _user == null
        ? await _localSettingsData()
        : (await FirebaseFirestore.instance
                      .collection('users')
                      .doc(_user!.uid)
                      .get())
                  .data() ??
              await _localSettingsData();
    final trackingMode =
        (settings['workoutTrackingMode'] as String?) ?? 'appleHealth';
    if (trackingMode != 'appleHealth') return;

    final service = AppleHealthService();
    if (!service.isAvailableOnDevice) return;

    final hasPermissions = await service.hasRequiredPermissions();
    if (hasPermissions || !mounted) return;

    await _showAppleHealthRequiredDialog(service);
  }

  Future<void> _showAppleHealthRequiredDialog(
    AppleHealthService service,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _surface,
          title: Text(
            'Apple Health access required',
            style: TextStyle(color: _cream),
          ),
          content: Text(
            'Burn Camp needs Apple Health access to import workout calories and minutes. Enable Health access to keep tracking data.',
            style: TextStyle(color: _muted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Not now', style: TextStyle(color: _muted)),
            ),
            TextButton(
              onPressed: () async {
                final granted = await service.requestAuthorization();
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
                if (!granted && mounted) {
                  _showSnack('Apple Health access is still disabled.');
                }
              },
              child: Text('Enable', style: TextStyle(color: _accent)),
            ),
          ],
        );
      },
    );
  }

  Widget _homeTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: WorkoutService.watchSummaries(limit: 120),
      builder: (context, snapshot) {
        final summaries = snapshot.data ?? [];
        final aggregate = _aggregateForPeriod(summaries, _period);

        return Column(
          children: [
            _topHeader(
              title: 'Burn Camp',
              leading: Builder(
                builder: (buttonContext) {
                  return IconButton(
                    icon: Icon(
                      Icons.ios_share,
                      color: _cream,
                      size: context.dimensions.values.s27,
                    ),
                    onPressed: () {
                      _openStatsShareScreen(summaries);
                    },
                  );
                },
              ),
              trailing: IconButton(
                icon: Icon(
                  Icons.add,
                  color: _cream,
                  size: context.dimensions.values.s32,
                ),
                onPressed: _showHomeCreateMenu,
              ),
              bottom: _periodTabs(),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => setState(() {}),
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    SizedBox(height: context.dimensions.values.s26),
                    Text(
                      _metricLabel(_period),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _cream,
                        fontSize: context.textSizes.s20,
                      ),
                    ),
                    SizedBox(height: context.dimensions.values.s10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            NumberFormat.decimalPattern().format(
                              aggregate.calories,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            style: TextStyle(
                              color: _cream,
                              fontSize: context.textSizes.s68,
                              fontWeight: FontWeight.w300,
                              height: 0.95,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.chevron_right,
                            color: _muted,
                            size: context.dimensions.values.s44,
                          ),
                          onPressed: () => _selectTab(1),
                        ),
                      ],
                    ),
                    SizedBox(height: context.dimensions.values.s10),
                    Text(
                      _minutesLabel(aggregate, _period),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _cream,
                        fontSize: context.textSizes.s20,
                      ),
                    ),
                    SizedBox(height: context.dimensions.values.s28),
                    _leaderboardToggle(),
                    SizedBox(height: context.dimensions.values.s18),
                    _leaderboard(aggregate),
                    SizedBox(height: context.dimensions.values.s30),
                    if (kDebugMode) ...[
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.dimensions.values.s22,
                        ),
                        child: SizedBox(
                          height: context.dimensions.values.s56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accent,
                              foregroundColor: _onAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  context.dimensions.values.s14,
                                ),
                              ),
                            ),
                            onPressed: _showAddWorkoutSheet,
                            child: Text(
                              aggregate.calories == 0
                                  ? 'Add today’s workout'
                                  : 'Add another workout',
                              style: TextStyle(fontSize: context.textSizes.s20),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: context.dimensions.values.s28),
                    ] else
                      SizedBox(height: context.dimensions.values.s28),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _historyTab() => _buildHistoryTab();

  Widget _socialTab() => _buildSocialTab();

  Widget _activityTab() => _buildActivityTab();

  Widget _settingsTab() => _buildSettingsTab();

  Widget _topHeader({
    required String title,
    required Widget leading,
    required Widget trailing,
    Widget? bottom,
  }) {
    return DashboardTopHeader(
      title: title,
      leading: leading,
      trailing: trailing,
      foreground: _cream,
      bottom: bottom,
    );
  }

  Widget _periodTabs() => _buildPeriodTabs();

  Widget _historyBar(Map<String, dynamic> summary, int scaleValue) {
    final calories = WorkoutService.caloriesFromSummary(summary);
    final minutes = WorkoutService.minutesFromSummary(summary);
    final value = _historyValueForSummaries([summary]);
    final widthFactor = value == 0
        ? 0.0
        : math.min(1.0, value / math.max(1, scaleValue));
    final label = _friendlyDate(summary);
    final valueText = _formatHistoryValue(
      calories,
      1,
      compact: false,
      includeUnit: false,
    );

    return Padding(
      padding: EdgeInsets.only(bottom: context.dimensions.values.s18),
      child: Row(
        children: [
          SizedBox(
            width: context.dimensions.values.s76,
            child: Text(
              label,
              style: TextStyle(color: _muted, fontSize: context.textSizes.s16),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _historyValueBar(
                  valueText: valueText,
                  widthFactor: widthFactor,
                  fontSize: context.textSizes.s19,
                ),
                SizedBox(height: context.dimensions.values.s5),
                Text('$minutes min trained', style: TextStyle(color: _muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryLine(
    String label,
    String value, {
    Color? valueColor,
    IconData? icon,
    VoidCallback? onTap,
  }) {
    final resolvedValueColor = valueColor ?? _cream;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.dimensions.values.s4),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(color: _cream, fontSize: context.textSizes.s20),
            ),
            const Spacer(),
            if (icon != null) ...[
              Icon(
                icon,
                color: resolvedValueColor,
                size: context.dimensions.values.s20,
              ),
              SizedBox(width: context.dimensions.values.s10),
            ],
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: resolvedValueColor,
                  fontSize: context.textSizes.s20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsRow(String label, String value, {VoidCallback? onTap}) {
    return DashboardSettingsRow(
      label: label,
      value: value,
      labelColor: _cream,
      valueColor: _muted,
      dividerColor: _surface,
      onTap: onTap,
    );
  }

  Future<void> _showAddWorkoutSheet() async {
    if (!kDebugMode) {
      _showSnack('Manual workout entry is only available in development.');
      return;
    }

    final user = _user;
    var defaultMinutes = 30;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      defaultMinutes =
          (doc.data()?['defaultWorkoutMinutes'] as num?)?.toInt() ?? 30;
    }

    if (!mounted) return;

    final caloriesController = TextEditingController();
    final minutesController = TextEditingController(
      text: defaultMinutes.toString(),
    );
    final notesController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    bool saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.dimensions.values.s22),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> save() async {
              final calories =
                  int.tryParse(caloriesController.text.trim()) ?? 0;
              final minutes = int.tryParse(minutesController.text.trim()) ?? 0;

              if (calories <= 0 || minutes <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Enter calories and minutes greater than 0.'),
                  ),
                );
                return;
              }

              setSheetState(() => saving = true);
              await WorkoutService.logWorkout(
                caloriesBurned: calories,
                minutesTrained: minutes,
                date: selectedDate,
                notes: notesController.text.trim().isEmpty
                    ? null
                    : notesController.text.trim(),
              );

              if (!context.mounted) return;
              Navigator.of(context).pop();
            }

            return Padding(
              padding: EdgeInsets.only(
                left: context.dimensions.values.s24,
                right: context.dimensions.values.s24,
                top: context.dimensions.values.s18,
                bottom: _sheetBottomPadding(context, 24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Add workout',
                          style: TextStyle(
                            color: _cream,
                            fontSize: context.textSizes.s22,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: saving ? null : save,
                        child: Text(
                          'Save',
                          style: TextStyle(
                            color: _accent,
                            fontSize: context.textSizes.s18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.dimensions.values.s14),
                  _darkNumberField(
                    controller: caloriesController,
                    label: 'Calories burned',
                    suffix: 'cals',
                  ),
                  SizedBox(height: context.dimensions.values.s12),
                  _darkNumberField(
                    controller: minutesController,
                    label: 'Minutes trained',
                    suffix: 'min',
                  ),
                  SizedBox(height: context.dimensions.values.s12),
                  TextField(
                    controller: notesController,
                    style: TextStyle(color: _cream),
                    decoration: _inputDecoration('Notes optional'),
                  ),
                  SizedBox(height: context.dimensions.values.s12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _cream,
                      side: BorderSide(color: _surface),
                      padding: EdgeInsets.symmetric(
                        vertical: context.dimensions.values.s12,
                      ),
                    ),
                    onPressed: saving
                        ? null
                        : () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(
                                const Duration(days: 1),
                              ),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setSheetState(() => selectedDate = picked);
                            }
                          },
                    icon: Icon(Icons.calendar_today),
                    label: Text(DateFormat.yMMMd().format(selectedDate)),
                  ),
                  SizedBox(height: context.dimensions.values.s16),
                  SizedBox(
                    height: context.dimensions.values.s50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: _onAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            context.dimensions.values.s14,
                          ),
                        ),
                      ),
                      onPressed: saving ? null : save,
                      child: saving
                          ? CircularProgressIndicator(color: _cream)
                          : Text(
                              'Save workout',
                              style: TextStyle(fontSize: context.textSizes.s17),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showGoalSheet() async {
    final user = _user;
    final data = user == null
        ? await _localSettingsData()
        : (await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .get())
                  .data() ??
              {};
    var goal = _goalCalories(data);

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: _background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.dimensions.values.s22),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> save() async {
              await _updateUserSettings({'goalCalories': goal});

              if (!context.mounted) return;
              Navigator.of(context).pop();
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                context.dimensions.values.s24,
                context.dimensions.values.s18,
                context.dimensions.values.s24,
                _sheetBottomPadding(context, context.dimensions.values.s34),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Daily Calorie Goal',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _cream,
                            fontSize: context.textSizes.s21,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: save,
                        child: Text(
                          'Done',
                          style: TextStyle(
                            color: _accent,
                            fontSize: context.textSizes.s18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.dimensions.values.s20),
                  Text(
                    NumberFormat.decimalPattern().format(goal),
                    style: TextStyle(
                      color: _goalLime,
                      fontSize: context.textSizes.s52,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  SizedBox(height: context.dimensions.values.s18),
                  Container(
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(
                        context.dimensions.values.s28,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.remove,
                            color: _cream,
                            size: context.dimensions.values.s26,
                          ),
                          onPressed: () {
                            setSheetState(() => goal = math.max(50, goal - 50));
                          },
                        ),
                        Container(
                          width: context.dimensions.values.s1,
                          height: context.dimensions.values.s28,
                          color: _muted,
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.add,
                            color: _cream,
                            size: context.dimensions.values.s26,
                          ),
                          onPressed: () => setSheetState(() => goal += 50),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: context.dimensions.values.s20),
                  Text(
                    'Set the calorie target you want to hit each training day. Streaks count days where this goal is met.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _cream,
                      fontSize: context.textSizes.s16,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showDefaultDurationSheet(int currentMinutes) async {
    final controller = TextEditingController(text: currentMinutes.toString());

    await _showSettingsSheet(
      title: 'Default Workout Duration',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _darkNumberField(
            controller: controller,
            label: 'Minutes',
            suffix: 'min',
          ),
          SizedBox(height: context.dimensions.values.s16),
          _primarySheetButton(
            label: 'Save duration',
            onPressed: () async {
              final minutes = int.tryParse(controller.text.trim()) ?? 0;
              if (minutes <= 0) {
                _showSnack('Enter a duration greater than 0 minutes.');
                return;
              }
              await _updateUserSettings({'defaultWorkoutMinutes': minutes});
              if (!mounted) return;
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showStreakModeSheet(String currentMode) {
    return _showChoiceSheet(
      title: 'Streak Mode',
      currentValue: currentMode,
      options: const {
        'strict': 'Strict — every day must hit the calorie goal',
        'flexible': 'Flexible — rest days do not break momentum',
        'trainingDays': 'Training days — only logged workout days count',
      },
      onSelected: (value) async {
        await _updateUserSettings({'streakMode': value});
      },
    );
  }

  Future<void> _showThemeModeSheet(String currentMode) {
    return _showChoiceSheet(
      title: 'Theme',
      currentValue: currentMode,
      options: const {'dark': 'Dark', 'light': 'Light', 'system': 'System'},
      onSelected: (value) async {
        appThemeModeNotifier.value = themeModeFromString(value);
        await _updateUserSettings({'themeMode': value});
      },
    );
  }

  Future<void> _showProfileSheet(Map<String, dynamic> data) async {
    final user = _user;
    if (user == null) return;

    final nameController = TextEditingController(
      text: (data['name'] as String?) ?? user.displayName ?? '',
    );
    final usernameController = TextEditingController(
      text: (data['username'] as String?) ?? '',
    );
    final photoUrl = (data['photoUrl'] as String?) ?? user.photoURL ?? '';
    var saving = false;

    await _showSettingsSheet(
      title: 'Update Profile',
      child: StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: CircleAvatar(
                  radius: context.dimensions.values.s46,
                  backgroundColor: _accent,
                  backgroundImage: photoUrl.trim().isNotEmpty
                      ? NetworkImage(photoUrl.trim())
                      : null,
                  child: photoUrl.trim().isEmpty
                      ? Icon(
                          Icons.person,
                          color: _background,
                          size: context.dimensions.values.s46,
                        )
                      : null,
                ),
              ),
              SizedBox(height: context.dimensions.values.s10),
              Text(
                'Profile picture updates are disabled for now.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _muted,
                  fontSize: context.textSizes.s14,
                ),
              ),
              SizedBox(height: context.dimensions.values.s22),
              TextField(
                controller: nameController,
                style: TextStyle(color: _cream),
                decoration: _inputDecoration('Display name'),
              ),
              SizedBox(height: context.dimensions.values.s12),
              TextField(
                controller: usernameController,
                style: TextStyle(color: _cream),
                decoration: _inputDecoration('Username'),
              ),
              SizedBox(height: context.dimensions.values.s16),
              _primarySheetButton(
                label: saving ? 'Saving…' : 'Save profile',
                onPressed: saving
                    ? () {}
                    : () async {
                        final name = nameController.text.trim();
                        final username = usernameController.text.trim();
                        if (name.isEmpty || username.isEmpty) {
                          _showSnack('Name and username are required.');
                          return;
                        }

                        setSheetState(() => saving = true);
                        try {
                          await user.updateDisplayName(name);
                          await _updateUserSettings({
                            'name': name,
                            'username': username,
                          });

                          if (!mounted) return;
                          Navigator.of(context).pop();
                          _showSnack('Profile updated.');
                        } catch (e) {
                          _showSnack('Profile update failed: $e');
                        } finally {
                          if (mounted) {
                            setSheetState(() => saving = false);
                          }
                        }
                      },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showRecapsSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: _background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.dimensions.values.s22),
        ),
      ),
      builder: (context) {
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: WorkoutService.watchSummaries(limit: 180),
          builder: (context, snapshot) {
            final summaries = snapshot.data ?? [];
            final today = _aggregateForPeriod(summaries, MetricPeriod.today);
            final week = _aggregateForPeriod(summaries, MetricPeriod.week);
            final month = _aggregateForPeriod(summaries, MetricPeriod.month);
            final lifetimeCalories = summaries.fold<int>(
              0,
              (total, summary) =>
                  total + WorkoutService.caloriesFromSummary(summary),
            );
            final lifetimeMinutes = summaries.fold<int>(
              0,
              (total, summary) =>
                  total + WorkoutService.minutesFromSummary(summary),
            );

            return Padding(
              padding: EdgeInsets.fromLTRB(
                context.dimensions.values.s24,
                context.dimensions.values.s18,
                context.dimensions.values.s24,
                _sheetBottomPadding(context, context.dimensions.values.s28),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Recaps',
                    style: TextStyle(
                      color: _cream,
                      fontSize: context.textSizes.s22,
                    ),
                  ),
                  SizedBox(height: context.dimensions.values.s16),
                  _recapRow('Today', today.calories, today.minutes),
                  _recapRow('This week', week.calories, week.minutes),
                  _recapRow('This month', month.calories, month.minutes),
                  _recapRow('All time', lifetimeCalories, lifetimeMinutes),
                  SizedBox(height: context.dimensions.values.s16),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _cream,
                      side: BorderSide(color: _divider),
                    ),
                    onPressed: () {
                      _shareText(
                        context,
                        'Burn Camp recap: ${NumberFormat.decimalPattern().format(month.calories)} calories and ${month.minutes} minutes trained this month.',
                      );
                    },
                    icon: Icon(Icons.ios_share),
                    label: Text('Share monthly recap'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _inviteFriends() async {
    await _shareText(
      context,
      'Join me on Burn Camp — track calories burned, training minutes, and compare workouts with friends.',
    );
  }

  Future<void> _showGroupDetailsDialog(
    QueryDocumentSnapshot<Map<String, dynamic>> groupDoc,
  ) async {
    final data = groupDoc.data();
    final name = (data['name'] as String?) ?? 'Workout group';
    final memberIds = List<String>.from(data['memberIds'] ?? const []);
    final ownerId =
        (data['ownerId'] as String?) ?? data['createdBy'] as String?;
    final pendingInvites =
        (data['pendingInviteIds'] as List<dynamic>? ?? const []).length;
    final currentUserId = _user?.uid;
    final detailsFuture = _groupDetailsData(memberIds);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.dimensions.values.s22),
            side: BorderSide(color: _divider),
          ),
          title: Text(name, style: TextStyle(color: _cream)),
          content: SizedBox(
            width: double.maxFinite,
            child: FutureBuilder<_GroupDetailsData>(
              future: detailsFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return SizedBox(
                    height: context.dimensions.values.s180,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final details = snapshot.data!;
                final members = details.members;
                final dialogFriendIds = {...details.friendIds};
                final calories = members.fold<int>(
                  0,
                  (total, member) => total + member.calories,
                );
                final minutes = members.fold<int>(
                  0,
                  (total, member) => total + member.minutes,
                );
                final goalsMet = members
                    .where((member) => member.goalMet)
                    .length;

                return StatefulBuilder(
                  builder: (context, setDialogState) {
                    return SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              _groupStatPill(
                                'Calories',
                                NumberFormat.compact().format(calories),
                              ),
                              SizedBox(width: context.dimensions.values.s10),
                              _groupStatPill('Minutes', '$minutes'),
                              SizedBox(width: context.dimensions.values.s10),
                              _groupStatPill(
                                'Goals',
                                '$goalsMet/${members.length}',
                              ),
                            ],
                          ),
                          if (pendingInvites > 0) ...[
                            SizedBox(height: context.dimensions.values.s12),
                            Text(
                              '$pendingInvites pending invite${pendingInvites == 1 ? '' : 's'}',
                              style: TextStyle(
                                color: _muted,
                                fontSize: context.textSizes.s13,
                              ),
                            ),
                          ],
                          SizedBox(height: context.dimensions.values.s16),
                          Divider(color: _divider),
                          SizedBox(height: context.dimensions.values.s6),
                          if (members.isEmpty)
                            Text(
                              'No members found yet.',
                              style: TextStyle(
                                color: _muted,
                                fontSize: context.textSizes.s16,
                              ),
                            )
                          else
                            ...members.indexed.map((entry) {
                              final index = entry.$1;
                              final member = entry.$2;
                              final isOwner = member.userId == ownerId;
                              final isCurrentUser =
                                  member.userId == currentUserId;
                              final isFriend =
                                  isCurrentUser ||
                                  dialogFriendIds.contains(member.userId);
                              return _groupMemberRow(
                                index + 1,
                                member,
                                isOwner,
                                isFriend: isFriend,
                                isCurrentUser: isCurrentUser,
                                onAddFriend: isFriend
                                    ? null
                                    : () async {
                                        final sent =
                                            await _sendFriendRequestToUser(
                                              friendId: member.userId,
                                              fallbackUsername:
                                                  member.username.isNotEmpty
                                                  ? member.username
                                                  : member.name,
                                            );
                                        if (sent) {
                                          setDialogState(() {
                                            dialogFriendIds.add(member.userId);
                                          });
                                        }
                                        return sent;
                                      },
                              );
                            }),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Close', style: TextStyle(color: _accent)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _showInviteToGroupSheet(groupDoc);
              },
              child: Text('Invite', style: TextStyle(color: _accent)),
            ),
          ],
        );
      },
    );
  }

  Widget _groupStatPill(String label, String value) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.dimensions.values.s10,
          vertical: context.dimensions.values.s12,
        ),
        decoration: BoxDecoration(
          color: _selectedSurface,
          borderRadius: BorderRadius.circular(context.dimensions.values.s14),
        ),
        child: Column(
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _cream,
                fontWeight: FontWeight.w700,
                fontSize: context.textSizes.s17,
              ),
            ),
            SizedBox(height: context.dimensions.values.s3),
            Text(
              label,
              style: TextStyle(color: _muted, fontSize: context.textSizes.s12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _groupMemberRow(
    int rank,
    _GroupMemberPerformance member,
    bool isOwner, {
    required bool isFriend,
    required bool isCurrentUser,
    Future<bool> Function()? onAddFriend,
  }) {
    final progress = member.goalCalories <= 0
        ? 0.0
        : math.min(1.0, member.calories / member.goalCalories);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.dimensions.values.s10),
      child: Row(
        children: [
          SizedBox(
            width: context.dimensions.values.s30,
            child: Text(
              '$rank',
              style: TextStyle(color: _muted, fontWeight: FontWeight.w700),
            ),
          ),
          CircleAvatar(
            radius: context.dimensions.values.s19,
            backgroundColor: member.goalMet ? _accent : _selectedSurface,
            child: Icon(
              member.goalMet ? Icons.local_fire_department : Icons.person,
              color: _background,
              size: context.dimensions.values.s20,
            ),
          ),
          SizedBox(width: context.dimensions.values.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        member.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _cream,
                          fontWeight: FontWeight.w700,
                          fontSize: context.textSizes.s16,
                        ),
                      ),
                    ),
                    if (isOwner) ...[
                      SizedBox(width: context.dimensions.values.s6),
                      Icon(
                        Icons.star,
                        color: _goalLime,
                        size: context.dimensions.values.s15,
                      ),
                    ],
                  ],
                ),
                SizedBox(height: context.dimensions.values.s6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(
                    context.dimensions.values.s20,
                  ),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: _divider,
                    color: member.goalMet ? _accent : _goalLime,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: context.dimensions.values.s12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                NumberFormat.compact().format(member.calories),
                style: TextStyle(
                  color: _cream,
                  fontSize: context.textSizes.s16,
                ),
              ),
              Text(
                '${member.minutes} min',
                style: TextStyle(
                  color: _muted,
                  fontSize: context.textSizes.s12,
                ),
              ),
            ],
          ),
          SizedBox(width: context.dimensions.values.s8),
          SizedBox(
            width: context.dimensions.values.s34,
            child: isFriend
                ? Icon(
                    isCurrentUser ? Icons.person : Icons.check_circle,
                    color: isCurrentUser ? _muted : _goalLime,
                    size: context.dimensions.values.s22,
                  )
                : IconButton(
                    tooltip: 'Add friend',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 34,
                      minHeight: 34,
                    ),
                    onPressed: onAddFriend == null
                        ? null
                        : () async {
                            final sent = await onAddFriend();
                            if (sent && mounted) setState(() {});
                          },
                    icon: Icon(
                      Icons.add_circle,
                      color: _accent,
                      size: context.dimensions.values.s24,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _showInviteToGroupSheet(
    QueryDocumentSnapshot<Map<String, dynamic>> groupDoc,
  ) async {
    final user = _user;
    if (user == null) {
      _showSnack('Sign in to invite people.');
      return;
    }

    final groupData = groupDoc.data();
    final groupName = (groupData['name'] as String?) ?? 'Workout group';
    final usernameController = TextEditingController();
    bool sending = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.dimensions.values.s22),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> sendInvite() async {
              final username = usernameController.text.trim().replaceFirst(
                '@',
                '',
              );
              if (username.isEmpty) {
                _showSnack('Enter a username to invite.');
                return;
              }

              setSheetState(() => sending = true);
              try {
                final invitedUserDoc = await _findUserByUsername(username);
                if (invitedUserDoc == null) {
                  _showSnack('Could not find @$username.');
                  return;
                }

                final invitedUserId = invitedUserDoc.id;
                final invitedUsername =
                    (invitedUserDoc.data()['username'] as String?) ?? username;

                if (invitedUserId == user.uid) {
                  _showSnack('You are already in this group.');
                  return;
                }

                final groupRef = FirebaseFirestore.instance
                    .collection('groups')
                    .doc(groupDoc.id);
                final invitationRef = groupRef
                    .collection('invitations')
                    .doc(invitedUserId);
                final inviteRef = FirebaseFirestore.instance
                    .collection('group_invites')
                    .doc();
                var didSend = false;
                var message = 'Invite already pending for @$invitedUsername.';

                await FirebaseFirestore.instance.runTransaction((
                  transaction,
                ) async {
                  final latestGroupDoc = await transaction.get(groupRef);
                  if (!latestGroupDoc.exists) {
                    throw StateError('Group no longer exists.');
                  }

                  final latestGroup = latestGroupDoc.data()!;
                  final memberIds = List<String>.from(
                    latestGroup['memberIds'] ?? const [],
                  );
                  final pendingInviteIds = List<String>.from(
                    latestGroup['pendingInviteIds'] ?? const [],
                  );

                  if (memberIds.contains(invitedUserId)) {
                    message = '@$invitedUsername is already in this group.';
                    return;
                  }

                  if (pendingInviteIds.contains(invitedUserId)) {
                    return;
                  }

                  final existingInviteDoc = await transaction.get(
                    invitationRef,
                  );
                  if (existingInviteDoc.exists &&
                      existingInviteDoc.data()?['status'] == 'pending') {
                    return;
                  }

                  final invitePayload = {
                    'fromUserId': user.uid,
                    'fromUserName': user.displayName ?? user.email ?? 'Burner',
                    'toUserId': invitedUserId,
                    'toUserName': invitedUsername,
                    'groupId': groupDoc.id,
                    'groupName': groupName,
                    'status': 'pending',
                    'createdAt': FieldValue.serverTimestamp(),
                  };

                  transaction.update(groupRef, {
                    'pendingInviteIds': FieldValue.arrayUnion([invitedUserId]),
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
                  transaction.set(inviteRef, invitePayload);
                  transaction.set(invitationRef, {
                    ...invitePayload,
                    'inviteId': inviteRef.id,
                  });

                  didSend = true;
                  message = 'Invited @$invitedUsername to $groupName.';
                });

                if (!context.mounted) return;
                if (didSend) Navigator.of(context).pop();
                _showSnack(message);
              } catch (e) {
                _showSnack('Could not send invite: $e');
              } finally {
                if (context.mounted) setSheetState(() => sending = false);
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: context.dimensions.values.s24,
                right: context.dimensions.values.s24,
                top: context.dimensions.values.s18,
                bottom: _sheetBottomPadding(context, 28),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Invite to $groupName',
                      style: TextStyle(
                        color: _cream,
                        fontSize: context.textSizes.s22,
                      ),
                    ),
                    SizedBox(height: context.dimensions.values.s8),
                    Text(
                      'Enter a Burn Camp username. Existing members and pending invites will be skipped.',
                      style: TextStyle(
                        color: _muted,
                        fontSize: context.textSizes.s14,
                      ),
                    ),
                    SizedBox(height: context.dimensions.values.s16),
                    TextField(
                      controller: usernameController,
                      style: TextStyle(color: _cream),
                      autofocus: true,
                      decoration: _inputDecoration('Username'),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) {
                        if (!sending) sendInvite();
                      },
                    ),
                    SizedBox(height: context.dimensions.values.s18),
                    SizedBox(
                      height: context.dimensions.values.s50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: _onAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              context.dimensions.values.s14,
                            ),
                          ),
                        ),
                        onPressed: sending ? null : sendInvite,
                        child: sending
                            ? CircularProgressIndicator(color: _cream)
                            : Text(
                                'Send invite',
                                style: TextStyle(
                                  fontSize: context.textSizes.s17,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    usernameController.dispose();
  }

  Future<void> _showCreateGroupSheet() async {
    final user = _user;
    if (user == null) {
      _showSnack('Sign in to create a group.');
      return;
    }

    final existingGroupCount = await _currentUserCreatedGroupCount();
    if (!mounted) return;
    if (existingGroupCount >= _freeGroupLimit) {
      _showSnack('Free accounts can create up to $_freeGroupLimit groups.');
      _showSupportPage();
      return;
    }

    final groupNameController = TextEditingController();
    final usernameController = TextEditingController();
    final friendsFuture = _loadFriendOptions(user.uid);
    final selectedFriendIds = <String>{};
    final manualUsernames = <String>{};
    bool saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.dimensions.values.s22),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> createGroup() async {
              final groupName = groupNameController.text.trim();
              if (groupName.isEmpty) {
                _showSnack('Name your group first.');
                return;
              }

              setSheetState(() => saving = true);
              try {
                final currentGroupCount = await _currentUserCreatedGroupCount();
                if (currentGroupCount >= _freeGroupLimit) {
                  _showSnack(
                    'Free accounts can create up to $_freeGroupLimit groups.',
                  );
                  return;
                }

                final friends = await friendsFuture;
                final friendNamesById = {
                  for (final friend in friends) friend.userId: friend.name,
                };
                final resolution = await _resolveInviteIds(
                  ownerId: user.uid,
                  manualUsernames: manualUsernames,
                  selectedFriendIds: selectedFriendIds,
                );

                if (resolution.missingUsernames.isNotEmpty) {
                  _showSnack(
                    'Could not find: ${resolution.missingUsernames.join(', ')}',
                  );
                  return;
                }

                final groupRef = FirebaseFirestore.instance
                    .collection('groups')
                    .doc();
                final inviteIds = resolution.userIds.toList()..sort();

                final batch = FirebaseFirestore.instance.batch();
                batch.set(groupRef, {
                  'name': groupName,
                  'ownerId': user.uid,
                  'createdBy': user.uid,
                  'memberIds': [user.uid],
                  'pendingInviteIds': inviteIds,
                  'createdAt': FieldValue.serverTimestamp(),
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                batch.set(
                  FirebaseFirestore.instance.collection('users').doc(user.uid),
                  {
                    'groups': FieldValue.arrayUnion([groupRef.id]),
                    'updatedAt': FieldValue.serverTimestamp(),
                  },
                  SetOptions(merge: true),
                );

                for (final inviteId in inviteIds) {
                  final inviteRef = FirebaseFirestore.instance
                      .collection('group_invites')
                      .doc();
                  final inviteName =
                      friendNamesById[inviteId] ??
                      resolution.usernamesById[inviteId] ??
                      'Friend';
                  final invitePayload = {
                    'fromUserId': user.uid,
                    'fromUserName': user.displayName ?? user.email ?? 'Burner',
                    'toUserId': inviteId,
                    'toUserName': inviteName,
                    'groupId': groupRef.id,
                    'groupName': groupName,
                    'status': 'pending',
                    'createdAt': FieldValue.serverTimestamp(),
                  };

                  batch.set(inviteRef, invitePayload);
                  batch.set(groupRef.collection('invitations').doc(inviteId), {
                    ...invitePayload,
                    'inviteId': inviteRef.id,
                  });
                }

                await batch.commit();

                if (!context.mounted) return;
                Navigator.of(context).pop();
                _showSnack(
                  inviteIds.isEmpty
                      ? 'Created $groupName.'
                      : 'Created $groupName and invited ${inviteIds.length}.',
                );
              } catch (e) {
                _showSnack('Could not create group: $e');
              } finally {
                if (mounted) setSheetState(() => saving = false);
              }
            }

            void addManualUsername() {
              final username = usernameController.text.trim().replaceFirst(
                '@',
                '',
              );
              if (username.isEmpty) return;
              setSheetState(() {
                manualUsernames.add(username);
                usernameController.clear();
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                left: context.dimensions.values.s24,
                right: context.dimensions.values.s24,
                top: context.dimensions.values.s18,
                bottom: _sheetBottomPadding(context, 28),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Create group',
                        style: TextStyle(
                          color: _cream,
                          fontSize: context.textSizes.s22,
                        ),
                      ),
                      SizedBox(height: context.dimensions.values.s16),
                      TextField(
                        controller: groupNameController,
                        style: TextStyle(color: _cream),
                        decoration: _inputDecoration('Group name'),
                      ),
                      SizedBox(height: context.dimensions.values.s14),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: usernameController,
                              style: TextStyle(color: _cream),
                              decoration: _inputDecoration('Invite username'),
                              onSubmitted: (_) => addManualUsername(),
                            ),
                          ),
                          SizedBox(width: context.dimensions.values.s10),
                          IconButton.filled(
                            style: IconButton.styleFrom(
                              backgroundColor: _accent,
                              foregroundColor: _onAccent,
                            ),
                            onPressed: addManualUsername,
                            icon: Icon(Icons.add),
                          ),
                        ],
                      ),
                      if (manualUsernames.isNotEmpty) ...[
                        SizedBox(height: context.dimensions.values.s10),
                        Wrap(
                          spacing: context.dimensions.values.s8,
                          runSpacing: context.dimensions.values.s8,
                          children: manualUsernames.map((username) {
                            return InputChip(
                              label: Text('@$username'),
                              onDeleted: () {
                                setSheetState(
                                  () => manualUsernames.remove(username),
                                );
                              },
                            );
                          }).toList(),
                        ),
                      ],
                      SizedBox(height: context.dimensions.values.s18),
                      Text(
                        'Pick from friends',
                        style: TextStyle(
                          color: _cream,
                          fontSize: context.textSizes.s16,
                        ),
                      ),
                      SizedBox(height: context.dimensions.values.s8),
                      FutureBuilder<List<_GroupInviteOption>>(
                        future: friendsFuture,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: context.dimensions.values.s20,
                              ),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          final friends = snapshot.data!;
                          if (friends.isEmpty) {
                            return Text(
                              'No friends yet. Add usernames manually above.',
                              style: TextStyle(color: _muted),
                            );
                          }

                          return Column(
                            children: friends.map((friend) {
                              final selected = selectedFriendIds.contains(
                                friend.userId,
                              );
                              return CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                value: selected,
                                activeColor: _accent,
                                checkColor: _onAccent,
                                title: Text(
                                  friend.name,
                                  style: TextStyle(color: _cream),
                                ),
                                subtitle: Text(
                                  '@${friend.username}',
                                  style: TextStyle(color: _muted),
                                ),
                                onChanged: (checked) {
                                  setSheetState(() {
                                    if (checked == true) {
                                      selectedFriendIds.add(friend.userId);
                                    } else {
                                      selectedFriendIds.remove(friend.userId);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          );
                        },
                      ),
                      SizedBox(height: context.dimensions.values.s18),
                      SizedBox(
                        height: context.dimensions.values.s50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: _onAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                context.dimensions.values.s14,
                              ),
                            ),
                          ),
                          onPressed: saving ? null : createGroup,
                          child: saving
                              ? CircularProgressIndicator(color: _cream)
                              : Text(
                                  'Create group',
                                  style: TextStyle(
                                    fontSize: context.textSizes.s17,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<int> _currentUserCreatedGroupCount() async {
    final user = _user;
    if (user == null) return 0;

    final db = FirebaseFirestore.instance;
    final owned = await db
        .collection('groups')
        .where('ownerId', isEqualTo: user.uid)
        .get();
    final legacyCreated = await db
        .collection('groups')
        .where('createdBy', isEqualTo: user.uid)
        .get();

    return {
      ...owned.docs.map((doc) => doc.id),
      ...legacyCreated.docs.map((doc) => doc.id),
    }.length;
  }

  Future<List<_GroupInviteOption>> _loadFriendOptions(String userId) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    final friendIds = List<String>.from(userDoc.data()?['friends'] ?? const []);
    if (friendIds.isEmpty) return [];

    final users = await _usersByIds(friendIds);
    return friendIds
        .where(users.containsKey)
        .map((friendId) {
          final data = users[friendId]!;
          final username = (data['username'] as String?)?.trim() ?? '';
          final name = (data['name'] as String?)?.trim();
          return _GroupInviteOption(
            userId: friendId,
            name: name?.isNotEmpty == true ? name! : username,
            username: username,
          );
        })
        .where((friend) => friend.username.isNotEmpty || friend.name.isNotEmpty)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?> _findUserByUsername(
    String rawUsername,
  ) async {
    final username = rawUsername.trim().replaceFirst('@', '');
    if (username.isEmpty) return null;

    var snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: username)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty && username != username.toLowerCase()) {
      snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username.toLowerCase())
          .limit(1)
          .get();
    }

    if (snapshot.docs.isEmpty) return null;
    return snapshot.docs.first;
  }

  Future<_InviteResolution> _resolveInviteIds({
    required String ownerId,
    required Set<String> manualUsernames,
    required Set<String> selectedFriendIds,
  }) async {
    final ids = selectedFriendIds.where((id) => id != ownerId).toSet();
    final usernamesById = <String, String>{};
    final missing = <String>[];

    for (final rawUsername in manualUsernames) {
      final username = rawUsername.trim().replaceFirst('@', '');
      if (username.isEmpty) continue;

      final doc = await _findUserByUsername(username);
      if (doc == null) {
        missing.add(username);
        continue;
      }

      if (doc.id == ownerId) continue;
      ids.add(doc.id);
      usernamesById[doc.id] = (doc.data()['username'] as String?) ?? username;
    }

    return _InviteResolution(
      userIds: ids,
      usernamesById: usernamesById,
      missingUsernames: missing,
    );
  }

  Future<void> _showHiddenFriendsSheet(Map<String, dynamic> data) async {
    final hidden = List<String>.from(data['hiddenFriends'] ?? []);
    final controller = TextEditingController();

    await _showSettingsSheet(
      title: 'Hidden Friends',
      child: StatefulBuilder(
        builder: (context, setSheetState) {
          Future<void> saveHidden(List<String> next) async {
            await _updateUserSettings({'hiddenFriends': next});
            setSheetState(() {
              hidden
                ..clear()
                ..addAll(next);
            });
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: controller,
                style: TextStyle(color: _cream),
                decoration: _inputDecoration('Friend username'),
              ),
              SizedBox(height: context.dimensions.values.s12),
              _primarySheetButton(
                label: 'Hide friend',
                onPressed: () async {
                  final username = controller.text.trim().replaceFirst('@', '');
                  if (username.isEmpty) return;

                  final friendDoc = await _findUserByUsername(username);
                  if (friendDoc == null) {
                    _showSnack('Could not find @$username.');
                    return;
                  }

                  final friendIds = List<String>.from(
                    data['friends'] ?? const [],
                  );
                  if (!friendIds.contains(friendDoc.id)) {
                    _showSnack('@$username is not in your friends list.');
                    return;
                  }

                  if (hidden.contains(friendDoc.id)) {
                    controller.clear();
                    return;
                  }
                  await saveHidden([...hidden, friendDoc.id]);
                  controller.clear();
                },
              ),
              SizedBox(height: context.dimensions.values.s16),
              if (hidden.isEmpty)
                Text(
                  'No hidden friends yet.',
                  style: TextStyle(
                    color: _muted,
                    fontSize: context.textSizes.s15,
                  ),
                )
              else
                ...hidden.map(
                  (hiddenFriend) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: FutureBuilder<String>(
                      future: _hiddenFriendLabel(hiddenFriend),
                      builder: (context, snapshot) {
                        return Text(
                          snapshot.data ?? hiddenFriend,
                          style: TextStyle(color: _cream),
                        );
                      },
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.close, color: _muted),
                      onPressed: () async {
                        await saveHidden(
                          hidden.where((item) => item != hiddenFriend).toList(),
                        );
                      },
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<String> _hiddenFriendLabel(String hiddenFriend) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(hiddenFriend)
        .get();
    if (!doc.exists) return hiddenFriend;

    final data = doc.data() ?? {};
    final username = (data['username'] as String?)?.trim();
    if (username?.isNotEmpty == true) return '@$username';

    final name = (data['name'] as String?)?.trim();
    if (name?.isNotEmpty == true) return name!;

    return hiddenFriend;
  }

  Future<void> _showWorkoutTrackingSheet(String currentMode) async {
    final isIos = defaultTargetPlatform == TargetPlatform.iOS;
    final effectiveMode = kDebugMode ? currentMode : 'appleHealth';

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: _background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.dimensions.values.s22),
        ),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              context.dimensions.values.s24,
              context.dimensions.values.s18,
              context.dimensions.values.s24,
              _sheetBottomPadding(context, context.dimensions.values.s28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Workout tracking',
                  style: TextStyle(
                    color: _cream,
                    fontSize: context.textSizes.s22,
                  ),
                ),
                SizedBox(height: context.dimensions.values.s16),
                if (kDebugMode) ...[
                  _trackingModeOption(
                    title: 'Manual entry',
                    subtitle: 'Development only: type calories and minutes.',
                    icon: Icons.edit_note,
                    selected: effectiveMode == 'manual',
                    onTap: () async {
                      await _setWorkoutTrackingMode('manual');
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                      _showManualTrackingPage();
                    },
                  ),
                  SizedBox(height: context.dimensions.values.s12),
                ],
                _trackingModeOption(
                  title: 'Sync Apple Health',
                  subtitle: isIos
                      ? 'Import workout calories and minutes from HealthKit.'
                      : 'Available on iPhone only.',
                  icon: Icons.favorite,
                  selected: effectiveMode == 'appleHealth',
                  enabled: isIos,
                  onTap: isIos
                      ? () async {
                          await _setWorkoutTrackingMode('appleHealth');
                          if (!context.mounted) return;
                          Navigator.of(context).pop();
                          _showAppleHealthTrackingPage();
                        }
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _trackingModeOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required VoidCallback? onTap,
    bool enabled = true,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(context.dimensions.values.s18),
      child: Container(
        padding: EdgeInsets.all(context.dimensions.values.s16),
        decoration: BoxDecoration(
          color: selected ? _selectedSurface : _surface,
          borderRadius: BorderRadius.circular(context.dimensions.values.s18),
          border: Border.all(color: selected ? _accent : _divider),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: context.dimensions.values.s22,
              backgroundColor: enabled ? _accent : _divider,
              child: Icon(
                icon,
                color: _background,
                size: context.dimensions.values.s24,
              ),
            ),
            SizedBox(width: context.dimensions.values.s14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: enabled ? _cream : _muted,
                      fontSize: context.textSizes.s17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: context.dimensions.values.s4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: _muted,
                      fontSize: context.textSizes.s14,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: context.dimensions.values.s10),
            if (selected)
              Icon(Icons.check_circle, color: _accent)
            else
              Icon(Icons.chevron_right, color: enabled ? _muted : _divider),
          ],
        ),
      ),
    );
  }

  Future<void> _setWorkoutTrackingMode(String mode) async {
    if (mode == 'manual' && !kDebugMode) {
      _showSnack('Manual tracking is only available in development.');
      return;
    }

    await _updateUserSettings({'workoutTrackingMode': mode});
    _showSnack(
      mode == 'appleHealth'
          ? 'Apple Health sync selected.'
          : 'Manual tracking selected.',
    );
  }

  String _workoutTrackingModeLabel(String mode) {
    if (!kDebugMode) return 'Apple Health';
    return mode == 'appleHealth' ? 'Apple Health' : 'Manual';
  }

  void _showManualTrackingPage() {
    _pushDetailPage(
      title: 'Manual Tracking',
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          context.dimensions.values.s24,
          context.dimensions.values.s36,
          context.dimensions.values.s24,
          context.dimensions.values.s28,
        ),
        children: [
          Icon(
            Icons.check_circle,
            color: _goalLime,
            size: context.dimensions.values.s54,
          ),
          SizedBox(height: context.dimensions.values.s18),
          Text(
            'Connected to your manual workout log',
            textAlign: TextAlign.center,
            style: TextStyle(color: _cream, fontSize: context.textSizes.s24),
          ),
          SizedBox(height: context.dimensions.values.s16),
          Text(
            'Burn Camp is built around intentional manual entry. Add calories burned and minutes trained after each workout. Your daily totals, goals, alerts, recaps, and leaderboard use those entries.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _muted,
              fontSize: context.textSizes.s18,
              height: 1.35,
            ),
          ),
          SizedBox(height: context.dimensions.values.s34),
          _infoBlock(
            'Today from manual entries',
            'Calories and minutes are summed from every workout you save today.',
          ),
          _infoBlock(
            'Why manual?',
            'No wearable sync is required, and you stay in control of the numbers you log.',
          ),
          _infoBlock(
            'Tip',
            'Set your default workout duration to speed up the add-workout flow.',
          ),
          SizedBox(height: context.dimensions.values.s28),
          _primarySheetButton(
            label: 'Add workout',
            onPressed: _showAddWorkoutSheet,
          ),
        ],
      ),
    );
  }

  void _showAppleHealthTrackingPage() {
    _pushDetailPage(
      title: 'Apple Health',
      child: StatefulBuilder(
        builder: (context, setPageState) {
          return ListView(
            padding: EdgeInsets.fromLTRB(
              context.dimensions.values.s24,
              context.dimensions.values.s36,
              context.dimensions.values.s24,
              context.dimensions.values.s28,
            ),
            children: [
              Icon(
                Icons.favorite,
                color: _accent,
                size: context.dimensions.values.s54,
              ),
              SizedBox(height: context.dimensions.values.s18),
              Text(
                'Apple Health sync',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _cream,
                  fontSize: context.textSizes.s24,
                ),
              ),
              SizedBox(height: context.dimensions.values.s16),
              Text(
                'Burn Camp can read Health app workouts on iPhone and import active calories plus workout duration into your daily totals.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _muted,
                  fontSize: context.textSizes.s18,
                  height: 1.35,
                ),
              ),
              SizedBox(height: context.dimensions.values.s34),
              _infoBlock(
                'What syncs',
                'Workout duration and active energy burned from Apple Health workouts.',
              ),
              _infoBlock(
                'Duplicate safe',
                'HealthKit workout IDs are stored so repeated syncs do not double-count the same workout.',
              ),
              if (kDebugMode)
                _infoBlock(
                  'Manual backup',
                  'Development builds can still add workouts manually for testing.',
                ),
              SizedBox(height: context.dimensions.values.s28),
              _primarySheetButton(
                label: _syncingAppleHealth
                    ? 'Syncing Apple Health...'
                    : 'Connect and sync last 7 days',
                onPressed: _syncingAppleHealth
                    ? () {}
                    : () => _syncAppleHealthWorkouts(setPageState),
              ),
              if (kDebugMode) ...[
                SizedBox(height: context.dimensions.values.s12),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _cream,
                    side: BorderSide(color: _divider),
                    padding: EdgeInsets.symmetric(
                      vertical: context.dimensions.values.s13,
                    ),
                  ),
                  onPressed: _showAddWorkoutSheet,
                  child: Text('Add manual workout'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _syncAppleHealthWorkouts(StateSetter setPageState) async {
    final service = AppleHealthService();
    if (!service.isAvailableOnDevice) {
      _showSnack('Apple Health sync is available on iPhone only.');
      return;
    }

    setPageState(() => _syncingAppleHealth = true);
    setState(() => _syncingAppleHealth = true);

    try {
      final result = await service.importRecentWorkouts();
      if (!mounted) return;
      _showSnack(
        result.importedWorkouts == 0
            ? 'No new Apple Health workouts found.'
            : 'Imported ${result.importedWorkouts} workouts: ${result.calories} cals · ${result.minutes} min.',
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack('Apple Health sync failed: $e');
    } finally {
      if (mounted) {
        setPageState(() => _syncingAppleHealth = false);
        setState(() => _syncingAppleHealth = false);
      }
    }
  }

  void _showManageGroupsPage() {
    final user = _user;
    _pushDetailPage(
      title: 'Manage Groups',
      child: user == null
          ? Center(
              child: Text(
                'Sign in to manage groups.',
                style: TextStyle(color: _muted),
              ),
            )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('groups')
                  .where('memberIds', arrayContains: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                final groups = snapshot.data?.docs ?? [];
                return ListView(
                  padding: EdgeInsets.fromLTRB(
                    context.dimensions.values.s24,
                    context.dimensions.values.s24,
                    context.dimensions.values.s24,
                    context.dimensions.values.s28,
                  ),
                  children: [
                    _primarySheetButton(
                      label: 'Create group',
                      onPressed: _showCreateGroupSheet,
                    ),
                    SizedBox(height: context.dimensions.values.s20),
                    if (groups.isEmpty)
                      Text(
                        'No groups yet. Create one to compare calorie totals with friends.',
                        style: TextStyle(
                          color: _muted,
                          fontSize: context.textSizes.s17,
                        ),
                      )
                    else
                      ...groups.map((doc) {
                        final data = doc.data();
                        final members =
                            (data['memberIds'] as List<dynamic>? ?? const [])
                                .length;
                        return _detailListTile(
                          title: (data['name'] as String?) ?? 'Workout group',
                          subtitle: '$members members',
                          icon: Icons.groups,
                          onTap: () => _showGroupDetailsDialog(doc),
                        );
                      }),
                  ],
                );
              },
            ),
    );
  }

  void _showHelpPage() {
    _pushDetailPage(
      title: 'Help and Feedback',
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          context.dimensions.values.s24,
          context.dimensions.values.s24,
          context.dimensions.values.s24,
          context.dimensions.values.s28,
        ),
        children: [
          _detailListTile(
            title: 'How tracking works',
            subtitle:
                'Calories and minutes are imported from Apple Health workouts on iPhone.',
            icon: Icons.info_outline,
          ),
          _detailListTile(
            title: 'Goals and streaks',
            subtitle:
                'A streak day counts when your logged calories meet your daily goal.',
            icon: Icons.local_fire_department,
          ),
          _detailListTile(
            title: 'Send feedback',
            subtitle: 'Email George.garzon@outlook.com.',
            icon: Icons.feedback_outlined,
            onTap: _emailHelpAndFeedback,
          ),
          SizedBox(height: context.dimensions.values.s18),
          Text(
            'Feedback opens your email app addressed to George.garzon@outlook.com.',
            style: TextStyle(color: _muted, fontSize: context.textSizes.s15),
          ),
        ],
      ),
    );
  }

  void _showSupportPage() {
    _pushDetailPage(
      title: 'Support Burn Camp',
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          context.dimensions.values.s24,
          context.dimensions.values.s36,
          context.dimensions.values.s24,
          context.dimensions.values.s28,
        ),
        children: [
          Icon(
            Icons.local_fire_department,
            color: _accent,
            size: context.dimensions.values.s64,
          ),
          SizedBox(height: context.dimensions.values.s18),
          Text(
            'Enjoy Burn Camp?',
            textAlign: TextAlign.center,
            style: TextStyle(color: _cream, fontSize: context.textSizes.s26),
          ),
          SizedBox(height: context.dimensions.values.s12),
          Text(
            'Support development and unlock a cleaner premium experience as the app grows.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _muted,
              fontSize: context.textSizes.s18,
              height: 1.3,
            ),
          ),
          SizedBox(height: context.dimensions.values.s28),
          _supportPlan('Yearly', '\$12', '\$1/month', 'Best value'),
          _supportPlan('Monthly', '\$2/month', '', ''),
          _supportPlan('Lifetime', '\$25', '', ''),
          SizedBox(height: context.dimensions.values.s18),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Not now',
              style: TextStyle(color: _muted, fontSize: context.textSizes.s18),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoPage({required String title, required String body}) {
    _pushDetailPage(
      title: title,
      child: Padding(
        padding: EdgeInsets.all(context.dimensions.values.s24),
        child: Text(
          body,
          style: TextStyle(
            color: _cream,
            fontSize: context.textSizes.s18,
            height: 1.35,
          ),
        ),
      ),
    );
  }

  Future<void> _emailHelpAndFeedback() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'George.garzon@outlook.com',
      queryParameters: const {'subject': 'Burn Camp help and feedback'},
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    _showSnack('No email app found. Email George.garzon@outlook.com.');
  }

  Future<void> _showWebDrawer({required String title, required String url}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.92,
          child: DashboardWebDrawer(title: title, url: url),
        );
      },
    );
  }

  void _pushDetailPage({required String title, required Widget child}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DashboardDetailPage(title: title, child: child),
      ),
    );
  }

  Widget _infoBlock(String title, String body) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: context.dimensions.values.s16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: _cream, fontSize: context.textSizes.s18),
          ),
          SizedBox(height: context.dimensions.values.s6),
          Text(
            body,
            style: TextStyle(
              color: _muted,
              fontSize: context.textSizes.s15,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailListTile({
    required String title,
    required String subtitle,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: _accent, size: context.dimensions.values.s30),
      title: Text(
        title,
        style: TextStyle(color: _cream, fontSize: context.textSizes.s18),
      ),
      subtitle: Text(subtitle, style: TextStyle(color: _muted)),
      trailing: onTap == null ? null : Icon(Icons.chevron_right, color: _muted),
      onTap: onTap,
    );
  }

  Widget _supportPlan(String title, String price, String right, String badge) {
    return Container(
      margin: EdgeInsets.only(bottom: context.dimensions.values.s16),
      padding: EdgeInsets.symmetric(
        horizontal: context.dimensions.values.s20,
        vertical: context.dimensions.values.s18,
      ),
      decoration: BoxDecoration(
        color: _cream,
        borderRadius: BorderRadius.circular(context.dimensions.values.s16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: _background,
                    fontSize: context.textSizes.s22,
                  ),
                ),
                Text(
                  price,
                  style: TextStyle(
                    color: _selectedSurface,
                    fontSize: context.textSizes.s17,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (right.isNotEmpty)
                Text(
                  right,
                  style: TextStyle(
                    color: _background,
                    fontSize: context.textSizes.s20,
                  ),
                ),
              if (badge.isNotEmpty)
                Text(
                  badge,
                  style: TextStyle(
                    color: _accent,
                    fontSize: context.textSizes.s14,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showChoiceSheet({
    required String title,
    required String currentValue,
    required Map<String, String> options,
    required Future<void> Function(String value) onSelected,
  }) {
    return _showSettingsSheet(
      title: title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: options.entries.map((entry) {
          final selected = entry.key == currentValue;
          return ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(entry.value, style: TextStyle(color: _cream)),
            trailing: selected
                ? Icon(Icons.check, color: _accent)
                : Icon(Icons.chevron_right, color: _muted),
            onTap: () async {
              await onSelected(entry.key);
              if (!mounted) return;
              Navigator.of(context).pop();
            },
          );
        }).toList(),
      ),
    );
  }

  Future<void> _showSettingsSheet({
    required String title,
    required Widget child,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.dimensions.values.s22),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: context.dimensions.values.s24,
            right: context.dimensions.values.s24,
            top: context.dimensions.values.s18,
            bottom: _sheetBottomPadding(context, 28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: _cream,
                  fontSize: context.textSizes.s22,
                ),
              ),
              SizedBox(height: context.dimensions.values.s16),
              child,
            ],
          ),
        );
      },
    );
  }

  Widget _primarySheetButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: context.dimensions.values.s48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent,
          foregroundColor: _onAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.dimensions.values.s14),
          ),
        ),
        onPressed: onPressed,
        child: Text(label, style: TextStyle(fontSize: context.textSizes.s16)),
      ),
    );
  }

  Widget _recapRow(String label, int calories, int minutes) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: context.dimensions.values.s12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: _cream, fontSize: context.textSizes.s17),
            ),
          ),
          Text(
            '${NumberFormat.decimalPattern().format(calories)} cals · $minutes min',
            style: TextStyle(color: _muted, fontSize: context.textSizes.s15),
          ),
        ],
      ),
    );
  }

  Future<void> _updateUserSettings(Map<String, dynamic> values) async {
    final user = _user;
    if (user == null) {
      final prefs = await SharedPreferences.getInstance();
      for (final entry in values.entries) {
        final key = 'settings.${entry.key}';
        final value = entry.value;
        if (value is String) {
          await prefs.setString(key, value);
        } else if (value is int) {
          await prefs.setInt(key, value);
        } else if (value is bool) {
          await prefs.setBool(key, value);
        } else if (value is List<String>) {
          await prefs.setStringList(key, value);
        }
      }
      final goalCalories = values['goalCalories'];
      if (goalCalories is int) {
        await WorkoutService.updateGoalCalories(goalCalories);
      }
      if (mounted) setState(() => _settingsRefresh++);
      return;
    }

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      ...values,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final goalCalories = values['goalCalories'];
    if (goalCalories is int) {
      await WorkoutService.updateGoalCalories(goalCalories);
    }
  }

  Future<Map<String, dynamic>> _localSettingsData() async {
    final prefs = await SharedPreferences.getInstance();
    final onboarding = await OnboardingPreferences.load();
    return {
      'goalCalories':
          prefs.getInt('settings.goalCalories') ??
          (onboarding['goalCalories'] as int?) ??
          500,
      'defaultWorkoutMinutes':
          prefs.getInt('settings.defaultWorkoutMinutes') ?? 30,
      'workoutTrackingMode':
          prefs.getString('settings.workoutTrackingMode') ??
          onboarding['workoutTrackingMode'] as String? ??
          'appleHealth',
      'streakMode': prefs.getString('settings.streakMode') ?? 'strict',
      'themeMode': prefs.getString('settings.themeMode') ?? 'dark',
      'hiddenFriends': prefs.getStringList('settings.hiddenFriends') ?? [],
    };
  }

  Future<void> _signInFromSettings() async {
    try {
      await AuthService().signInWithGoogle();
      await OnboardingPreferences.syncToCurrentUser();
      await _syncLocalSettingsToCurrentUser();
      if (!mounted) return;
      setState(() {});
      _showSnack('Signed in. Your Burn Camp settings can now sync.');
    } catch (e) {
      _showSnack('Sign in failed: $e');
    }
  }

  Future<void> _syncLocalSettingsToCurrentUser() async {
    final user = _user;
    if (user == null) return;

    final settings = await _localSettingsData();
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      ...settings,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _resetPersonalization() async {
    await OnboardingPreferences.reset();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      (_) => false,
    );
  }

  Future<void> _logout() async {
    try {
      final googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.disconnect();
        await googleSignIn.signOut();
      }
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      _showSnack('Sign out failed: $e');
      return;
    }

    if (!mounted) return;
    setState(() {});
    _showSnack('Signed out of Google.');
  }
}
