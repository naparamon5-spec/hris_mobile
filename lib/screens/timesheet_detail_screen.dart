import 'package:flutter/material.dart';

import '../data/hris_api.dart';
import '../data/mock_data.dart';
import '../theme/app_colors.dart';
import '../widgets/async_view.dart';

/// Timesheet (DTR) detail for one pay period — a simple, vertically-scrollable
/// list, one row per day. No wide table, no download button.
class TimesheetDetailScreen extends StatelessWidget {
  const TimesheetDetailScreen({super.key, required this.id, required this.title});

  /// `<pay_year>-<pay_period>`.
  final String id;
  final String title;

  String get _headerId {
    final parts = id.split('-');
    return parts.length == 2 ? '#${parts[0]}:${parts[1]}' : '#$id';
  }

  static String _h(double v) => v == 0
      ? '0'
      : (v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text('TimesheetID $_headerId')),
      body: AsyncView<TimesheetDetail>(
        load: () => HrisApi.instance.timesheet(id),
        useGlobalLoader: true,
        builder: (context, ts) {
          if (ts.days.isEmpty) {
            return const Center(
              child: Text('No timesheet entries for this period.',
                  style: TextStyle(
                      fontSize: 14,
                      color: AppColors.inkFaint,
                      fontWeight: FontWeight.w500)),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: ts.days.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _DayRow(day: ts.days[i]),
          );
        },
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({required this.day});

  final TimesheetDay day;

  // Remarks that should be flagged red (e.g. approved leave, no time out).
  bool get _flagged {
    final r = day.remarks.toLowerCase();
    return r.contains('leave') ||
        r.contains('no time') ||
        r.contains('late') ||
        r.contains('absent') ||
        r.contains('awol');
  }

  @override
  Widget build(BuildContext context) {
    final hasTime = day.timeIn.isNotEmpty || day.timeOut.isNotEmpty;
    final flagged = _flagged;
    final subtitle = hasTime
        ? '${day.dayType}  •  ${day.timeIn} – ${day.timeOut}'
        : '${day.dayType}  •  ${day.remarks.isNotEmpty ? day.remarks : 'No entry'}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(day.date,
                    style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink)),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: flagged ? FontWeight.w700 : FontWeight.w600,
                      color: flagged ? AppColors.brandRed : AppColors.inkSoft),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text('${TimesheetDetailScreen._h(day.totalHrs)} hrs',
              style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w900,
                  color: flagged ? AppColors.brandRed : AppColors.ink)),
        ],
      ),
    );
  }
}
