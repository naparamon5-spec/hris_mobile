import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
          children: [
            _ClockCard(),
            const SizedBox(height: 22),
            _SummaryRow(),
            const SizedBox(height: 24),
            const SectionHeader(title: 'This week'),
            const SizedBox(height: 14),
            _WeeklyChart(),
            const SizedBox(height: 24),
            const SectionHeader(title: "Today's log"),
            const SizedBox(height: 14),
            _Timeline(),
          ],
        ),
      ),
    );
  }
}

class _ClockCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
                  color: AppColors.successSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.circle, size: 8, color: AppColors.success),
                    SizedBox(width: 6),
                    Text(
                      'CLOCKED IN',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                'Shift: 08:30 AM – 05:30 PM',
                style: TextStyle(
                  color: AppColors.inkSoft,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            '07 : 12 : 48',
            style: TextStyle(
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
                  child: _miniStat('Time in', '08:32 AM',
                      Icons.login_rounded, AppColors.brandRed),
                ),
                Container(width: 1, height: 28, color: AppColors.line),
                Expanded(
                  child: _miniStat('Break', '48 min',
                      Icons.coffee_outlined, AppColors.brandRed),
                ),
                Container(width: 1, height: 28, color: AppColors.line),
                Expanded(
                  child: _miniStat('Overtime', '0h 00m',
                      Icons.access_time_rounded, AppColors.brandRed),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => showToast(context, 'Clocked out at 04:30 PM'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandRed,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text(
                'Clock Out',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
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
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: _box('Present', '21', Icons.check_circle_rounded,
                AppColors.success)),
        const SizedBox(width: 12),
        Expanded(
            child:
                _box('Late', '3', Icons.watch_later_rounded, AppColors.warning)),
        const SizedBox(width: 12),
        Expanded(
            child: _box('Leave', '2', Icons.beach_access_rounded,
                AppColors.info)),
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
  @override
  Widget build(BuildContext context) {
    // value out of 10 hours
    final days = const [
      ('Mon', 8.5, false),
      ('Tue', 9.0, false),
      ('Wed', 7.5, false),
      ('Thu', 8.0, false),
      ('Fri', 7.2, true), // today
      ('Sat', 0.0, false),
      ('Sun', 0.0, false),
    ];
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Avg 8.0h / day',
                  style: TextStyle(
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
  @override
  Widget build(BuildContext context) {
    final events = const [
      ('Clock in', '08:32 AM', 'Makati HQ', Icons.login_rounded,
          AppColors.brandRed),
      ('Break start', '12:05 PM', 'Lunch break', Icons.coffee_rounded,
          AppColors.inkSoft),
      ('Break end', '12:53 PM', 'Back to work', Icons.work_rounded,
          AppColors.inkSoft),
      ('In progress', 'Now', 'Working…', Icons.more_horiz_rounded,
          AppColors.brandRed),
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
