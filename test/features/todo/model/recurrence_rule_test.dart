import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/features/todo/model/recurrence_rule.dart';

// 2026-09-30 is a Wednesday; 2026-10-01 a Thursday; 2026-10-02 a Friday.
void main() {
  group('nextAfter — days and weeks', () {
    test('every N days crosses month and year ends', () {
      expect(
        const RecurrenceRule.daily(3).nextAfter(DateTime(2026, 12, 30)),
        DateTime(2027, 1, 2),
      );
    });

    test('a plain weekly rule repeats on the same weekday', () {
      expect(
        const RecurrenceRule.weekly().nextAfter(DateTime(2026, 1, 28)),
        DateTime(2026, 2, 4),
      );
    });

    test('a weekly rule with chosen weekdays walks through the week', () {
      const rule = RecurrenceRule(
        unit: RecurrenceUnit.week,
        weekdays: {DateTime.monday, DateTime.wednesday, DateTime.friday},
      );

      expect(rule.nextAfter(DateTime(2026, 9, 30)), DateTime(2026, 10, 2));
      expect(rule.nextAfter(DateTime(2026, 10, 2)), DateTime(2026, 10, 5));
    });

    test('every 2 weeks skips the week in between', () {
      const rule = RecurrenceRule(
        unit: RecurrenceUnit.week,
        interval: 2,
        weekdays: {DateTime.monday, DateTime.wednesday, DateTime.friday},
      );

      // Friday of week A -> Monday of week C, not week B.
      expect(rule.nextAfter(DateTime(2026, 10, 2)), DateTime(2026, 10, 12));
      // Monday of week A -> Wednesday of the same week.
      expect(rule.nextAfter(DateTime(2026, 9, 28)), DateTime(2026, 9, 30));
    });

    test('every weekday skips the weekend', () {
      expect(
        const RecurrenceRule.weekdays().nextAfter(DateTime(2026, 10, 2)),
        DateTime(2026, 10, 5),
      );
      expect(
        const RecurrenceRule.weekdays().nextAfter(DateTime(2026, 10, 1)),
        DateTime(2026, 10, 2),
      );
    });
  });

  group('nextAfter — months', () {
    test('without chosen days it keeps the day and clamps short months', () {
      expect(
        const RecurrenceRule.monthly().nextAfter(DateTime(2026, 1, 31)),
        DateTime(2026, 2, 28),
      );
      expect(
        const RecurrenceRule.monthly().nextAfter(DateTime(2028, 1, 31)),
        DateTime(2028, 2, 29),
      );
    });

    test('an explicit day 31 does not drift after a short month', () {
      const rule = RecurrenceRule(unit: RecurrenceUnit.month, monthDays: {31});

      expect(rule.nextAfter(DateTime(2026, 1, 31)), DateTime(2026, 2, 28));
      expect(rule.nextAfter(DateTime(2026, 2, 28)), DateTime(2026, 3, 31));
    });

    test('several days of the month are visited in order', () {
      const rule = RecurrenceRule(
        unit: RecurrenceUnit.month,
        monthDays: {1, 15},
      );

      expect(rule.nextAfter(DateTime(2026, 1, 1)), DateTime(2026, 1, 15));
      expect(rule.nextAfter(DateTime(2026, 1, 15)), DateTime(2026, 2, 1));
    });

    test('every 2 months skips a month', () {
      expect(
        const RecurrenceRule.monthly(2).nextAfter(DateTime(2026, 11, 12)),
        DateTime(2027, 1, 12),
      );
    });

    test('every second Friday', () {
      const rule = RecurrenceRule(
        unit: RecurrenceUnit.month,
        nthWeekday: NthWeekday(ordinal: 2, weekday: DateTime.friday),
      );

      expect(rule.nextAfter(DateTime(2026, 10, 1)), DateTime(2026, 10, 9));
      expect(rule.nextAfter(DateTime(2026, 10, 9)), DateTime(2026, 11, 13));
    });

    test('every last Friday', () {
      const rule = RecurrenceRule(
        unit: RecurrenceUnit.month,
        nthWeekday: NthWeekday(ordinal: -1, weekday: DateTime.friday),
      );

      expect(rule.nextAfter(DateTime(2026, 10, 1)), DateTime(2026, 10, 30));
      expect(rule.nextAfter(DateTime(2026, 10, 30)), DateTime(2026, 11, 27));
    });
  });

  group('nextAfter — years and end date', () {
    test('a plain yearly rule repeats on the same date', () {
      expect(
        const RecurrenceRule.yearly().nextAfter(DateTime(2026, 1, 12)),
        DateTime(2027, 1, 12),
      );
    });

    test('a leap day falls back to Feb 28 in other years', () {
      expect(
        const RecurrenceRule.yearly().nextAfter(DateTime(2028, 2, 29)),
        DateTime(2029, 2, 28),
      );
    });

    test('chosen months are visited in order', () {
      const rule = RecurrenceRule(unit: RecurrenceUnit.year, months: {1, 6});

      expect(rule.nextAfter(DateTime(2026, 1, 12)), DateTime(2026, 6, 12));
      expect(rule.nextAfter(DateTime(2026, 6, 12)), DateTime(2027, 1, 12));
    });

    test('nothing is returned after the end date', () {
      final rule = RecurrenceRule(
        unit: RecurrenceUnit.day,
        until: DateTime(2026, 10, 1),
      );

      expect(rule.nextAfter(DateTime(2026, 9, 30)), DateTime(2026, 10, 1));
      expect(rule.nextAfter(DateTime(2026, 10, 1)), isNull);
    });
  });

  group('nextDue', () {
    test('an on-time completion moves to the next occurrence', () {
      expect(
        const RecurrenceRule.daily().nextDue(
          DateTime(2026, 9, 30),
          DateTime(2026, 9, 30),
        ),
        DateTime(2026, 10, 1),
      );
    });

    test('a late completion skips occurrences already in the past', () {
      expect(
        const RecurrenceRule.daily().nextDue(
          DateTime(2026, 9, 27),
          DateTime(2026, 9, 30),
        ),
        DateTime(2026, 10, 1),
      );
      expect(
        const RecurrenceRule.weekly().nextDue(
          DateTime(2026, 9, 1),
          DateTime(2026, 9, 30),
        ),
        DateTime(2026, 10, 6),
      );
    });

    test('completing early still advances past the due date', () {
      expect(
        const RecurrenceRule.daily().nextDue(
          DateTime(2026, 10, 5),
          DateTime(2026, 9, 30),
        ),
        DateTime(2026, 10, 6),
      );
    });

    test('a very late daily task still lands after today', () {
      expect(
        const RecurrenceRule.daily().nextDue(
          DateTime(2020, 1, 1),
          DateTime(2026, 9, 30),
        ),
        DateTime(2026, 10, 1),
      );
    });

    test('returns null when the rule ended before reaching the future', () {
      final rule = RecurrenceRule(
        unit: RecurrenceUnit.day,
        until: DateTime(2026, 9, 29),
      );

      expect(
        rule.nextDue(DateTime(2026, 9, 27), DateTime(2026, 9, 30)),
        isNull,
      );
    });
  });

  group('summary', () {
    test('describes days and weeks', () {
      expect(const RecurrenceRule.daily().summary(), 'Every day');
      expect(const RecurrenceRule.daily(3).summary(), 'Every 3 days');
      expect(const RecurrenceRule.weekdays().summary(), 'Every weekday');
      expect(const RecurrenceRule.weekly().summary(), 'Every week');
      expect(
        const RecurrenceRule(
          unit: RecurrenceUnit.week,
          interval: 2,
          weekdays: {DateTime.wednesday, DateTime.monday},
        ).summary(),
        'Every 2 weeks on Mon, Wed',
      );
    });

    test('describes months with correct ordinals', () {
      expect(const RecurrenceRule.monthly().summary(), 'Every month');
      expect(
        const RecurrenceRule(
          unit: RecurrenceUnit.month,
          monthDays: {12},
        ).summary(),
        'Every month on the 12th',
      );
      expect(
        const RecurrenceRule(
          unit: RecurrenceUnit.month,
          monthDays: {1, 11, 12, 13, 22, 23},
        ).summary(),
        'Every month on the 1st, 11th, 12th, 13th, 22nd, 23rd',
      );
      expect(
        const RecurrenceRule(
          unit: RecurrenceUnit.month,
          nthWeekday: NthWeekday(ordinal: 2, weekday: DateTime.friday),
        ).summary(),
        'Every second Friday',
      );
      expect(
        const RecurrenceRule(
          unit: RecurrenceUnit.month,
          interval: 2,
          nthWeekday: NthWeekday(ordinal: -1, weekday: DateTime.monday),
        ).summary(),
        'Every 2 months on the last Monday',
      );
    });

    test('describes years and the end date', () {
      expect(
        const RecurrenceRule(unit: RecurrenceUnit.year, months: {1}).summary(),
        'Every year in January',
      );
      expect(
        RecurrenceRule(
          unit: RecurrenceUnit.day,
          until: DateTime(2026, 12, 12),
        ).summary(),
        'Every day, until 12 Dec 2026',
      );
    });
  });

  group('JSON', () {
    test('round-trips every field', () {
      final rule = RecurrenceRule(
        unit: RecurrenceUnit.month,
        interval: 2,
        weekdays: const {DateTime.monday},
        monthDays: const {1, 15},
        nthWeekday: const NthWeekday(ordinal: 3, weekday: DateTime.tuesday),
        months: const {3, 9},
        until: DateTime(2027, 5, 6),
      );

      expect(RecurrenceRule.fromJson(rule.toJson()), rule);
    });

    test('reads the original enum-name format', () {
      expect(RecurrenceRule.fromJson('daily'), const RecurrenceRule.daily());
      expect(
        RecurrenceRule.fromJson('weekdays'),
        const RecurrenceRule.weekdays(),
      );
      expect(RecurrenceRule.fromJson('weekly'), const RecurrenceRule.weekly());
      expect(
        RecurrenceRule.fromJson('monthly'),
        const RecurrenceRule.monthly(),
      );
    });

    test('treats "none" and unreadable data as not repeating', () {
      expect(RecurrenceRule.fromJson('none'), isNull);
      expect(RecurrenceRule.fromJson(null), isNull);
      expect(RecurrenceRule.fromJson(42), isNull);
      expect(RecurrenceRule.fromJson({'unit': 'fortnight'}), isNull);
    });

    test('repairs out-of-range values instead of failing', () {
      final rule = RecurrenceRule.fromJson({
        'unit': 'week',
        'interval': 0,
        'weekdays': [0, 1, 8, 'x', 3],
        'monthDays': [0, 32],
        'nth': {'ordinal': 9, 'weekday': 1},
      })!;

      expect(rule.interval, 1);
      expect(rule.weekdays, {1, 3});
      expect(rule.monthDays, isEmpty);
      expect(rule.nthWeekday, isNull);
    });
  });

  test('equality ignores set ordering', () {
    expect(
      const RecurrenceRule(
        unit: RecurrenceUnit.week,
        weekdays: {DateTime.monday, DateTime.friday},
      ),
      const RecurrenceRule(
        unit: RecurrenceUnit.week,
        weekdays: {DateTime.friday, DateTime.monday},
      ),
    );
  });
}
