/// Sizes of the Month view, measured from Tweek's Android app (1 dp = 2.74 px).
abstract final class MonthMetrics {
  /// Height of one week row.
  static const double rowHeight = 138;

  /// Extra height above the first row of a month, holding its name.
  static const double labelHeight = 64;

  /// Margin at the left and right of the grid.
  static const double margin = 16;

  /// A day number sits in a circle this wide, this far from the top of its cell.
  static const double numberSize = 28;
  static const double numberTop = 8;

  /// A task pill, and the gap after each one.
  static const double pillHeight = 18;
  static const double pillGap = 3;

  /// Space between the number and the first pill.
  static const double numberGap = 6;

  /// How many pills fit under the number in one row.
  static int get pillCapacity =>
      ((rowHeight - numberTop - numberSize - numberGap) /
              (pillHeight + pillGap))
          .floor();
}

/// One row of the month grid: up to seven days.
///
/// A week that crosses a month boundary is split in two rows, one at the end
/// of each month: the first keeps its days on the left, the second on the
/// right. The first row of a month carries the month's name above it, centred
/// on the column of the 1st.
class MonthRow {
  const MonthRow({required this.cells, this.monthStart, this.labelColumn = 0});

  /// Seven slots; null where the row has no day.
  final List<DateTime?> cells;

  /// Set on the first row of a month: the 1st of that month.
  final DateTime? monthStart;

  /// The column of the 1st, where the month name is aligned.
  final int labelColumn;

  bool get startsMonth => monthStart != null;

  double get height =>
      MonthMetrics.rowHeight + (startsMonth ? MonthMetrics.labelHeight : 0);

  /// The first day in the row.
  DateTime get firstDay => cells.firstWhere((day) => day != null)!;
}

/// Every row from the month of [from] to the month of [to], inclusive.
/// [weekStartsOn] is [DateTime.monday] or [DateTime.sunday].
List<MonthRow> buildMonthRows({
  required DateTime from,
  required DateTime to,
  int weekStartsOn = DateTime.monday,
}) {
  final rows = <MonthRow>[];
  var year = from.year;
  var month = from.month;

  while (year < to.year || (year == to.year && month <= to.month)) {
    final first = DateTime(year, month);
    final count = DateTime(year, month + 1, 0).day;
    final firstColumn = (first.weekday - weekStartsOn) % 7;

    var cells = List<DateTime?>.filled(7, null);
    var column = firstColumn;
    var isFirstRow = true;

    for (var day = 1; day <= count; day++) {
      cells[column] = DateTime(year, month, day);
      column++;
      if (column == 7 || day == count) {
        rows.add(
          MonthRow(
            cells: cells,
            monthStart: isFirstRow ? first : null,
            labelColumn: isFirstRow ? firstColumn : 0,
          ),
        );
        cells = List<DateTime?>.filled(7, null);
        column = 0;
        isFirstRow = false;
      }
    }

    month++;
    if (month > 12) {
      month = 1;
      year++;
    }
  }
  return rows;
}
