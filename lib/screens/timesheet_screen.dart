import 'package:flutter/material.dart';

import 'period_grid_screen.dart';

/// TIMESHEET — a year selector over a grid of pay-period cards (two calendar
/// dates each), mirroring the HRIS web timesheet page.
class TimesheetScreen extends StatelessWidget {
  const TimesheetScreen({super.key});

  static const _periods = <PeriodEntry>[
    PeriodEntry('001', ['December-16', 'January-06']),
    PeriodEntry('002', ['January-07', 'January-22']),
    PeriodEntry('003', ['January-23', 'February-06']),
    PeriodEntry('004', ['February-07', 'February-20']),
    PeriodEntry('005', ['February-21', 'March-05']),
    PeriodEntry('006', ['March-06', 'March-22']),
    PeriodEntry('007', ['March-23', 'April-06']),
    PeriodEntry('008', ['April-07', 'April-21']),
    PeriodEntry('009', ['April-22', 'May-06']),
    PeriodEntry('010', ['May-07', 'May-22']),
    PeriodEntry('011', ['May-23', 'June-06']),
    PeriodEntry('012', ['June-07', 'June-22']),
    PeriodEntry('013', ['June-23', 'July-06']),
    PeriodEntry('014', ['July-07', 'July-22']),
    PeriodEntry('015', ['July-23', 'August-06']),
    PeriodEntry('016', ['August-07', 'August-22']),
    PeriodEntry('017', ['August-23', 'September-06']),
    PeriodEntry('018', ['September-07', 'September-22']),
    PeriodEntry('019', ['September-23', 'October-06']),
    PeriodEntry('020', ['October-07', 'October-22']),
    PeriodEntry('021', ['October-23', 'November-06']),
    PeriodEntry('022', ['November-07', 'November-22']),
    PeriodEntry('023', ['November-23', 'December-06']),
    PeriodEntry('024', ['December-07', 'December-22']),
  ];

  @override
  Widget build(BuildContext context) {
    return const PeriodGridScreen(
      title: 'Timesheet',
      idLabel: 'TimesheetID',
      years: ['2026', '2025', '2024'],
      periods: _periods,
    );
  }
}
