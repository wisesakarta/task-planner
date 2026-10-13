import 'package:intl/intl.dart';

enum RecurrenceUnit { day, week, month, year }

/// "The Nth [weekday] of the month", e.g. every second Friday.
class NthWeekday {
  const NthWeekday({required this.ordinal, required this.weekday})
    : assert(ordinal >= 1 && ordinal <= 4 || ordinal == -1),
      assert(weekday >= DateTime.monday && weekday <= DateTime.sunday);

  /// 1–4, or -1 for the last one.
  final int ordinal;

  /// [DateTime.monday] … [DateTime.sunday].
  final int weekday;

  @override
  bool operator ==(Object other) =>
      other is NthWeekday &&
      other.ordinal == ordinal &&
      other.weekday == weekday;

  @override
  int get hashCode => Object.hash(ordinal, weekday);
}

/// When a task repeats.
///
/// An empty [weekdays], [monthDays], or [months] set means "the same as the
/// occurrence it repeats from". All dates are local calendar days.
class RecurrenceRule {
  const RecurrenceRule({
    required this.unit,
    this.interval = 1,
    this.weekdays = const {},
    this.monthDays = const {},
    this.nthWeekday,
    this.months = const {},
    this.until,
  }) : assert(interval >= 1);

  const RecurrenceRule.daily([int interval = 1])
    : this(unit: RecurrenceUnit.day, interval: interval);

  const RecurrenceRule.weekly([int interval = 1])
    : this(unit: RecurrenceUnit.week, interval: interval);

  const RecurrenceRule.weekdays()
    : this(
        unit: RecurrenceUnit.week,
        weekdays: const {
          DateTime.monday,
          DateTime.tuesday,
          DateTime.wednesday,
          DateTime.thursday,
          DateTime.friday,
        },
      );

  const RecurrenceRule.monthly([int interval = 1])
    : this(unit: RecurrenceUnit.month, interval: interval);

  const RecurrenceRule.yearly([int interval = 1])
    : this(unit: RecurrenceUnit.year, interval: interval);

  /// Reads the current object format and the original enum-name format
  /// (`"daily"`, `"weekdays"`, …). Returns null for "does not repeat" or data
  /// that cannot be understood.
  static RecurrenceRule? fromJson(Object? json) {
    if (json is String) {
      return switch (json) {
        'daily' => const RecurrenceRule.daily(),
        'weekdays' => const RecurrenceRule.weekdays(),
        'weekly' => const RecurrenceRule.weekly(),
        'monthly' => const RecurrenceRule.monthly(),
        _ => null,
      };
    }
    if (json is! Map<String, dynamic>) return null;

    final unit = RecurrenceUnit.values.where((u) => u.name == json['unit']);
    if (unit.isEmpty) return null;

    Set<int> ints(String key, int min, int max) => {
      for (final value in json[key] as List<dynamic>? ?? const [])
        if (value is int && value >= min && value <= max) value,
    };

    final nth = json['nth'];
    NthWeekday? nthWeekday;
    if (nth is Map<String, dynamic>) {
      final ordinal = nth['ordinal'];
      final weekday = nth['weekday'];
      if (ordinal is int &&
          (ordinal == -1 || (ordinal >= 1 && ordinal <= 4)) &&
          weekday is int &&
          weekday >= DateTime.monday &&
          weekday <= DateTime.sunday) {
        nthWeekday = NthWeekday(ordinal: ordinal, weekday: weekday);
      }
    }

    final until = json['until'] as String?;
    final interval = json['interval'];
    return RecurrenceRule(
      unit: unit.first,
      interval: interval is int && interval >= 1 ? interval : 1,
      weekdays: ints('weekdays', DateTime.monday, DateTime.sunday),
      monthDays: ints('monthDays', 1, 31),
      nthWeekday: nthWeekday,
      months: ints('months', 1, 12),
      until: until == null ? null : _day(DateTime.parse(until)),
    );
  }

  final RecurrenceUnit unit;
  final int interval;

  /// Weekly rules: which weekdays ([DateTime.monday] … [DateTime.sunday]).
  final Set<int> weekdays;

  /// Monthly and yearly rules: days of the month (1–31, clamped to the month's
  /// length, so 31 becomes the 30th or 28th where needed).
  final Set<int> monthDays;

  /// Monthly rules: "every second Friday". Takes precedence over [monthDays].
  final NthWeekday? nthWeekday;

  /// Yearly rules: which months (1–12).
  final Set<int> months;

  /// Last day (inclusive) an occurrence may fall on, or null for "never".
  final DateTime? until;

  RecurrenceRule copyWith({
    RecurrenceUnit? unit,
    int? interval,
    Set<int>? weekdays,
    Set<int>? monthDays,
    NthWeekday? nthWeekday,
    Set<int>? months,
    DateTime? until,
    bool clearNthWeekday = false,
    bool clearUntil = false,
  }) {
    return RecurrenceRule(
      unit: unit ?? this.unit,
      interval: interval ?? this.interval,
      weekdays: weekdays ?? this.weekdays,
      monthDays: monthDays ?? this.monthDays,
      nthWeekday: clearNthWeekday ? null : (nthWeekday ?? this.nthWeekday),
      months: months ?? this.months,
      until: clearUntil ? null : (until ?? this.until),
    );
  }

  /// The first occurrence strictly after [from], or null once [until] passes.
  DateTime? nextAfter(DateTime from) {
    final date = _day(from);
    final next = switch (unit) {
      RecurrenceUnit.day => DateTime(
        date.year,
        date.month,
        date.day + interval,
      ),
      RecurrenceUnit.week => _nextWeekly(date),
      RecurrenceUnit.month => _nextMonthly(date),
      RecurrenceUnit.year => _nextYearly(date),
    };
    final limit = until;
    if (limit != null && next.isAfter(_day(limit))) return null;
    return next;
  }

  /// The next due date once a task due on [due] is completed on [today].
  ///
  /// Skips occurrences already in the past, so finishing a daily task three
  /// days late schedules it for tomorrow instead of yesterday. Null when the
  /// rule has ended.
  DateTime? nextDue(DateTime due, DateTime today) {
    final now = _day(today);
    var next = nextAfter(due);
    for (var i = 0; i < 1000 && next != null && !next.isAfter(now); i++) {
      next = nextAfter(next);
    }
    if (next != null && !next.isAfter(now)) next = nextAfter(now);
    return next;
  }

  /// Human-readable description, e.g. "Every 2 weeks on Mon, Wed".
  String summary() {
    final buffer = StringBuffer();
    final every = interval == 1 ? '' : '$interval ';
    switch (unit) {
      case RecurrenceUnit.day:
        buffer.write(interval == 1 ? 'Every day' : 'Every $interval days');
      case RecurrenceUnit.week:
        if (interval == 1 && _isWeekdaysOnly) {
          buffer.write('Every weekday');
        } else {
          buffer.write('Every ${every}week${interval == 1 ? '' : 's'}');
          if (weekdays.isNotEmpty) {
            buffer.write(
              ' on ${_sorted(weekdays).map(_weekdayShort).join(', ')}',
            );
          }
        }
      case RecurrenceUnit.month:
        final nth = nthWeekday;
        if (nth != null) {
          final which =
              '${_ordinalWord(nth.ordinal)} ${_weekdayLong(nth.weekday)}';
          buffer.write(
            interval == 1
                ? 'Every $which'
                : 'Every $interval months on the $which',
          );
        } else {
          buffer.write('Every ${every}month${interval == 1 ? '' : 's'}');
          if (monthDays.isNotEmpty) {
            buffer.write(
              ' on the ${_sorted(monthDays).map(_ordinal).join(', ')}',
            );
          }
        }
      case RecurrenceUnit.year:
        buffer.write('Every ${every}year${interval == 1 ? '' : 's'}');
        if (months.isNotEmpty) {
          buffer.write(' in ${_sorted(months).map(_monthName).join(', ')}');
        }
        if (monthDays.isNotEmpty) {
          buffer.write(
            ' on the ${_sorted(monthDays).map(_ordinal).join(', ')}',
          );
        }
    }
    final limit = until;
    if (limit != null) {
      buffer.write(', until ${DateFormat('d MMM y').format(limit)}');
    }
    return buffer.toString();
  }

  Map<String, dynamic> toJson() => {
    'unit': unit.name,
    'interval': interval,
    'weekdays': _sorted(weekdays),
    'monthDays': _sorted(monthDays),
    'nth': nthWeekday == null
        ? null
        : {'ordinal': nthWeekday!.ordinal, 'weekday': nthWeekday!.weekday},
    'months': _sorted(months),
    'until': until?.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      other is RecurrenceRule &&
      other.unit == unit &&
      other.interval == interval &&
      _sorted(other.weekdays).join(',') == _sorted(weekdays).join(',') &&
      _sorted(other.monthDays).join(',') == _sorted(monthDays).join(',') &&
      other.nthWeekday == nthWeekday &&
      _sorted(other.months).join(',') == _sorted(months).join(',') &&
      other.until == until;

  @override
  int get hashCode => Object.hash(
    unit,
    interval,
    _sorted(weekdays).join(','),
    _sorted(monthDays).join(','),
    nthWeekday,
    _sorted(months).join(','),
    until,
  );

  bool get _isWeekdaysOnly =>
      weekdays.length == 5 && weekdays.every((day) => day <= DateTime.friday);

  DateTime _nextWeekly(DateTime date) {
    final days = weekdays.isEmpty ? {date.weekday} : weekdays;
    final weekStart = DateTime(
      date.year,
      date.month,
      date.day - (date.weekday - 1),
    );

    for (
      var weekday = date.weekday + 1;
      weekday <= DateTime.sunday;
      weekday++
    ) {
      if (days.contains(weekday)) {
        return DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day + weekday - 1,
        );
      }
    }
    final first = _sorted(days).first;
    return DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day + 7 * interval + first - 1,
    );
  }

  DateTime _nextMonthly(DateTime date) {
    final nth = nthWeekday;
    if (nth != null) {
      final thisMonth = _nthWeekdayOf(date.year, date.month, nth);
      if (thisMonth.isAfter(date)) return thisMonth;
      final target = DateTime(date.year, date.month + interval);
      return _nthWeekdayOf(target.year, target.month, nth);
    }

    final days = monthDays.isEmpty ? {date.day} : monthDays;
    final later = [
      for (final day in days) _clampedDay(date.year, date.month, day),
    ].where((candidate) => candidate.isAfter(date)).toList()..sort();
    if (later.isNotEmpty) return later.first;

    final target = DateTime(date.year, date.month + interval);
    return ([
      for (final day in days) _clampedDay(target.year, target.month, day),
    ]..sort()).first;
  }

  DateTime _nextYearly(DateTime date) {
    final chosenMonths = months.isEmpty ? {date.month} : months;
    final days = monthDays.isEmpty ? {date.day} : monthDays;

    List<DateTime> candidates(int year) => [
      for (final month in chosenMonths)
        for (final day in days) _clampedDay(year, month, day),
    ]..sort();

    final later = candidates(
      date.year,
    ).where((candidate) => candidate.isAfter(date));
    if (later.isNotEmpty) return later.first;
    return candidates(date.year + interval).first;
  }
}

DateTime _day(DateTime date) => DateTime(date.year, date.month, date.day);

DateTime _clampedDay(int year, int month, int day) {
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, day > lastDay ? lastDay : day);
}

DateTime _nthWeekdayOf(int year, int month, NthWeekday nth) {
  if (nth.ordinal > 0) {
    final first = DateTime(year, month);
    final offset = (nth.weekday - first.weekday + 7) % 7;
    return DateTime(year, month, 1 + offset + 7 * (nth.ordinal - 1));
  }
  final last = DateTime(year, month + 1, 0);
  final offset = (last.weekday - nth.weekday + 7) % 7;
  return DateTime(year, month, last.day - offset);
}

List<int> _sorted(Set<int> values) => values.toList()..sort();

const _weekdayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String _weekdayLong(int weekday) => _weekdayNames[weekday - 1];

String _weekdayShort(int weekday) => _weekdayNames[weekday - 1].substring(0, 3);

String _monthName(int month) => _monthNames[month - 1];

String _ordinalWord(int ordinal) => switch (ordinal) {
  1 => 'first',
  2 => 'second',
  3 => 'third',
  4 => 'fourth',
  _ => 'last',
};

String _ordinal(int n) {
  final teen = n % 100 >= 11 && n % 100 <= 13;
  final suffix = teen
      ? 'th'
      : switch (n % 10) {
          1 => 'st',
          2 => 'nd',
          3 => 'rd',
          _ => 'th',
        };
  return '$n$suffix';
}
