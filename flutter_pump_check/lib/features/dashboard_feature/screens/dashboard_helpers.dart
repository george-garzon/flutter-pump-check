part of 'dashboard_screen.dart';

extension _DashboardHelpers on _DashboardScreenState {
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

  void _openStatsShareScreen(List<Map<String, dynamic>> summaries) {
    final data = _StatsShareData(
      periodAggregates: {
        for (final period in MetricPeriod.values)
          period: _aggregateForPeriod(summaries, period),
      },
      longestStreak: _longestStreak(summaries),
      bestWeek: _bestWindow(summaries, const Duration(days: 7)),
      bestMonth: _bestMonth(summaries),
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            _StatsShareScreen(initialPeriod: _period, shareData: data),
      ),
    );
  }

  Future<void> _shareText(BuildContext _, String text) async {
    try {
      final origin = _shareOriginForPlatform();
      await SharePlus.instance.share(
        ShareParams(text: text, sharePositionOrigin: origin),
      );
    } catch (e) {
      _showSnack('Share failed: $e');
    }
  }

  Rect? _shareOriginForPlatform() {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return null;
    }

    // The app-level scaling wrapper can report Flutter global coordinates that
    // are outside the native iOS source view. iOS rejects those rects. Passing a
    // tiny in-bounds rect is more reliable for the text-only share sheet.
    return const Rect.fromLTWH(1, 1, 1, 1);
  }

  Widget _darkNumberField({
    required TextEditingController controller,
    required String label,
    required String suffix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: TextStyle(color: _cream, fontSize: context.textSizes.s18),
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
        borderRadius: BorderRadius.circular(context.dimensions.values.s14),
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
      if (date == null || date.isBefore(start) || !date.isBefore(end)) {
        continue;
      }
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

  int _averagePositiveHistoryValue(Iterable<int> values) {
    final positiveValues = values.where((value) => value > 0).toList();
    if (positiveValues.isEmpty) return 1;

    final total = positiveValues.fold<int>(
      0,
      (runningTotal, value) => runningTotal + value,
    );
    return math.max(1, (total / positiveValues.length).round());
  }

  double _measureTextWidth(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: ui.TextDirection.ltr,
    )..layout();
    return painter.width;
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
}
