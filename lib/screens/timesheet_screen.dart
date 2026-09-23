import 'package:flutter/material.dart';

import '../data/hris_api.dart';
import '../theme/app_colors.dart';
import '../widgets/async_view.dart';
import 'period_grid_screen.dart';

/// TIMESHEET — a year selector over a grid of pay-period cards, loaded from the
/// backend `/auth/pay-periods` endpoint, with pull-to-refresh and AppBar refresh.
class TimesheetScreen extends StatefulWidget {
  const TimesheetScreen({super.key});

  @override
  State<TimesheetScreen> createState() => _TimesheetScreenState();
}

class _TimesheetScreenState extends State<TimesheetScreen> {
  final _controller = AsyncViewController();

  Future<void> _handleRefresh() async {
    _controller.reload();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Timesheet'),
      ),
      body: AsyncView<List<PayPeriod>>(
        controller: _controller,
        load: () => HrisApi.instance.payPeriods(type: 'timesheet'),
        useGlobalLoader: true,
        builder: (context, periods) => PeriodGridScreen(
          title: 'Timesheet',
          idLabel: 'TimesheetID',
          kind: PeriodKind.timesheet,
          years: const ['2026', '2025', '2024'],
          embedded: true,
          onRefresh: _handleRefresh,
          periods: periods
              .map((p) => PeriodEntry(p.code, [p.range], year: p.year))
              .toList(),
        ),
      ),
    );
  }
}
