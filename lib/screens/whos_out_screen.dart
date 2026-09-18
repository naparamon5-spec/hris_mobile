import 'package:flutter/material.dart';

import '../data/hris_api.dart';
import '../theme/app_colors.dart';
import '../widgets/async_view.dart';
import '../widgets/ui.dart';

/// A single "out of office" entry shown on the Who's Out calendar.
class OutEntry {
  const OutEntry({
    required this.name,
    required this.start,
    required this.end,
    required this.type,
    this.approved = true,
    this.colorOverride,
  });

  /// Builds an entry from a real backend record. Colour is by category —
  /// Leave of Absence (red) vs Call Approval (blue) — since the view has no
  /// approval status of its own; everyone in it is genuinely out.
  factory OutEntry.fromRecord(WhosOutRecord r) => OutEntry(
        name: r.name,
        start: r.from,
        end: r.to,
        type: r.typeLabel,
        colorOverride: r.type.toLowerCase() == 'ca'
            ? AppColors.success
            : AppColors.brandRedSoft,
      );

  final String name;
  final DateTime start;
  final DateTime end;

  /// Leave type shown in the day sheet (e.g. Vacation, Sick, Emergency).
  final String type;

  /// Approved entries render green; pending/filed entries render red.
  final bool approved;

  /// Explicit chip colour (set for real records); falls back to the
  /// approved/pending colour used by the dashboard's mock preview.
  final Color? colorOverride;

  Color get color =>
      colorOverride ?? (approved ? AppColors.success : AppColors.brandRedSoft);

  bool covers(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    return !d.isBefore(s) && !d.isAfter(e);
  }
}

/// WHO'S OUT — month calendar mirroring the web "Who's Out" app. Shows a grid
/// of days with coloured name bars (green = approved, red = pending) and a tap
/// target per day that lists everyone out that date.
class WhosOutScreen extends StatefulWidget {
  const WhosOutScreen({super.key});

  @override
  State<WhosOutScreen> createState() => _WhosOutScreenState();
}

class _WhosOutScreenState extends State<WhosOutScreen> {
  final DateTime _today = DateTime.now();
  late DateTime _month = DateTime(_today.year, _today.month);

  final _reload = AsyncViewController();

  /// Precomputed day -> entries index, so each day cell is an O(1) lookup
  /// instead of scanning every record (keeps the frame cheap and the loader
  /// animation smooth).
  Map<String, List<OutEntry>> _byDay = const {};

  static String _dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  void _indexEntries(List<OutEntry> entries) {
    final map = <String, List<OutEntry>>{};
    for (final e in entries) {
      var d = DateTime(e.start.year, e.start.month, e.start.day);
      final end = DateTime(e.end.year, e.end.month, e.end.day);
      while (!d.isAfter(end)) {
        (map[_dayKey(d)] ??= []).add(e);
        d = d.add(const Duration(days: 1));
      }
    }
    _byDay = map;
  }

  static const _monthNames = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
  ];
  static const _weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  void dispose() {
    _reload.dispose();
    super.dispose();
  }

  /// Fetches the currently displayed month from the backend (same source and
  /// filter as the web calendar) and maps rows to calendar entries.
  Future<List<OutEntry>> _load() async {
    final records =
        await HrisApi.instance.whosOutMonth(_month.month, _month.year);
    return records.map(OutEntry.fromRecord).toList();
  }

  void _prev() {
    setState(() => _month = DateTime(_month.year, _month.month - 1));
    _reload.reload();
  }

  void _next() {
    setState(() => _month = DateTime(_month.year, _month.month + 1));
    _reload.reload();
  }

  void _goToday() {
    setState(() => _month = DateTime(_today.year, _today.month));
    _reload.reload();
  }

  List<OutEntry> _entriesFor(DateTime day) => _byDay[_dayKey(day)] ?? const [];

  void _showDaySheet(DateTime day) {
    final entries = _entriesFor(day);
    showPremiumBottomSheet(
      context,
      // Let the sheet grow with the list and scroll instead of overflowing
      // when many people are out on the same day.
      isScrollControlled: true,
      builder: (ctx) => _DayOutSheet(day: day, entries: entries),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Build the 6-week grid starting on the Sunday on/before the 1st.
    final first = DateTime(_month.year, _month.month, 1);
    final gridStart = first.subtract(Duration(days: first.weekday % 7));
    final days = List.generate(
      42,
      (i) => gridStart.add(Duration(days: i)),
    );

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    "Who's Out",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                ),
                TextButton(
                  onPressed: _goToday,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    backgroundColor: AppColors.fieldFill,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Today',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 12),
            child: Row(
              children: [
                Text(
                  _month.year.toString(),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkSoft,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _monthNames[_month.month - 1],
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                _navBtn(Icons.chevron_left_rounded, _prev),
                const SizedBox(width: 8),
                _navBtn(Icons.chevron_right_rounded, _next),
              ],
            ),
          ),
          // Weekday header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                for (int i = 0; i < 7; i++)
                  Expanded(
                    child: Center(
                      child: Text(
                        _weekdays[i],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                          color: (i == 0 || i == 6)
                              ? AppColors.brandRed
                              : AppColors.inkSoft,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Calendar grid + footer, driven by the live month fetch.
          Expanded(
            child: AsyncView<List<OutEntry>>(
              controller: _reload,
              load: _load,
              useGlobalLoader: true,
              builder: (context, entries) {
                // Index the entries once so day cells are O(1) lookups.
                _indexEntries(entries);
                final outToday = _entriesFor(_today).length;
                return Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        color: AppColors.brandRed,
                        onRefresh: () async => _reload.reload(),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                          child: Column(
                            children: [
                              for (int w = 0; w < 6; w++)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (int d = 0; d < 7; d++)
                                      Expanded(
                                        child: _DayCell(
                                          day: days[w * 7 + d],
                                          inMonth: days[w * 7 + d].month ==
                                              _month.month,
                                          isToday: _isSameDay(
                                              days[w * 7 + d], _today),
                                          entries:
                                              _entriesFor(days[w * 7 + d]),
                                          onTap: () =>
                                              _showDaySheet(days[w * 7 + d]),
                                        ),
                                      ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Legend + today's count
                    Container(
                      decoration: const BoxDecoration(
                        color: AppColors.card,
                        border: Border(top: BorderSide(color: AppColors.line)),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                      child: Row(
                        children: [
                          _legendDot(AppColors.brandRedSoft, 'Leave'),
                          const SizedBox(width: 16),
                          _legendDot(AppColors.success, 'Call Approval'),
                          const Spacer(),
                          Text(
                            '$outToday out today',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.inkSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _navBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.line),
        ),
        child: Icon(icon, size: 20, color: AppColors.ink),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.inkSoft,
          ),
        ),
      ],
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

/// One day cell in the month grid: date number plus up to two coloured name
/// chips and a "+N" overflow indicator.
class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.inMonth,
    required this.isToday,
    required this.entries,
    required this.onTap,
  });

  final DateTime day;
  final bool inMonth;
  final bool isToday;
  final List<OutEntry> entries;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const maxChips = 2;
    final shown = entries.take(maxChips).toList();
    final extra = entries.length - shown.length;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 84,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: inMonth ? AppColors.card : AppColors.fieldFill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isToday ? AppColors.brandRed : AppColors.line,
            width: isToday ? 1.6 : 1,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date number (today gets a red disc)
            SizedBox(
              height: 20,
              child: Align(
                alignment: Alignment.centerLeft,
                child: isToday
                    ? Container(
                        width: 20,
                        height: 20,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.brandRed,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${day.day}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: inMonth
                              ? AppColors.ink
                              : AppColors.inkFaint,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 2),
            for (final e in shown) ...[
              _chip(e),
              const SizedBox(height: 2),
            ],
            if (extra > 0)
              Text(
                '+$extra',
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.inkFaint,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _chip(OutEntry e) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      decoration: BoxDecoration(
        color: e.color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        e.name.split(' ').first,
        maxLines: 1,
        overflow: TextOverflow.clip,
        softWrap: false,
        style: const TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          height: 1.1,
        ),
      ),
    );
  }
}

/// Bottom sheet listing everyone out on the tapped day.
class _DayOutSheet extends StatelessWidget {
  const _DayOutSheet({required this.day, required this.entries});

  final DateTime day;
  final List<OutEntry> entries;

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static const _wd = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday',
    'Saturday', 'Sunday',
  ];

  @override
  Widget build(BuildContext context) {
    // Cap the sheet so it never exceeds the screen; the people list scrolls.
    final maxHeight = MediaQuery.of(context).size.height * 0.75;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${_wd[day.weekday - 1]}, ${_months[day.month - 1]} ${day.day}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              entries.isEmpty
                  ? 'No one is out on this day.'
                  : '${entries.length} ${entries.length == 1 ? "person" : "people"} out',
              style: const TextStyle(color: AppColors.inkSoft, fontSize: 13),
            ),
            const SizedBox(height: 14),
            if (entries.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 26),
                decoration: BoxDecoration(
                  color: AppColors.fieldFill,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.event_available_rounded,
                        size: 34, color: AppColors.inkFaint),
                    SizedBox(height: 8),
                    Text('Full attendance',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.inkSoft,
                        )),
                  ],
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: entries.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final e = entries[i];
                    return SoftCard(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          InitialsAvatar(
                              name: e.name, size: 40, color: e.color),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  e.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  e.type,
                                  style: const TextStyle(
                                    color: AppColors.inkSoft,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// MOCK DATA — Who's out this month (anchored around Sep 2026)
// -----------------------------------------------------------------------------

/// The app's demo "today" so calendars and dashboards line up on sample data.
final DateTime kToday = DateTime(2026, 9, 11);

/// Everyone whose leave covers [day], used by both the calendar and the
/// dashboard's "Who's out today" preview.
List<OutEntry> whosOutOn(DateTime day) =>
    kWhosOut.where((e) => e.covers(day)).toList();

final List<OutEntry> kWhosOut = [
  OutEntry(
      name: 'Vincent Cataylo',
      start: DateTime(2026, 8, 31),
      end: DateTime(2026, 9, 4),
      type: 'Vacation Leave',
      approved: false),
  OutEntry(
      name: 'Franco De Jesus',
      start: DateTime(2026, 9, 1),
      end: DateTime(2026, 9, 4),
      type: 'Sick Leave',
      approved: false),
  OutEntry(
      name: 'Abner Padilla',
      start: DateTime(2026, 9, 4),
      end: DateTime(2026, 9, 4),
      type: 'Vacation Leave'),
  OutEntry(
      name: 'Merwin Justin Lipi',
      start: DateTime(2026, 9, 4),
      end: DateTime(2026, 9, 4),
      type: 'Emergency Leave'),
  OutEntry(
      name: 'Franco De Jesus',
      start: DateTime(2026, 9, 7),
      end: DateTime(2026, 9, 9),
      type: 'Sick Leave',
      approved: false),
  OutEntry(
      name: 'Mapalad Reque',
      start: DateTime(2026, 9, 7),
      end: DateTime(2026, 9, 9),
      type: 'Vacation Leave',
      approved: false),
  OutEntry(
      name: 'Rhodora Celis',
      start: DateTime(2026, 9, 10),
      end: DateTime(2026, 9, 11),
      type: 'Vacation Leave',
      approved: false),
  OutEntry(
      name: 'Hicie Pangilinan',
      start: DateTime(2026, 9, 10),
      end: DateTime(2026, 9, 10),
      type: 'Vacation Leave'),
  OutEntry(
      name: 'Marvin John Hao',
      start: DateTime(2026, 9, 11),
      end: DateTime(2026, 9, 11),
      type: 'Emergency Leave',
      approved: false),
  OutEntry(
      name: 'Alma Mae Cabarrubias',
      start: DateTime(2026, 9, 14),
      end: DateTime(2026, 9, 15),
      type: 'Sick Leave',
      approved: false),
  OutEntry(
      name: 'Margeux Adelia',
      start: DateTime(2026, 9, 17),
      end: DateTime(2026, 9, 17),
      type: 'Vacation Leave'),
  OutEntry(
      name: 'Maricar Ocampo',
      start: DateTime(2026, 9, 20),
      end: DateTime(2026, 9, 20),
      type: 'Vacation Leave'),
  OutEntry(
      name: 'Margeux Adelia',
      start: DateTime(2026, 9, 22),
      end: DateTime(2026, 9, 22),
      type: 'Vacation Leave'),
];
