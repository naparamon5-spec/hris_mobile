import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/hris_api.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/async_view.dart';
import '../widgets/ui.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final _reload = AsyncViewController();
  bool _busy = false;

  @override
  void dispose() {
    _reload.dispose();
    super.dispose();
  }

  Future<void> _toggle(AttendanceToday today) async {
    if (_busy) return;
    setState(() => _busy = true);
    showLoadingOverlay(context);
    try {
      if (today.isClockedIn) {
        await HrisApi.instance.clockOut();
        if (mounted) {
          hideLoadingOverlay(context);
          showToast(context, 'You have successfully clocked out.', isSuccess: true, title: 'Clocked Out');
        }
      } else {
        await HrisApi.instance.clockIn();
        if (mounted) {
          hideLoadingOverlay(context);
          showToast(context, 'You have successfully clocked in.', isSuccess: true, title: 'Clocked In');
        }
      }
      _reload.reload();
    } on ApiException catch (e) {
      hideLoadingOverlay(context);
      if (mounted) showToast(context, e.message, isSuccess: false, title: 'Error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: canPop,
        title: const Text('Attendance'),
        actions: [
          IconButton(
            onPressed: () => showToast(context, 'Opening calendar view…'),
            icon: const Icon(Icons.calendar_month_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: AsyncView<Attendance>(
          controller: _reload,
          load: () => HrisApi.instance.attendance(),
          builder: (context, a) => RefreshIndicator(
            color: AppColors.brandRed,
            onRefresh: () async => _reload.reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _ClockCard(
                    today: a.today,
                    busy: _busy,
                    onToggle: () => _toggle(a.today)),
                const SizedBox(height: 22),
                _SummaryRow(summary: a.summary),
                const SizedBox(height: 24),
                const SectionHeader(title: 'This week'),
                const SizedBox(height: 14),
                _WeeklyChart(week: a.week),
                const SizedBox(height: 24),
                const SectionHeader(title: "Today's log"),
                const SizedBox(height: 14),
                _Timeline(today: a.today),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ClockCard extends StatelessWidget {
  const _ClockCard(
      {required this.today, required this.busy, required this.onToggle});
  final AttendanceToday today;
  final bool busy;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final clockedIn = today.isClockedIn;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line, width: 1),
        boxShadow: kSoftShadow,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: clockedIn
                      ? AppColors.successSoft
                      : AppColors.fieldFill,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle,
                        size: 8,
                        color: clockedIn
                            ? AppColors.success
                            : AppColors.inkFaint),
                    const SizedBox(width: 6),
                    Text(
                      clockedIn ? 'CLOCKED IN' : 'CLOCKED OUT',
                      style: TextStyle(
                        color: clockedIn
                            ? AppColors.success
                            : AppColors.inkSoft,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Shift: ${today.shift}',
                style: const TextStyle(
                  color: AppColors.inkSoft,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            today.totalHoursToday.isEmpty ? '—' : today.totalHoursToday,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 38,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Total hours worked today',
            style: TextStyle(
              color: AppColors.inkSoft,
              fontWeight: FontWeight.w500,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.fieldFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _miniStat('Time in', today.timeIn ?? '—',
                      Icons.login_rounded, AppColors.brandRed),
                ),
                Container(width: 1, height: 28, color: AppColors.line),
                Expanded(
                  child: _miniStat('Break', '${today.breakMinutes} min',
                      Icons.coffee_outlined, AppColors.brandRed),
                ),
                Container(width: 1, height: 28, color: AppColors.line),
                Expanded(
                  child: _miniStat(
                      'Overtime',
                      today.overtime.isEmpty ? '0h 00m' : today.overtime,
                      Icons.access_time_rounded,
                      AppColors.brandRed),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: busy ? null : onToggle,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    clockedIn ? AppColors.brandRed : AppColors.success,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.2, color: Colors.white),
                    )
                  : Icon(clockedIn ? Icons.logout_rounded : Icons.login_rounded,
                      size: 18),
              label: Text(
                clockedIn ? 'Clock Out' : 'Clock In',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.inkSoft,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.summary});
  final AttendanceSummary summary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: _box('Present', '${summary.present}',
                Icons.check_circle_rounded, AppColors.success)),
        const SizedBox(width: 12),
        Expanded(
            child: _box('Late', '${summary.late}', Icons.watch_later_rounded,
                AppColors.warning)),
        const SizedBox(width: 12),
        Expanded(
            child: _box('Leave', '${summary.leave}',
                Icons.beach_access_rounded, AppColors.info)),
      ],
    );
  }

  Widget _box(String label, String value, IconData icon, Color color) {
    return SoftCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        children: [
          IconBadge(icon: icon, color: color, size: 40, iconSize: 21),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800)),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.inkSoft,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({required this.week});
  final List<AttendanceDay> week;

  @override
  Widget build(BuildContext context) {
    // value out of 10 hours
    final days = week.map((d) => (d.day, d.hours, d.today)).toList();
    final worked = week.where((d) => d.hours > 0).toList();
    final avg = worked.isEmpty
        ? 0.0
        : worked.map((d) => d.hours).reduce((a, b) => a + b) / worked.length;
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Avg ${avg.toStringAsFixed(1)}h / day',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 15)),
              const Spacer(),
              StatusPill(
                  label: '40h target',
                  color: AppColors.info,
                  icon: Icons.flag_rounded),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final d in days)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          d.$2 == 0 ? '–' : d.$2.toStringAsFixed(1),
                          style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: d.$3
                                  ? AppColors.brandRed
                                  : AppColors.inkFaint),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 18,
                          height: (d.$2 / 10) * 110 + (d.$2 == 0 ? 0 : 6),
                          decoration: BoxDecoration(
                            gradient: d.$3
                                ? AppColors.brandGradient
                                : null,
                            color: d.$3 ? null : AppColors.fieldFill,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(d.$1,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: d.$3
                                    ? AppColors.brandRed
                                    : AppColors.inkSoft)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.today});
  final AttendanceToday today;

  @override
  Widget build(BuildContext context) {
    final events = <(String, String, String, IconData, Color)>[
      (
        'Clock in',
        today.timeIn ?? '—',
        'Shift start',
        Icons.login_rounded,
        AppColors.brandRed
      ),
      if (today.isClockedIn)
        (
          'In progress',
          'Now',
          'Working…',
          Icons.more_horiz_rounded,
          AppColors.brandRed
        )
      else
        (
          'Clock out',
          today.timeOut ?? '—',
          'Shift end',
          Icons.logout_rounded,
          AppColors.inkSoft
        ),
    ];
    return SoftCard(
      child: Column(
        children: [
          for (int i = 0; i < events.length; i++)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: events[i].$5.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child:
                          Icon(events[i].$4, size: 18, color: events[i].$5),
                    ),
                    if (i != events.length - 1)
                      Container(
                        width: 2,
                        height: 30,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: AppColors.line,
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(events[i].$1,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14)),
                            const Spacer(),
                            Text(events[i].$2,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: AppColors.inkSoft)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(events[i].$3,
                            style: const TextStyle(
                                color: AppColors.inkFaint, fontSize: 12.5)),
                        SizedBox(height: i == events.length - 1 ? 0 : 14),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
