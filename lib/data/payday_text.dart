import 'hris_api.dart';

/// Makes the date in a payday notification match the dashboard's payday.
///
/// The server writes payday notifications with its own rule, which can name
/// the unshifted date (e.g. "Nov 15") while the dashboard shows the date it is
/// actually paid (Fri Nov 13, because the 15th is a Sunday). Each payday date
/// found in the text is passed through [PayCalendarPeriod.paydayFromCutoff],
/// the same rule the dashboard uses, so both always agree. The original
/// format of the date (short/long month, year, ISO, numeric) is kept.
class PaydayText {
  PaydayText._();

  static const _short = [
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
  static const _long = [
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

  // "Nov 15", "Nov. 15", "November 15", "Nov 15, 2026", "Nov 15th".
  static final _monthDay = RegExp(
    r'\b(Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|May|Jun(?:e)?|'
    r'Jul(?:y)?|Aug(?:ust)?|Sep(?:t(?:ember)?)?|Oct(?:ober)?|Nov(?:ember)?|'
    r'Dec(?:ember)?)(\.?)\s+(\d{1,2})(st|nd|rd|th)?(,?\s+(\d{4}))?\b',
    caseSensitive: false,
  );
  // "2026-11-15"
  static final _iso = RegExp(r'\b(\d{4})-(\d{2})-(\d{2})\b');
  // "11/15/2026"
  static final _numeric = RegExp(r'\b(\d{1,2})/(\d{1,2})/(\d{4})\b');

  /// True when the notification is about a payday (not a payslip or cutoff,
  /// whose dates are period ranges and must stay as they are).
  static bool isPayday(String kind, String title, String body) {
    final text = '$title $body'.toLowerCase();
    if (text.contains('payslip') ||
        text.contains('cutoff') ||
        text.contains('cut-off')) {
      return false;
    }
    return kind.trim().toLowerCase() == 'payday' ||
        text.contains('payday') ||
        text.contains('pay day') ||
        text.contains('pay date');
  }

  /// [text] with every payday date corrected; unchanged otherwise.
  static String fix(String text, {DateTime? now}) {
    final ref = now ?? DateTime.now();
    var out = text.replaceAllMapped(_monthDay, (m) {
      final month = _monthIndex(m[1]!);
      final day = int.parse(m[3]!);
      final year = m[6] != null ? int.parse(m[6]!) : _nearestYear(month, ref);
      final fixed = _correct(year, month, day);
      if (fixed == null) return m[0]!;
      final isLong = m[1]!.length > 4;
      final name = isLong ? _long[fixed.month - 1] : _short[fixed.month - 1];
      final yearPart = m[5] ?? '';
      return '$name${m[2]} ${fixed.day}${m[4] ?? ''}$yearPart';
    });
    out = out.replaceAllMapped(_iso, (m) {
      final fixed = _correct(
        int.parse(m[1]!),
        int.parse(m[2]!),
        int.parse(m[3]!),
      );
      if (fixed == null) return m[0]!;
      return '${fixed.year.toString().padLeft(4, '0')}-'
          '${fixed.month.toString().padLeft(2, '0')}-'
          '${fixed.day.toString().padLeft(2, '0')}';
    });
    out = out.replaceAllMapped(_numeric, (m) {
      final fixed = _correct(
        int.parse(m[3]!),
        int.parse(m[1]!),
        int.parse(m[2]!),
      );
      if (fixed == null) return m[0]!;
      return '${fixed.month}/${fixed.day}/${fixed.year}';
    });
    return out;
  }

  /// Corrected title/body for a notification, or the originals when it isn't
  /// a payday notification.
  static (String, String) apply(
    String kind,
    String title,
    String body, {
    DateTime? now,
  }) {
    if (!isPayday(kind, title, body)) return (title, body);
    return (fix(title, now: now), fix(body, now: now));
  }

  /// The dashboard's payday for a date that names a payday, or null when the
  /// date isn't a plausible payday (so other dates are left alone).
  static DateTime? _correct(int year, int month, int day) {
    if (month < 1 || month > 12 || day < 1) return null;
    final lastDay = DateTime.utc(year, month + 1, 0).day;
    if (day > lastDay) return null;
    // Paydays are the 15th / 30th (or month end), possibly paid a few days
    // early; anything else isn't a payday date.
    final plausible = (day >= 10 && day <= 15) || day >= 25;
    if (!plausible) return null;
    final pay = PayCalendarPeriod.paydayFromCutoff(
      DateTime.utc(year, month, day),
    );
    return pay;
  }

  static int _monthIndex(String name) {
    final key = name.substring(0, 3).toLowerCase();
    return _short.indexWhere((s) => s.toLowerCase() == key) + 1;
  }

  /// Year for a date written without one: the one closest to [ref], so a
  /// "Jan 15" notification read in late December means next January.
  static int _nearestYear(int month, DateTime ref) {
    final diff = month - ref.month;
    if (diff > 6) return ref.year - 1;
    if (diff < -6) return ref.year + 1;
    return ref.year;
  }
}
