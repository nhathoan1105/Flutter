class WeeklyWeight {
  final DateTime weekStart;
  final double average;
  final int count;

  const WeeklyWeight(this.weekStart, this.average, this.count);
}

DateTime startOfWeek(DateTime d) {
  // Calendar arithmetic (not Duration) so DST shifts can't add stray hours.
  return DateTime(d.year, d.month, d.day - (d.weekday - DateTime.monday));
}

/// Averages weigh-ins per Monday-based week, covering the last [weeks] weeks
/// up to [now]. Weeks without a weigh-in are omitted.
List<WeeklyWeight> weeklyAverages(
  List<({DateTime date, double kg})> history, {
  required int weeks,
  DateTime? now,
}) {
  final thisWeek = startOfWeek(now ?? DateTime.now());
  final firstWeek =
      DateTime(thisWeek.year, thisWeek.month, thisWeek.day - 7 * (weeks - 1));
  final buckets = <DateTime, List<double>>{};
  for (final h in history) {
    final week = startOfWeek(h.date);
    if (week.isBefore(firstWeek)) continue;
    buckets.putIfAbsent(week, () => []).add(h.kg);
  }
  final result = buckets.entries
      .map((e) => WeeklyWeight(
            e.key,
            e.value.reduce((a, b) => a + b) / e.value.length,
            e.value.length,
          ))
      .toList();
  result.sort((a, b) => a.weekStart.compareTo(b.weekStart));
  return result;
}
