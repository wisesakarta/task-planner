/// Pure date helpers for the week screen. All dates are local calendar days
/// (time stripped).
abstract final class WeekDates {
  static DateTime day(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// The first day of the week containing [date]. [weekStartsOn] is
  /// [DateTime.monday] or [DateTime.sunday].
  static DateTime startOfWeek(
    DateTime date, {
    int weekStartsOn = DateTime.monday,
  }) {
    final d = day(date);
    final back = weekStartsOn == DateTime.sunday
        ? d.weekday %
              7 // Sunday is 7 → 0
        : d.weekday - 1;
    return DateTime(d.year, d.month, d.day - back);
  }

  /// The seven days of the week that starts at [start].
  static List<DateTime> days(DateTime start) => [
    for (var i = 0; i < 7; i++)
      DateTime(start.year, start.month, start.day + i),
  ];

  static DateTime addWeeks(DateTime start, int weeks) =>
      DateTime(start.year, start.month, start.day + 7 * weeks);

  /// The month a week is "in": the month of its middle day, so the title of
  /// 28 Sep – 4 Oct reads "Oct" (four of its days are in October).
  static DateTime titleMonth(List<DateTime> week) => week[3];
}
