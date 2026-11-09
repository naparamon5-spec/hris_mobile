/// Philippine regular holidays and special non-working days, used to work out
/// when a payday has to be paid early. Special *working* days (e.g. EDSA,
/// Feb 25) are normal days and are left out.
///
/// Dates that repeat by rule are computed so this keeps working in future
/// years. Only the dates below need updating when Malacañang announces them.
const _proclaimed = <int, List<(int month, int day)>>{
  2026: [(2, 17)], // Chinese New Year (Proclamation 1006, s. 2025)
  2027: [(2, 6)], // Chinese New Year (Proclamation 1427, s. 2026)
  // Add Eid'l Fitr and Eid'l Adha here once each year's dates are declared.
};

const _fixed = <(int month, int day)>{
  (1, 1), // New Year's Day
  (4, 9), // Araw ng Kagitingan
  (5, 1), // Labor Day
  (6, 12), // Independence Day
  (8, 21), // Ninoy Aquino Day
  (11, 1), // All Saints' Day
  (11, 2), // All Souls' Day
  (11, 30), // Bonifacio Day
  (12, 8), // Immaculate Conception
  (12, 24), // Christmas Eve
  (12, 25), // Christmas Day
  (12, 30), // Rizal Day
  (12, 31), // Last Day of the Year
};

bool isPhilippineHoliday(DateTime date) {
  final key = (date.month, date.day);
  if (_fixed.contains(key)) return true;
  if (_proclaimed[date.year]?.contains(key) ?? false) return true;

  final day = DateTime.utc(date.year, date.month, date.day);
  final daysToEaster = _easterSunday(date.year).difference(day).inDays;
  if (daysToEaster >= 1 && daysToEaster <= 3) return true; // Holy Week

  // National Heroes Day: the last Monday of August.
  return date.month == 8 &&
      date.weekday == DateTime.monday &&
      date.day + 7 > 31;
}

/// Western Easter Sunday (anonymous Gregorian algorithm).
DateTime _easterSunday(int year) {
  final a = year % 19;
  final b = year ~/ 100;
  final c = year % 100;
  final d = b ~/ 4;
  final e = b % 4;
  final f = (b + 8) ~/ 25;
  final g = (b - f + 1) ~/ 3;
  final h = (19 * a + b - d - g + 15) % 30;
  final i = c ~/ 4;
  final k = c % 4;
  final l = (32 + 2 * e + 2 * i - h - k) % 7;
  final m = (a + 11 * h + 22 * l) ~/ 451;
  final month = (h + l - 7 * m + 114) ~/ 31;
  final day = (h + l - 7 * m + 114) % 31 + 1;
  return DateTime.utc(year, month, day);
}
