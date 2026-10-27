/// Small date helpers shared by the progress, streak and ranking logic.
class Dates {
  const Dates._();

  /// Calendar day key such as `2026-03-07` (local time).
  static String key(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }

  static DateTime dayStart(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Monday of the week containing [date].
  static DateTime weekStart(DateTime date) {
    final start = dayStart(date);
    return DateTime(start.year, start.month, start.day - (start.weekday - 1));
  }

  /// Adds whole calendar days (DST-safe, unlike adding a [Duration]).
  static DateTime addDays(DateTime date, int days) =>
      DateTime(date.year, date.month, date.day + days);

  static DateTime? parseKey(String key) {
    final parts = key.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  static String weekdayShort(DateTime date) => _weekdays[date.weekday - 1];

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// e.g. `7 Mar 2026`.
  static String readable(DateTime date) =>
      '${date.day} ${_months[date.month - 1]} ${date.year}';
}
