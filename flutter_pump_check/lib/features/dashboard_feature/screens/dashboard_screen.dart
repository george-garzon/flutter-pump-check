import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pump_check/services/workout_service.dart';
import 'package:flutter_pump_check/theme/app_theme_mode.dart';
import 'package:flutter_pump_check/theme/claude_palette.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

enum MetricPeriod { today, yesterday, week, month }

enum HistoryRange { day, week, month, calendar }

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const _accent = ClaudePalette.accent;
  static const _goalLime = ClaudePalette.goal;

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
  Color get _onAccent => ClaudePalette.charcoal;

  int _selectedIndex = 0;
  MetricPeriod _period = MetricPeriod.today;
  HistoryRange _historyRange = HistoryRange.week;
  bool _historyShowsAverage = true;
  bool _showFriends = true;

  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final screens = [
      _homeTab(),
      _historyTab(),
      _socialTab(),
      _activityTab(),
      _settingsTab(),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _selectedIndex, children: screens),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        backgroundColor: _surface,
        selectedItemColor: _accent,
        unselectedItemColor: _cream,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        iconSize: 29,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: ''),
          BottomNavigationBarItem(
            icon: Icon(Icons.insert_chart_outlined),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: '',
          ),
        ],
      ),
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
              leading: IconButton(
                icon: Icon(Icons.ios_share, color: _cream, size: 27),
                onPressed: () {
                  Share.share(
                    'I burned ${aggregate.calories} calories and trained ${aggregate.minutes} minutes in Burn Camp.',
                  );
                },
              ),
              trailing: IconButton(
                icon: Icon(Icons.add, color: _cream, size: 32),
                onPressed: _showAddWorkoutSheet,
              ),
              bottom: _periodTabs(),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => setState(() {}),
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    SizedBox(height: 26),
                    Text(
                      _metricLabel(_period),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _cream, fontSize: 20),
                    ),
                    SizedBox(height: 10),
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
                              fontSize: 68,
                              fontWeight: FontWeight.w300,
                              height: 0.95,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.chevron_right,
                            color: _muted,
                            size: 44,
                          ),
                          onPressed: () => setState(() => _selectedIndex = 1),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text(
                      _minutesLabel(aggregate, _period),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _cream, fontSize: 20),
                    ),
                    SizedBox(height: 28),
                    _leaderboardToggle(),
                    SizedBox(height: 18),
                    _leaderboard(aggregate),
                    SizedBox(height: 30),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: _onAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _showAddWorkoutSheet,
                          child: Text(
                            aggregate.calories == 0
                                ? 'Add today’s workout'
                                : 'Add another workout',
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _historyTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: WorkoutService.watchSummaries(limit: 180),
      builder: (context, snapshot) {
        final summaries = snapshot.data ?? [];
        final longestStreak = _longestStreak(summaries);
        final bestWeek = _bestWindow(summaries, const Duration(days: 7));
        final bestMonth = _bestMonth(summaries);

        return Column(
          children: [
            _topHeader(
              title: 'History',
              leading: IconButton(
                icon: Icon(Icons.history, color: _cream, size: 28),
                onPressed: () {},
              ),
              trailing: IconButton(
                tooltip: _historyShowsAverage
                    ? 'Show total calories'
                    : 'Show average calories',
                icon: Icon(
                  _historyShowsAverage
                      ? Icons.bar_chart
                      : Icons.format_list_numbered,
                  color: _cream,
                  size: 30,
                ),
                onPressed: () {
                  setState(() => _historyShowsAverage = !_historyShowsAverage);
                },
              ),
              bottom: Padding(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
                child: Column(
                  children: [
                    _summaryLine(
                      'Daily goal:',
                      '${_goalCaloriesFromCachedSummaries(summaries)} cals',
                      valueColor: _goalLime,
                      icon: Icons.edit,
                      onTap: _showGoalSheet,
                    ),
                    _summaryLine('Longest streak:', '$longestStreak days'),
                    _summaryLine('Best week:', bestWeek),
                    _summaryLine('Best month:', bestMonth),
                    SizedBox(height: 12),
                    _historyTabs(),
                  ],
                ),
              ),
            ),
            Expanded(child: _historyContent(summaries)),
          ],
        );
      },
    );
  }

  Widget _socialTab() {
    return Column(
      children: [
        _topHeader(
          title: 'Chats',
          leading: SizedBox(width: 48),
          trailing: IconButton(
            icon: Icon(Icons.person_add_alt, color: _cream, size: 28),
            onPressed: _inviteFriends,
          ),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 38),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.forum_outlined, color: _muted, size: 74),
                  SizedBox(height: 26),
                  Text(
                    'Tap on a friend from the leaderboard to send them a cheer, challenge, or note. Those conversations will show up here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _muted, fontSize: 21, height: 1.25),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _activityTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: WorkoutService.watchSummaries(limit: 60),
      builder: (context, snapshot) {
        final summaries = snapshot.data ?? [];
        return Column(
          children: [
            _topHeader(
              title: 'Alerts',
              leading: SizedBox(width: 48),
              trailing: IconButton(
                icon: Icon(Icons.ios_share, color: _cream, size: 27),
                onPressed: () {
                  Share.share(
                    'Burn Camp keeps me accountable for calories burned and workout minutes.',
                  );
                },
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                children: _alertItems(summaries),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _alertItems(List<Map<String, dynamic>> summaries) {
    if (summaries.isEmpty) {
      return [
        SizedBox(height: 160),
        Icon(Icons.notifications_none, color: _muted, size: 70),
        SizedBox(height: 18),
        Text(
          'Your workout recaps, goal streaks, and calorie trends will show up here.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _muted, fontSize: 19),
        ),
      ];
    }

    final week = _aggregateForPeriod(summaries, MetricPeriod.week);
    final month = _aggregateForPeriod(summaries, MetricPeriod.month);
    final bestDay = summaries.reduce((a, b) {
      return WorkoutService.caloriesFromSummary(a) >=
              WorkoutService.caloriesFromSummary(b)
          ? a
          : b;
    });

    return [
      _alertTile(
        'You burned ${NumberFormat.decimalPattern().format(week.calories)} calories this week across ${week.minutes} workout minutes.',
        'Now',
      ),
      _alertTile(
        'This month you have logged ${NumberFormat.decimalPattern().format(month.calories)} calories burned.',
        DateFormat.yMMMd().format(DateTime.now()),
      ),
      _alertTile(
        'Best logged day: ${NumberFormat.decimalPattern().format(WorkoutService.caloriesFromSummary(bestDay))} calories and ${WorkoutService.minutesFromSummary(bestDay)} minutes.',
        _friendlyDate(bestDay),
      ),
      _alertTile(
        'Tip: update Default workout duration in Settings to make manual entry faster.',
        'Settings',
      ),
    ];
  }

  Widget _alertTile(String message, String dateLabel) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _divider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.show_chart, color: _accent, size: 44),
          SizedBox(width: 22),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(color: _cream, fontSize: 20, height: 1.2),
                ),
                SizedBox(height: 8),
                Text(dateLabel, style: TextStyle(color: _muted, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsTab() {
    final user = _user;
    if (user == null) {
      return Center(
        child: Text('Not signed in', style: TextStyle(color: _cream)),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? {};
        final name = (data['name'] as String?)?.trim();
        final goal = _goalCalories(data);
        final defaultMinutes =
            (data['defaultWorkoutMinutes'] as num?)?.toInt() ?? 30;
        final streakMode = (data['streakMode'] as String?) ?? 'strict';
        final themeMode = (data['themeMode'] as String?) ?? 'dark';
        final notificationsEnabled = data['notificationsEnabled'] != false;
        final hiddenFriends =
            (data['hiddenFriends'] as List<dynamic>? ?? const []).length;

        return Column(
          children: [
            _topHeader(
              title: 'Settings',
              leading: const SizedBox(width: 48),
              trailing: const SizedBox(width: 48),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 32),
                  _settingsRow(
                    'Manual workout tracking',
                    'Connected',
                    onTap: _showManualTrackingPage,
                  ),
                  _settingsRow(
                    'Daily calorie goal',
                    '$goal',
                    onTap: _showGoalSheet,
                  ),
                  _settingsRow(
                    'Default workout duration',
                    '$defaultMinutes min',
                    onTap: () => _showDefaultDurationSheet(defaultMinutes),
                  ),
                  _settingsRow(
                    'Streak mode',
                    _streakModeLabel(streakMode),
                    onTap: () => _showStreakModeSheet(streakMode),
                  ),
                  _settingsRow(
                    'Theme',
                    themeModeLabel(themeMode),
                    onTap: () => _showThemeModeSheet(themeMode),
                  ),
                  _settingsRow(
                    'Notifications',
                    notificationsEnabled ? 'On' : 'Off',
                    onTap: () => _toggleNotifications(notificationsEnabled),
                  ),
                  SizedBox(height: 28, child: ColoredBox(color: _surface)),
                  _settingsRow(
                    'Update profile',
                    name?.isNotEmpty == true ? name! : 'Profile',
                    onTap: () => _showProfileSheet(data),
                  ),
                  _settingsRow('Recaps', 'View', onTap: _showRecapsSheet),
                  _settingsRow(
                    'Invite friends',
                    'Share',
                    onTap: _inviteFriends,
                  ),
                  _settingsRow(
                    'Hidden friends',
                    '$hiddenFriends',
                    onTap: () => _showHiddenFriendsSheet(data),
                  ),
                  _settingsRow(
                    'Manage groups',
                    '',
                    onTap: _showManageGroupsPage,
                  ),
                  SizedBox(height: 28, child: ColoredBox(color: _surface)),
                  _settingsRow('Help and feedback', '', onTap: _showHelpPage),
                  _settingsRow(
                    'Support Burn Camp',
                    'Premium',
                    onTap: _showSupportPage,
                  ),
                  _settingsRow(
                    'Instagram',
                    '@burncamp',
                    onTap: () =>
                        _showSnack('Social links are placeholders for now.'),
                  ),
                  _settingsRow(
                    'TikTok',
                    '@burncamp',
                    onTap: () =>
                        _showSnack('Social links are placeholders for now.'),
                  ),
                  SizedBox(height: 28, child: ColoredBox(color: _surface)),
                  _settingsRow(
                    'Privacy',
                    '',
                    onTap: () => _showInfoPage(
                      title: 'Privacy',
                      body:
                          'Burn Camp stores workout entries, goals, and settings in your account so your calorie history can sync across devices.',
                    ),
                  ),
                  _settingsRow(
                    'Terms',
                    '',
                    onTap: () => _showInfoPage(
                      title: 'Terms',
                      body:
                          'Burn Camp is for personal fitness tracking and friendly accountability. Manually entered workouts should reflect your best estimate.',
                    ),
                  ),
                  SizedBox(height: 22),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _cream,
                        side: BorderSide(color: _divider),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      onPressed: _logout,
                      child: Text('Log out', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  SizedBox(height: 22),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _topHeader({
    required String title,
    required Widget leading,
    required Widget trailing,
    Widget? bottom,
  }) {
    return Column(
      children: [
        SizedBox(
          height: 86,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                SizedBox(width: 56, child: Center(child: leading)),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        color: _cream,
                        size: 24,
                      ),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _cream,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 56, child: Center(child: trailing)),
              ],
            ),
          ),
        ),
        if (bottom != null) bottom,
      ],
    );
  }

  Widget _periodTabs() {
    const tabs = [
      (MetricPeriod.today, 'Today'),
      (MetricPeriod.yesterday, 'Yesterday'),
      (MetricPeriod.week, 'Week'),
      (MetricPeriod.month, 'Month'),
    ];

    return SizedBox(
      height: 54,
      child: Row(
        children: tabs.map((tab) {
          final selected = _period == tab.$1;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: selected
                      ? _selectedSurface
                      : Colors.transparent,
                  foregroundColor: _cream,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => setState(() => _period = tab.$1),
                child: Text(tab.$2, style: TextStyle(fontSize: 16)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _historyTabs() {
    const tabs = [
      (HistoryRange.day, 'Day'),
      (HistoryRange.week, 'Week'),
      (HistoryRange.month, 'Month'),
      (HistoryRange.calendar, '▦'),
    ];
    return SizedBox(
      height: 46,
      child: Row(
        children: tabs.map((tab) {
          final selected = _historyRange == tab.$1;
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => _historyRange = tab.$1),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: selected ? _selectedSurface : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  tab.$2,
                  style: TextStyle(
                    color: _cream,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _historyContent(List<Map<String, dynamic>> summaries) {
    if (summaries.isEmpty &&
        _historyRange != HistoryRange.month &&
        _historyRange != HistoryRange.calendar) {
      return Center(
        child: Text(
          'No workouts logged yet.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _muted, fontSize: 17),
        ),
      );
    }

    switch (_historyRange) {
      case HistoryRange.day:
        return _dayHistoryContent(summaries);
      case HistoryRange.week:
        return _weekHistoryContent(summaries);
      case HistoryRange.month:
        return _monthHistoryContent(summaries);
      case HistoryRange.calendar:
        return _calendarHistoryContent(summaries);
    }
  }

  Widget _dayHistoryContent(List<Map<String, dynamic>> summaries) {
    final summariesByMondayWeek = <DateTime, List<Map<String, dynamic>>>{};
    var earliestYear = DateTime.now().year;
    for (final summary in summaries) {
      final date = _dateFromSummary(summary);
      if (date == null) continue;
      earliestYear = math.min(earliestYear, date.year);
      final week = WorkoutService.startOfWeek(date);
      summariesByMondayWeek.putIfAbsent(week, () => []).add(summary);
    }

    final now = WorkoutService.startOfDay(DateTime.now());
    final months = _historyMonthsThroughCurrent(earliestYear);

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
      children: _dayHistoryRows(months, summariesByMondayWeek, now),
    );
  }

  Widget _weekHistoryContent(List<Map<String, dynamic>> summaries) {
    final summariesByMondayWeek = <DateTime, List<Map<String, dynamic>>>{};
    var earliestYear = DateTime.now().year;
    for (final summary in summaries) {
      final date = _dateFromSummary(summary);
      if (date == null) continue;
      earliestYear = math.min(earliestYear, date.year);
      final week = WorkoutService.startOfWeek(date);
      summariesByMondayWeek.putIfAbsent(week, () => []).add(summary);
    }

    final now = WorkoutService.startOfDay(DateTime.now());
    final months = _historyMonthsThroughCurrent(earliestYear);

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
      children: _weekHistoryRows(months, summariesByMondayWeek, now),
    );
  }

  List<Widget> _dayHistoryRows(
    List<DateTime> months,
    Map<DateTime, List<Map<String, dynamic>>> summariesByMondayWeek,
    DateTime today,
  ) {
    final rows = <Widget>[];

    for (final month in months) {
      final mondayWeeks = _mondayWeeksForMonth(month, today);
      final monthSummaries = mondayWeeks
          .expand(
            (week) =>
                summariesByMondayWeek[week] ?? const <Map<String, dynamic>>[],
          )
          .toList();

      rows
        ..add(
          _historySectionHeader(
            DateFormat.MMMM().format(month),
            _formatHistoryValue(
              _sumCalories(monthSummaries),
              _distinctDays(monthSummaries),
            ),
          ),
        )
        ..add(SizedBox(height: 14));

      if (mondayWeeks.isEmpty) {
        rows
          ..add(Text('No data', style: TextStyle(color: _muted, fontSize: 18)))
          ..add(const SizedBox(height: 18));
        continue;
      }

      for (final week in mondayWeeks) {
        final weekSummaries =
            [...(summariesByMondayWeek[week] ?? const <Map<String, dynamic>>[])]
              ..sort((a, b) {
                final aDate = _dateFromSummary(a) ?? DateTime(1970);
                final bDate = _dateFromSummary(b) ?? DateTime(1970);
                return bDate.compareTo(aDate);
              });

        rows
          ..add(
            _historySectionHeader(
              'Week of ${DateFormat.Md().format(week)}',
              _formatHistoryValue(
                _sumCalories(weekSummaries),
                _distinctDays(weekSummaries),
              ),
            ),
          )
          ..add(SizedBox(height: 12));

        if (weekSummaries.isEmpty) {
          rows
            ..add(
              Text('No data', style: TextStyle(color: _muted, fontSize: 18)),
            )
            ..add(const SizedBox(height: 14));
        } else {
          rows
            ..addAll(weekSummaries.map(_historyBar))
            ..add(const SizedBox(height: 14));
        }
      }

      rows.add(const SizedBox(height: 18));
    }

    return rows;
  }

  List<Widget> _weekHistoryRows(
    List<DateTime> months,
    Map<DateTime, List<Map<String, dynamic>>> summariesByMondayWeek,
    DateTime today,
  ) {
    final rows = <Widget>[];

    for (final month in months) {
      final mondayWeeks = _mondayWeeksForMonth(month, today);
      final monthSummaries = mondayWeeks
          .expand(
            (week) =>
                summariesByMondayWeek[week] ?? const <Map<String, dynamic>>[],
          )
          .toList();

      rows
        ..add(
          _historySectionHeader(
            DateFormat.MMMM().format(month),
            _formatHistoryValue(
              _sumCalories(monthSummaries),
              _distinctDays(monthSummaries),
            ),
          ),
        )
        ..add(SizedBox(height: 14));

      if (mondayWeeks.isEmpty) {
        rows
          ..add(Text('No data', style: TextStyle(color: _muted, fontSize: 18)))
          ..add(const SizedBox(height: 18));
        continue;
      }

      for (final week in mondayWeeks) {
        rows
          ..add(_weekBar(week, summariesByMondayWeek[week] ?? const []))
          ..add(const SizedBox(height: 14));
      }

      rows.add(const SizedBox(height: 18));
    }

    return rows;
  }

  Widget _monthHistoryContent(List<Map<String, dynamic>> summaries) {
    final groups = <DateTime, List<Map<String, dynamic>>>{};
    var earliestYear = DateTime.now().year;
    for (final summary in summaries) {
      final date = _dateFromSummary(summary);
      if (date == null) continue;
      earliestYear = math.min(earliestYear, date.year);
      final month = DateTime(date.year, date.month);
      groups.putIfAbsent(month, () => []).add(summary);
    }

    final allMonths = _historyMonthsThroughCurrent(earliestYear);

    final maxValue = allMonths.fold<int>(
      1,
      (maxValue, month) => math.max(
        maxValue,
        _historyValueForSummaries(groups[month] ?? const []),
      ),
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
      children: _monthHistoryRows(allMonths, groups, maxValue),
    );
  }

  List<Widget> _monthHistoryRows(
    List<DateTime> allMonths,
    Map<DateTime, List<Map<String, dynamic>>> groups,
    int maxValue,
  ) {
    final rows = <Widget>[];
    int? currentYear;

    for (final month in allMonths) {
      if (currentYear != month.year) {
        currentYear = month.year;
        final yearSummaries = allMonths
            .where((item) => item.year == month.year)
            .expand((item) => groups[item] ?? const <Map<String, dynamic>>[])
            .toList();
        rows
          ..add(
            _historySectionHeader(
              '${month.year}',
              _formatHistoryValue(
                _sumCalories(yearSummaries),
                _distinctDays(yearSummaries),
              ),
            ),
          )
          ..add(const SizedBox(height: 14));
      }

      rows.add(
        _monthBar(
          DateFormat.MMM().format(month),
          groups[month] ?? const [],
          maxValue,
        ),
      );
    }

    return rows;
  }

  Widget _calendarHistoryContent(List<Map<String, dynamic>> summaries) {
    final byDate = <DateTime, Map<String, dynamic>>{};
    for (final summary in summaries) {
      final date = _dateFromSummary(summary);
      if (date == null) continue;
      byDate[date] = summary;
    }

    final now = DateTime.now();
    final months = [
      DateTime(now.year, now.month),
      DateTime(now.year, now.month - 1),
      DateTime(now.year, now.month - 2),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
      children: [
        for (final month in months) ...[
          _calendarMonth(month, byDate),
          SizedBox(height: 30),
        ],
      ],
    );
  }

  Widget _historySectionHeader(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: _cream, fontSize: 23)),
        Text(value, style: TextStyle(color: _muted, fontSize: 18)),
      ],
    );
  }

  Widget _weekBar(DateTime week, List<Map<String, dynamic>> summaries) {
    final calories = _sumCalories(summaries);
    final minutes = _sumMinutes(summaries);
    final value = _historyValueForSummaries(summaries);
    final widthFactor = value == 0
        ? 0.0
        : math.max(0.12, math.min(1.0, value / 1000));

    return _periodBar(
      label: DateFormat.Md().format(week),
      valueText: calories == 0
          ? 'No data'
          : _formatHistoryValue(
              calories,
              _distinctDays(summaries),
              compact: false,
            ),
      subtitle: '$minutes min trained',
      widthFactor: widthFactor,
      hasData: calories > 0,
    );
  }

  Widget _monthBar(
    String label,
    List<Map<String, dynamic>> summaries,
    int maxValue,
  ) {
    final calories = _sumCalories(summaries);
    final minutes = _sumMinutes(summaries);
    final value = _historyValueForSummaries(summaries);
    final widthFactor = value == 0
        ? 0.0
        : math.max(0.12, math.min(1.0, value / maxValue));

    return _periodBar(
      label: label,
      valueText: calories == 0
          ? 'No data'
          : _formatHistoryValue(
              calories,
              _distinctDays(summaries),
              compact: false,
            ),
      subtitle: '$minutes min trained',
      widthFactor: widthFactor,
      hasData: calories > 0,
    );
  }

  Widget _periodBar({
    required String label,
    required String valueText,
    required String subtitle,
    required double widthFactor,
    required bool hasData,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            child: Text(label, style: TextStyle(color: _muted, fontSize: 18)),
          ),
          Expanded(
            child: !hasData
                ? Text(valueText, style: TextStyle(color: _muted, fontSize: 18))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FractionallySizedBox(
                        widthFactor: widthFactor,
                        child: Container(
                          height: 42,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: _accent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            valueText,
                            style: TextStyle(
                              color: _background,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(color: _muted, fontSize: 13),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _calendarMonth(
    DateTime month,
    Map<DateTime, Map<String, dynamic>> byDate,
  ) {
    final firstDay = DateTime(month.year, month.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingBlanks = firstDay.weekday - DateTime.monday;
    final totalCells = leadingBlanks + daysInMonth;
    final trailingBlanks = (7 - totalCells % 7) % 7;

    final monthSummaries = byDate.entries
        .where(
          (entry) =>
              entry.key.year == month.year && entry.key.month == month.month,
        )
        .map((entry) => entry.value)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _historySectionHeader(
          DateFormat.yMMMM().format(month),
          _formatHistoryValue(
            _sumCalories(monthSummaries),
            _distinctDays(monthSummaries),
            compact: true,
          ),
        ),
        const SizedBox(height: 14),
        const Row(
          children: [
            _WeekdayLabel('M'),
            _WeekdayLabel('T'),
            _WeekdayLabel('W'),
            _WeekdayLabel('T'),
            _WeekdayLabel('F'),
            _WeekdayLabel('S'),
            _WeekdayLabel('S'),
          ],
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 0.95,
          children: [
            for (var i = 0; i < leadingBlanks; i++) const SizedBox.shrink(),
            for (var day = 1; day <= daysInMonth; day++)
              _calendarDay(DateTime(month.year, month.month, day), byDate),
            for (var i = 0; i < trailingBlanks; i++) const SizedBox.shrink(),
          ],
        ),
      ],
    );
  }

  Widget _calendarDay(
    DateTime date,
    Map<DateTime, Map<String, dynamic>> byDate,
  ) {
    final summary = byDate[date];
    final calories = WorkoutService.caloriesFromSummary(summary);
    final isToday = date == WorkoutService.startOfDay(DateTime.now());

    return Container(
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isToday ? _selectedSurface : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            calories > 0 ? NumberFormat.compact().format(calories) : '',
            style: TextStyle(
              color: calories > 0 ? _accent : _muted,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text('${date.day}', style: TextStyle(color: _muted, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _leaderboardToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 44,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: _showFriends ? _accent : Colors.transparent,
                  foregroundColor: _showFriends ? _cream : _accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => setState(() => _showFriends = true),
                child: Text('Friends', style: TextStyle(fontSize: 17)),
              ),
            ),
          ),
          SizedBox(width: 24),
          Expanded(
            child: SizedBox(
              height: 44,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: !_showFriends ? _accent : Colors.transparent,
                  foregroundColor: !_showFriends ? _cream : _accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => setState(() => _showFriends = false),
                child: const Text('Groups', style: TextStyle(fontSize: 17)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _leaderboard(_MetricAggregate aggregate) {
    if (!_showFriends) {
      return Column(
        children: [
          _rankRow(
            rank: 1,
            icon: Icons.groups,
            name: 'Your group',
            value: aggregate.calories,
            subtitle: '${aggregate.minutes} min trained',
          ),
          _rankRow(
            rank: 2,
            icon: Icons.group_outlined,
            name: 'Create a group',
            value: 0,
            subtitle: 'Invite friends to compete',
          ),
        ],
      );
    }

    final user = _user;
    final displayName = user?.displayName?.trim();
    return Column(
      children: [
        _rankRow(
          rank: 1,
          icon: Icons.person,
          name: displayName?.isNotEmpty == true ? displayName! : 'You',
          value: aggregate.calories,
          subtitle: aggregate.calories > 0
              ? 'now · ${aggregate.minutes} min'
              : 'no workout yet',
        ),
        _rankRow(
          rank: 2,
          icon: Icons.local_fire_department,
          name: 'Active Bot',
          value: _botValue(aggregate.calories, 1.25),
          subtitle: 'sample competitor',
        ),
        _rankRow(
          rank: 3,
          icon: Icons.directions_run,
          name: 'Chill Bot',
          value: _botValue(aggregate.calories, 0.82),
          subtitle: 'sample competitor',
        ),
      ],
    );
  }

  Widget _rankRow({
    required int rank,
    required IconData icon,
    required String name,
    required int value,
    required String subtitle,
  }) {
    final medalColors = {
      1: Colors.amber,
      2: Colors.grey.shade300,
      3: Colors.brown.shade400,
    };

    return Container(
      height: 78,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _divider)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            child: Center(
              child: rank <= 3
                  ? Icon(Icons.emoji_events, color: medalColors[rank], size: 22)
                  : Text(
                      '$rank',
                      style: TextStyle(color: _cream, fontSize: 18),
                    ),
            ),
          ),
          CircleAvatar(
            radius: 23,
            backgroundColor: _accent,
            child: Icon(icon, color: _background, size: 26),
          ),
          SizedBox(width: 24),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: _cream, fontSize: 21),
            ),
          ),
          SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                NumberFormat.decimalPattern().format(value),
                style: TextStyle(color: _cream, fontSize: 21),
              ),
              Text(subtitle, style: TextStyle(color: _muted, fontSize: 13)),
            ],
          ),
          SizedBox(width: 24),
        ],
      ),
    );
  }

  Widget _historyBar(Map<String, dynamic> summary) {
    final calories = WorkoutService.caloriesFromSummary(summary);
    final minutes = WorkoutService.minutesFromSummary(summary);
    final value = _historyValueForSummaries([summary]);
    final maxWidth = math.max(0.22, math.min(1.0, value / 1000));
    final label = _friendlyDate(summary);

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            child: Text(label, style: TextStyle(color: _muted, fontSize: 16)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FractionallySizedBox(
                  widthFactor: maxWidth,
                  child: Container(
                    height: 42,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: _accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _formatHistoryValue(
                        calories,
                        1,
                        compact: false,
                        includeUnit: false,
                      ),
                      style: TextStyle(
                        color: _background,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 5),
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
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Text(label, style: TextStyle(color: _cream, fontSize: 20)),
            const Spacer(),
            if (icon != null) ...[
              Icon(icon, color: resolvedValueColor, size: 20),
              SizedBox(width: 10),
            ],
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: resolvedValueColor, fontSize: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsRow(String label, String value, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: _surface)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: TextStyle(color: _cream, fontSize: 20)),
            ),
            if (value.isNotEmpty)
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: _muted, fontSize: 20),
                ),
              ),
            SizedBox(width: 8),
            Icon(Icons.chevron_right, color: _muted, size: 26),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddWorkoutSheet() async {
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
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
                left: 24,
                right: 24,
                top: 18,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
                          style: TextStyle(color: _cream, fontSize: 22),
                        ),
                      ),
                      TextButton(
                        onPressed: saving ? null : save,
                        child: Text(
                          'Save',
                          style: TextStyle(color: _accent, fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14),
                  _darkNumberField(
                    controller: caloriesController,
                    label: 'Calories burned',
                    suffix: 'cals',
                  ),
                  SizedBox(height: 12),
                  _darkNumberField(
                    controller: minutesController,
                    label: 'Minutes trained',
                    suffix: 'min',
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    style: TextStyle(color: _cream),
                    decoration: _inputDecoration('Notes optional'),
                  ),
                  SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _cream,
                      side: BorderSide(color: _surface),
                      padding: const EdgeInsets.symmetric(vertical: 12),
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
                  SizedBox(height: 16),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: _onAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: saving ? null : save,
                      child: saving
                          ? CircularProgressIndicator(color: _cream)
                          : Text(
                              'Save workout',
                              style: TextStyle(fontSize: 17),
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
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    var goal = _goalCalories(doc.data() ?? {});

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: _background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> save() async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .set({
                    'goalCalories': goal,
                    'updatedAt': FieldValue.serverTimestamp(),
                  }, SetOptions(merge: true));

              if (!context.mounted) return;
              Navigator.of(context).pop();
            }

            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 34),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Daily Calorie Goal',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: _cream, fontSize: 21),
                        ),
                      ),
                      TextButton(
                        onPressed: save,
                        child: Text(
                          'Done',
                          style: TextStyle(color: _accent, fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Text(
                    NumberFormat.decimalPattern().format(goal),
                    style: TextStyle(
                      color: _goalLime,
                      fontSize: 52,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  SizedBox(height: 18),
                  Container(
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.remove, color: _cream, size: 26),
                          onPressed: () {
                            setSheetState(() => goal = math.max(50, goal - 50));
                          },
                        ),
                        Container(width: 1, height: 28, color: _muted),
                        IconButton(
                          icon: Icon(Icons.add, color: _cream, size: 26),
                          onPressed: () => setSheetState(() => goal += 50),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Set the calorie target you want to hit each training day. Streaks count days where this goal is met.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _cream, fontSize: 16),
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
          const SizedBox(height: 16),
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

  Future<void> _toggleNotifications(bool currentlyEnabled) async {
    final enabled = !currentlyEnabled;
    await _updateUserSettings({'notificationsEnabled': enabled});
    _showSnack(
      enabled ? 'Notifications turned on.' : 'Notifications turned off.',
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

    await _showSettingsSheet(
      title: 'Update Profile',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: nameController,
            style: TextStyle(color: _cream),
            decoration: _inputDecoration('Display name'),
          ),
          SizedBox(height: 12),
          TextField(
            controller: usernameController,
            style: TextStyle(color: _cream),
            decoration: _inputDecoration('Username'),
          ),
          SizedBox(height: 16),
          _primarySheetButton(
            label: 'Save profile',
            onPressed: () async {
              final name = nameController.text.trim();
              final username = usernameController.text.trim();
              if (name.isEmpty || username.isEmpty) {
                _showSnack('Name and username are required.');
                return;
              }

              await user.updateDisplayName(name);
              await _updateUserSettings({'name': name, 'username': username});

              if (!mounted) return;
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showRecapsSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: _background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
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
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Recaps', style: TextStyle(color: _cream, fontSize: 22)),
                  SizedBox(height: 16),
                  _recapRow('Today', today.calories, today.minutes),
                  _recapRow('This week', week.calories, week.minutes),
                  _recapRow('This month', month.calories, month.minutes),
                  _recapRow('All time', lifetimeCalories, lifetimeMinutes),
                  SizedBox(height: 16),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _cream,
                      side: BorderSide(color: _divider),
                    ),
                    onPressed: () {
                      Share.share(
                        'Burn Camp recap: ${NumberFormat.decimalPattern().format(month.calories)} calories and ${month.minutes} minutes trained this month.',
                      );
                    },
                    icon: const Icon(Icons.ios_share),
                    label: const Text('Share monthly recap'),
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
    await Share.share(
      'Join me on Burn Camp — track calories burned, training minutes, and compare workouts with friends.',
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
              SizedBox(height: 12),
              _primarySheetButton(
                label: 'Hide friend',
                onPressed: () async {
                  final username = controller.text.trim();
                  if (username.isEmpty) return;
                  if (hidden.contains(username)) {
                    controller.clear();
                    return;
                  }
                  await saveHidden([...hidden, username]);
                  controller.clear();
                },
              ),
              SizedBox(height: 16),
              if (hidden.isEmpty)
                Text(
                  'No hidden friends yet.',
                  style: TextStyle(color: _muted, fontSize: 15),
                )
              else
                ...hidden.map(
                  (username) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(username, style: TextStyle(color: _cream)),
                    trailing: IconButton(
                      icon: Icon(Icons.close, color: _muted),
                      onPressed: () async {
                        await saveHidden(
                          hidden.where((item) => item != username).toList(),
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

  void _showManualTrackingPage() {
    _pushDetailPage(
      title: 'Manual Tracking',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
        children: [
          Icon(Icons.check_circle, color: _goalLime, size: 54),
          SizedBox(height: 18),
          Text(
            'Connected to your manual workout log',
            textAlign: TextAlign.center,
            style: TextStyle(color: _cream, fontSize: 24),
          ),
          SizedBox(height: 16),
          Text(
            'Burn Camp is built around intentional manual entry. Add calories burned and minutes trained after each workout. Your daily totals, goals, alerts, recaps, and leaderboard use those entries.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 18, height: 1.35),
          ),
          const SizedBox(height: 34),
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
          SizedBox(height: 28),
          _primarySheetButton(
            label: 'Add workout',
            onPressed: _showAddWorkoutSheet,
          ),
        ],
      ),
    );
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
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                  children: [
                    _primarySheetButton(
                      label: 'Create group',
                      onPressed: () => _showSnack(
                        'Group creation screen can be connected next.',
                      ),
                    ),
                    SizedBox(height: 20),
                    if (groups.isEmpty)
                      Text(
                        'No groups yet. Create one to compare calorie totals with friends.',
                        style: TextStyle(color: _muted, fontSize: 17),
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
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
        children: [
          _detailListTile(
            title: 'How tracking works',
            subtitle:
                'Calories and minutes are entered manually after each workout.',
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
            subtitle: 'Share what should be improved next.',
            icon: Icons.feedback_outlined,
            onTap: () => Share.share('Burn Camp feedback: '),
          ),
          SizedBox(height: 18),
          Text(
            'Support note: this screen is local for now. Hook it to email, a feedback form, or your support inbox when ready.',
            style: TextStyle(color: _muted, fontSize: 15),
          ),
        ],
      ),
    );
  }

  void _showSupportPage() {
    _pushDetailPage(
      title: 'Support Burn Camp',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
        children: [
          Icon(Icons.local_fire_department, color: _accent, size: 64),
          SizedBox(height: 18),
          Text(
            'Enjoy Burn Camp?',
            textAlign: TextAlign.center,
            style: TextStyle(color: _cream, fontSize: 26),
          ),
          SizedBox(height: 12),
          Text(
            'Support development and unlock a cleaner premium experience as the app grows.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 18, height: 1.3),
          ),
          SizedBox(height: 28),
          _supportPlan('Yearly', '\$12', '\$1/month', 'Best value'),
          _supportPlan('Monthly', '\$2/month', '', ''),
          _supportPlan('Lifetime', '\$25', '', ''),
          SizedBox(height: 18),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Not now',
              style: TextStyle(color: _muted, fontSize: 18),
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
        padding: const EdgeInsets.all(24),
        child: Text(
          body,
          style: TextStyle(color: _cream, fontSize: 18, height: 1.35),
        ),
      ),
    );
  }

  void _pushDetailPage({required String title, required Widget child}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _DashboardDetailPage(title: title, child: child),
      ),
    );
  }

  Widget _infoBlock(String title, String body) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: _cream, fontSize: 18)),
          SizedBox(height: 6),
          Text(
            body,
            style: TextStyle(color: _muted, fontSize: 15, height: 1.3),
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
      leading: Icon(icon, color: _accent, size: 30),
      title: Text(title, style: TextStyle(color: _cream, fontSize: 18)),
      subtitle: Text(subtitle, style: TextStyle(color: _muted)),
      trailing: onTap == null ? null : Icon(Icons.chevron_right, color: _muted),
      onTap: onTap,
    );
  }

  Widget _supportPlan(String title, String price, String right, String badge) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: _cream,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: _background, fontSize: 22)),
                Text(
                  price,
                  style: TextStyle(color: _selectedSurface, fontSize: 17),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (right.isNotEmpty)
                Text(right, style: TextStyle(color: _background, fontSize: 20)),
              if (badge.isNotEmpty)
                Text(badge, style: TextStyle(color: _accent, fontSize: 14)),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 18,
            bottom: MediaQuery.of(context).viewInsets.bottom + 28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: TextStyle(color: _cream, fontSize: 22)),
              SizedBox(height: 16),
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
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent,
          foregroundColor: _onAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: onPressed,
        child: Text(label, style: TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _recapRow(String label, int calories, int minutes) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: TextStyle(color: _cream, fontSize: 17)),
          ),
          Text(
            '${NumberFormat.decimalPattern().format(calories)} cals · $minutes min',
            style: TextStyle(color: _muted, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Future<void> _updateUserSettings(Map<String, dynamic> values) async {
    final user = _user;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      ...values,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  String _streakModeLabel(String mode) {
    switch (mode) {
      case 'flexible':
        return 'Flexible';
      case 'trainingDays':
        return 'Training days';
      case 'strict':
      default:
        return 'Strict';
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _darkNumberField({
    required TextEditingController controller,
    required String label,
    required String suffix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: TextStyle(color: _cream, fontSize: 18),
      decoration: _inputDecoration(label).copyWith(
        suffixText: suffix,
        suffixStyle: TextStyle(color: _muted),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: _muted),
      filled: true,
      fillColor: _surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  _MetricAggregate _aggregateForPeriod(
    List<Map<String, dynamic>> summaries,
    MetricPeriod period,
  ) {
    final now = DateTime.now();
    late final DateTime start;
    late final DateTime end;

    switch (period) {
      case MetricPeriod.today:
        start = WorkoutService.startOfDay(now);
        end = start.add(const Duration(days: 1));
      case MetricPeriod.yesterday:
        end = WorkoutService.startOfDay(now);
        start = end.subtract(const Duration(days: 1));
      case MetricPeriod.week:
        start = WorkoutService.startOfWeek(now);
        end = start.add(const Duration(days: 7));
      case MetricPeriod.month:
        start = WorkoutService.startOfMonth(now);
        end = DateTime(now.year, now.month + 1);
    }

    var calories = 0;
    var minutes = 0;
    var daysWithEntries = 0;

    for (final summary in summaries) {
      final date = _dateFromSummary(summary);
      if (date == null || date.isBefore(start) || !date.isBefore(end)) continue;
      calories += WorkoutService.caloriesFromSummary(summary);
      minutes += WorkoutService.minutesFromSummary(summary);
      daysWithEntries++;
    }

    return _MetricAggregate(
      calories: calories,
      minutes: minutes,
      days: daysWithEntries,
    );
  }

  String _metricLabel(MetricPeriod period) {
    switch (period) {
      case MetricPeriod.today:
        return 'calories today';
      case MetricPeriod.yesterday:
        return 'calories yesterday';
      case MetricPeriod.week:
        return 'calories this week';
      case MetricPeriod.month:
        return 'calories this month';
    }
  }

  String _minutesLabel(_MetricAggregate aggregate, MetricPeriod period) {
    if (period == MetricPeriod.week || period == MetricPeriod.month) {
      final avg = aggregate.days == 0
          ? 0
          : (aggregate.minutes / aggregate.days).round();
      return '$avg min/day · ${aggregate.minutes} min trained';
    }

    return '${aggregate.minutes} min trained';
  }

  int _sumCalories(List<Map<String, dynamic>> summaries) {
    return summaries.fold<int>(
      0,
      (total, summary) => total + WorkoutService.caloriesFromSummary(summary),
    );
  }

  int _sumMinutes(List<Map<String, dynamic>> summaries) {
    return summaries.fold<int>(
      0,
      (total, summary) => total + WorkoutService.minutesFromSummary(summary),
    );
  }

  List<DateTime> _historyMonthsThroughCurrent(int earliestYear) {
    final now = DateTime.now();
    final months = <DateTime>[];

    for (var year = now.year; year >= earliestYear; year--) {
      final startMonth = year == now.year ? now.month : 12;
      for (var month = startMonth; month >= 1; month--) {
        months.add(DateTime(year, month));
      }
    }

    return months;
  }

  List<DateTime> _mondayWeeksForMonth(DateTime month, DateTime today) {
    final firstDay = DateTime(month.year, month.month);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final firstMondayOffset = firstDay.weekday == DateTime.monday
        ? 0
        : (DateTime.daysPerWeek + DateTime.monday - firstDay.weekday) %
              DateTime.daysPerWeek;
    var monday = firstDay.add(Duration(days: firstMondayOffset));
    final weeks = <DateTime>[];

    while (!monday.isAfter(lastDay) && !monday.isAfter(today)) {
      weeks.add(monday);
      monday = monday.add(const Duration(days: 7));
    }

    return weeks.reversed.toList();
  }

  int _distinctDays(List<Map<String, dynamic>> summaries) {
    return summaries.map(_dateFromSummary).whereType<DateTime>().toSet().length;
  }

  int _historyValueForSummaries(List<Map<String, dynamic>> summaries) {
    final calories = _sumCalories(summaries);
    if (!_historyShowsAverage) return calories;

    final days = _distinctDays(summaries);
    if (days == 0) return 0;
    return (calories / days).round();
  }

  String _formatHistoryValue(
    int calories,
    int days, {
    bool compact = false,
    bool includeUnit = true,
  }) {
    final value = _historyShowsAverage && days > 0
        ? (calories / days).round()
        : calories;
    final formatted = compact
        ? NumberFormat.compact().format(value)
        : NumberFormat.decimalPattern().format(value);

    if (!includeUnit) return formatted;
    return _historyShowsAverage ? '$formatted cals/day' : '$formatted cals';
  }

  String _friendlyDate(Map<String, dynamic> summary) {
    final date = _dateFromSummary(summary);
    if (date == null) return '--';
    return DateFormat.Md().format(date);
  }

  DateTime? _dateFromSummary(Map<String, dynamic> summary) {
    final timestamp = summary['dateTimestamp'];
    if (timestamp is Timestamp) {
      return WorkoutService.startOfDay(timestamp.toDate());
    }

    final date = summary['date'];
    if (date is String) {
      try {
        return WorkoutService.startOfDay(DateTime.parse(date));
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  int _goalCalories(Map<String, dynamic> data) {
    return (data['goalCalories'] as num?)?.toInt() ??
        (data['goalMinutes'] as num?)?.toInt() ??
        500;
  }

  int _goalCaloriesFromCachedSummaries(List<Map<String, dynamic>> summaries) {
    for (final summary in summaries) {
      final goal = (summary['goalCalories'] as num?)?.toInt();
      if (goal != null && goal > 0) return goal;
    }
    return 500;
  }

  int _longestStreak(List<Map<String, dynamic>> summaries) {
    final metDays = summaries
        .where((summary) => summary['goalMet'] == true)
        .map(_dateFromSummary)
        .whereType<DateTime>()
        .toSet();

    if (metDays.isEmpty) return 0;

    var longest = 0;
    var current = 0;
    var day = WorkoutService.startOfDay(DateTime.now());
    final oldest = metDays.reduce((a, b) => a.isBefore(b) ? a : b);

    while (!day.isBefore(oldest)) {
      if (metDays.contains(day)) {
        current++;
        longest = math.max(longest, current);
      } else {
        current = 0;
      }
      day = day.subtract(const Duration(days: 1));
    }

    return longest;
  }

  String _bestWindow(List<Map<String, dynamic>> summaries, Duration window) {
    if (summaries.isEmpty) return '—';

    final dates = summaries
        .map(_dateFromSummary)
        .whereType<DateTime>()
        .toList();
    if (dates.isEmpty) return '—';

    var bestCalories = 0;
    DateTime? bestStart;

    for (final candidate in dates) {
      final end = candidate.add(window);
      final total = summaries.fold<int>(0, (totalCalories, summary) {
        final date = _dateFromSummary(summary);
        if (date == null || date.isBefore(candidate) || !date.isBefore(end)) {
          return totalCalories;
        }
        return totalCalories + WorkoutService.caloriesFromSummary(summary);
      });

      if (total > bestCalories) {
        bestCalories = total;
        bestStart = candidate;
      }
    }

    if (bestStart == null) return '—';
    return '${DateFormat.Md().format(bestStart)} · ${NumberFormat.compact().format(bestCalories)} cals';
  }

  String _bestMonth(List<Map<String, dynamic>> summaries) {
    if (summaries.isEmpty) return '—';
    final totals = <String, int>{};

    for (final summary in summaries) {
      final date = _dateFromSummary(summary);
      if (date == null) continue;
      final key = DateFormat('MMM yyyy').format(date);
      totals[key] =
          (totals[key] ?? 0) + WorkoutService.caloriesFromSummary(summary);
    }

    if (totals.isEmpty) return '—';
    final best = totals.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return '${best.key} · ${NumberFormat.compact().format(best.value)} cals';
  }

  int _botValue(int userCalories, double factor) {
    if (userCalories <= 0) return (350 * factor).round();
    return (userCalories * factor).round();
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }
}

class _MetricAggregate {
  final int calories;
  final int minutes;
  final int days;

  const _MetricAggregate({
    required this.calories,
    required this.minutes,
    required this.days,
  });
}

class _WeekdayLabel extends StatelessWidget {
  final String label;

  const _WeekdayLabel(this.label);

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isLight
              ? ClaudePalette.lightMutedText
              : ClaudePalette.mutedText,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _DashboardDetailPage extends StatelessWidget {
  final String title;
  final Widget child;

  const _DashboardDetailPage({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final foreground = isLight ? ClaudePalette.charcoal : ClaudePalette.cream;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, color: foreground, size: 34),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          title,
          style: TextStyle(
            color: foreground,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: child,
    );
  }
}
