import 'package:flutter/material.dart';

import '../data/hris_api.dart';
import '../theme/app_colors.dart';
import '../widgets/async_view.dart';
import 'bulk_payslip_screen.dart';
import 'period_grid_screen.dart';

/// PAYSLIP — a year selector over a grid of pay-period cards, loaded from the
/// backend `/auth/pay-periods` endpoint.
class PayslipScreen extends StatelessWidget {
  const PayslipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Payslip')),
      body: AsyncView<List<PayPeriod>>(
        load: () => HrisApi.instance.payPeriods(type: 'payslip'),
        useGlobalLoader: true,
        builder: (context, periods) {
          return PeriodGridScreen(
            title: 'Payslip',
            idLabel: 'PayslipID',
            kind: PeriodKind.payslip,
            years: const ['2026', '2025', '2024'],
            embedded: true,
            headerAction: _DownloadButton(
              onTap: periods.isEmpty
                  ? null
                  : () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => BulkPayslipScreen(periods: periods),
                        ),
                      ),
            ),
            periods: periods
                .map((p) => PeriodEntry(p.code, [p.range], year: p.year))
                .toList(),
          );
        },
      ),
    );
  }
}

/// Compact download button shown next to the year dropdown on the payslip page.
class _DownloadButton extends StatelessWidget {
  const _DownloadButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: enabled ? AppColors.dangerSoft : AppColors.fieldFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: enabled ? AppColors.brandRed : AppColors.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.file_download_outlined,
                size: 18,
                color: enabled ? AppColors.brandRed : AppColors.inkFaint),
            const SizedBox(width: 6),
            Text(
              'Download',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: enabled ? AppColors.brandRed : AppColors.inkFaint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
