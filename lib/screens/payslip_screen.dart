import 'package:flutter/material.dart';

import '../data/hris_api.dart';
import '../theme/app_colors.dart';
import '../widgets/async_view.dart';
import 'bulk_payslip_screen.dart';
import 'period_grid_screen.dart';

/// PAYSLIP — a year selector over a grid of pay-period cards, loaded from the
/// backend `/auth/pay-periods` endpoint.
class PayslipScreen extends StatefulWidget {
  const PayslipScreen({super.key});

  @override
  State<PayslipScreen> createState() => _PayslipScreenState();
}

class _PayslipScreenState extends State<PayslipScreen> {
  List<PayPeriod> _periods = const [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Payslip'),
        actions: [
          IconButton(
            tooltip: 'Download multiple',
            icon: const Icon(Icons.download_rounded),
            onPressed: _periods.isEmpty
                ? null
                : () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BulkPayslipScreen(periods: _periods),
                      ),
                    ),
          ),
        ],
      ),
      body: AsyncView<List<PayPeriod>>(
        load: () => HrisApi.instance.payPeriods(type: 'payslip'),
        useGlobalLoader: true,
        builder: (context, periods) {
          // Keep the loaded periods so the AppBar bulk-download action can use
          // them (set after this frame to avoid setState during build).
          if (!identical(_periods, periods)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _periods = periods);
            });
          }
          return PeriodGridScreen(
            title: 'Payslip',
            idLabel: 'PayslipID',
            kind: PeriodKind.payslip,
            years: const ['2026', '2025', '2024'],
            embedded: true,
            periods: periods
                .map((p) => PeriodEntry(p.code, [p.range], year: p.year))
                .toList(),
          );
        },
      ),
    );
  }
}
