import 'package:flutter/material.dart';

import '../data/hris_api.dart';
import '../theme/app_colors.dart';
import '../widgets/async_view.dart';
import 'period_grid_screen.dart';

/// TIMESHEET — a year selector over a grid of pay-period cards, loaded from the
/// backend `/auth/pay-periods` endpoint.
class TimesheetScreen extends StatelessWidget {
  const TimesheetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Timesheet')),
      body: AsyncView<List<PayPeriod>>(
        load: () => HrisApi.instance.payPeriods(type: 'timesheet'),
        useGlobalLoader: true,
        builder: (context, periods) => PeriodGridScreen(
          title: 'Timesheet',
          idLabel: 'TimesheetID',
          kind: PeriodKind.timesheet,
          years: const ['2026', '2025', '2024'],
          embedded: true,
          periods: periods
              .map((p) => PeriodEntry(p.code, [p.range], year: p.year))
              .toList(),
        ),
      ),
    );
  }
}
