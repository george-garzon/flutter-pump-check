part of 'dashboard_screen.dart';

extension _DashboardHistoryTab on _DashboardScreenState {
  Widget _buildHistoryTab() {
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
              leading: SizedBox(width: context.dimensions.values.s48),
              trailing: IconButton(
                tooltip: _historyShowsAverage
                    ? 'Show total calories'
                    : 'Show average calories',
                icon: Icon(
                  _historyShowsAverage
                      ? Icons.bar_chart
                      : Icons.format_list_numbered,
                  color: _cream,
                  size: context.dimensions.values.s30,
                ),
                onPressed: () {
                  _updateState(
                    () => _historyShowsAverage = !_historyShowsAverage,
                  );
                },
              ),
              bottom: Padding(
                padding: EdgeInsets.fromLTRB(
                  context.dimensions.values.s22,
                  context.dimensions.values.s12,
                  context.dimensions.values.s22,
                  context.dimensions.values.s0,
                ),
                child: Column(
                  children: [
                    _summaryLine(
                      'Daily goal:',
                      '${_goalCaloriesFromCachedSummaries(summaries)} cals',
                      valueColor: _DashboardScreenState._goalLime,
                      icon: Icons.edit,
                      onTap: _showGoalSheet,
                    ),
                    _summaryLine('Longest streak:', '$longestStreak days'),
                    _summaryLine('Best week:', bestWeek),
                    _summaryLine('Best month:', bestMonth),
                    SizedBox(height: context.dimensions.values.s12),
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

  Widget _buildPeriodTabs() {
    final tabs = [
      DashboardSegmentTab.text(value: MetricPeriod.today, label: 'Today'),
      DashboardSegmentTab.text(
        value: MetricPeriod.yesterday,
        label: 'Yesterday',
      ),
      DashboardSegmentTab.text(value: MetricPeriod.week, label: 'Week'),
      DashboardSegmentTab.text(value: MetricPeriod.month, label: 'Month'),
    ];

    return DashboardSegmentedTabs<MetricPeriod>(
      tabs: tabs,
      selectedValue: _period,
      onSelected: (period) => _updateState(() => _period = period),
      height: context.dimensions.values.s54,
      foreground: _cream,
      selectedBackground: _selectedSurface,
      tabMargin: EdgeInsets.zero,
      tabPadding: EdgeInsets.symmetric(
        horizontal: context.dimensions.values.s4,
        vertical: context.dimensions.values.s6,
      ),
    );
  }

  Widget _historyTabs() {
    final tabs = [
      DashboardSegmentTab.text(value: HistoryRange.day, label: 'Day'),
      DashboardSegmentTab.text(value: HistoryRange.week, label: 'Week'),
      DashboardSegmentTab.text(value: HistoryRange.month, label: 'Month'),
      DashboardSegmentTab(
        value: HistoryRange.calendar,
        child: FaIcon(
          FontAwesomeIcons.calendar,
          size: context.dimensions.values.s18,
        ),
      ),
    ];
    return DashboardSegmentedTabs<HistoryRange>(
      tabs: tabs,
      selectedValue: _historyRange,
      onSelected: (range) => _updateState(() => _historyRange = range),
      height: context.dimensions.values.s46,
      foreground: _cream,
      selectedBackground: _selectedSurface,
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
          style: TextStyle(color: _muted, fontSize: context.textSizes.s17),
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
    final scaleValue = _averagePositiveHistoryValue(
      summaries.map((summary) => _historyValueForSummaries([summary])),
    );

    return ListView(
      padding: EdgeInsets.fromLTRB(
        context.dimensions.values.s22,
        context.dimensions.values.s18,
        context.dimensions.values.s22,
        context.dimensions.values.s22,
      ),
      children: _dayHistoryRows(months, summariesByMondayWeek, now, scaleValue),
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
    final scaleValue = _averagePositiveHistoryValue(
      summariesByMondayWeek.values.map(_historyValueForSummaries),
    );

    return ListView(
      padding: EdgeInsets.fromLTRB(
        context.dimensions.values.s22,
        context.dimensions.values.s18,
        context.dimensions.values.s22,
        context.dimensions.values.s22,
      ),
      children: _weekHistoryRows(
        months,
        summariesByMondayWeek,
        now,
        scaleValue,
      ),
    );
  }

  List<Widget> _dayHistoryRows(
    List<DateTime> months,
    Map<DateTime, List<Map<String, dynamic>>> summariesByMondayWeek,
    DateTime today,
    int scaleValue,
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
        ..add(SizedBox(height: context.dimensions.values.s14));

      if (mondayWeeks.isEmpty) {
        rows
          ..add(
            Text(
              'No data',
              style: TextStyle(color: _muted, fontSize: context.textSizes.s18),
            ),
          )
          ..add(SizedBox(height: context.dimensions.values.s18));
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
          ..add(SizedBox(height: context.dimensions.values.s12));

        if (weekSummaries.isEmpty) {
          rows
            ..add(
              Text(
                'No data',
                style: TextStyle(
                  color: _muted,
                  fontSize: context.textSizes.s18,
                ),
              ),
            )
            ..add(SizedBox(height: context.dimensions.values.s14));
        } else {
          rows
            ..addAll(
              weekSummaries.map((summary) => _historyBar(summary, scaleValue)),
            )
            ..add(SizedBox(height: context.dimensions.values.s14));
        }
      }

      rows.add(SizedBox(height: context.dimensions.values.s18));
    }

    return rows;
  }

  List<Widget> _weekHistoryRows(
    List<DateTime> months,
    Map<DateTime, List<Map<String, dynamic>>> summariesByMondayWeek,
    DateTime today,
    int scaleValue,
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
        ..add(SizedBox(height: context.dimensions.values.s14));

      if (mondayWeeks.isEmpty) {
        rows
          ..add(
            Text(
              'No data',
              style: TextStyle(color: _muted, fontSize: context.textSizes.s18),
            ),
          )
          ..add(SizedBox(height: context.dimensions.values.s18));
        continue;
      }

      for (final week in mondayWeeks) {
        rows
          ..add(
            _weekBar(week, summariesByMondayWeek[week] ?? const [], scaleValue),
          )
          ..add(SizedBox(height: context.dimensions.values.s14));
      }

      rows.add(SizedBox(height: context.dimensions.values.s18));
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

    final scaleValue = _averagePositiveHistoryValue(
      groups.values.map(_historyValueForSummaries),
    );
    return ListView(
      padding: EdgeInsets.fromLTRB(
        context.dimensions.values.s22,
        context.dimensions.values.s18,
        context.dimensions.values.s22,
        context.dimensions.values.s22,
      ),
      children: _monthHistoryRows(allMonths, groups, scaleValue),
    );
  }

  List<Widget> _monthHistoryRows(
    List<DateTime> allMonths,
    Map<DateTime, List<Map<String, dynamic>>> groups,
    int scaleValue,
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
          ..add(SizedBox(height: context.dimensions.values.s14));
      }

      rows.add(
        _monthBar(
          DateFormat.MMM().format(month),
          groups[month] ?? const [],
          scaleValue,
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
      padding: EdgeInsets.fromLTRB(
        context.dimensions.values.s22,
        context.dimensions.values.s18,
        context.dimensions.values.s22,
        context.dimensions.values.s22,
      ),
      children: [
        for (final month in months) ...[
          _calendarMonth(month, byDate),
          SizedBox(height: context.dimensions.values.s30),
        ],
      ],
    );
  }

  Widget _historySectionHeader(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: _cream, fontSize: context.textSizes.s23),
        ),
        Text(
          value,
          style: TextStyle(color: _muted, fontSize: context.textSizes.s18),
        ),
      ],
    );
  }

  Widget _weekBar(
    DateTime week,
    List<Map<String, dynamic>> summaries,
    int scaleValue,
  ) {
    final calories = _sumCalories(summaries);
    final minutes = _sumMinutes(summaries);
    final value = _historyValueForSummaries(summaries);
    final widthFactor = value == 0
        ? 0.0
        : math.min(1.0, value / math.max(1, scaleValue));

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
    int scaleValue,
  ) {
    final calories = _sumCalories(summaries);
    final minutes = _sumMinutes(summaries);
    final value = _historyValueForSummaries(summaries);
    final widthFactor = value == 0
        ? 0.0
        : math.min(1.0, value / math.max(1, scaleValue));

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
      padding: EdgeInsets.only(bottom: context.dimensions.values.s20),
      child: Row(
        children: [
          SizedBox(
            width: context.dimensions.values.s76,
            child: Text(
              label,
              style: TextStyle(color: _muted, fontSize: context.textSizes.s18),
            ),
          ),
          Expanded(
            child: !hasData
                ? Text(
                    valueText,
                    style: TextStyle(
                      color: _muted,
                      fontSize: context.textSizes.s18,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _historyValueBar(
                        valueText: valueText,
                        widthFactor: widthFactor,
                        fontSize: context.textSizes.s18,
                      ),
                      SizedBox(height: context.dimensions.values.s4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: _muted,
                          fontSize: context.textSizes.s13,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _historyValueBar({
    required String valueText,
    required double widthFactor,
    required double fontSize,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final measuredTextWidth = _measureTextWidth(
          valueText,
          TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700),
        );
        final minimumWidth = measuredTextWidth + 24;
        final calculatedWidth = availableWidth * widthFactor;
        final barWidth = math.min(
          availableWidth,
          math.max(minimumWidth, calculatedWidth),
        );

        return Container(
          width: barWidth,
          height: context.dimensions.values.s42,
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.symmetric(
            horizontal: context.dimensions.values.s12,
          ),
          decoration: BoxDecoration(
            color: _DashboardScreenState._accent,
            borderRadius: BorderRadius.circular(context.dimensions.values.s8),
          ),
          child: Text(
            valueText,
            maxLines: 1,
            overflow: TextOverflow.visible,
            style: TextStyle(
              color: _background,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      },
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
        SizedBox(height: context.dimensions.values.s14),
        const Row(
          children: [
            DashboardWeekdayLabel('M'),
            DashboardWeekdayLabel('T'),
            DashboardWeekdayLabel('W'),
            DashboardWeekdayLabel('T'),
            DashboardWeekdayLabel('F'),
            DashboardWeekdayLabel('S'),
            DashboardWeekdayLabel('S'),
          ],
        ),
        SizedBox(height: context.dimensions.values.s8),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 0.95,
          children: [
            for (var i = 0; i < leadingBlanks; i++) SizedBox.shrink(),
            for (var day = 1; day <= daysInMonth; day++)
              _calendarDay(DateTime(month.year, month.month, day), byDate),
            for (var i = 0; i < trailingBlanks; i++) SizedBox.shrink(),
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
      margin: EdgeInsets.all(context.dimensions.values.s3),
      decoration: BoxDecoration(
        color: isToday ? _selectedSurface : Colors.transparent,
        borderRadius: BorderRadius.circular(context.dimensions.values.s8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            calories > 0 ? NumberFormat.compact().format(calories) : '',
            style: TextStyle(
              color: calories > 0 ? _DashboardScreenState._accent : _muted,
              fontSize: context.textSizes.s15,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '${date.day}',
            style: TextStyle(color: _muted, fontSize: context.textSizes.s13),
          ),
        ],
      ),
    );
  }
}
