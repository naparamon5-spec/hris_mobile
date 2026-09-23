import 'package:flutter/material.dart';

import '../data/hris_api.dart';
import '../theme/app_colors.dart';
import '../widgets/async_view.dart';
import 'bulk_payslip_screen.dart';
import 'period_grid_screen.dart';

/// PAYSLIP — a year selector over a grid of pay-period cards, loaded from the
/// backend `/auth/pay-periods` endpoint, with pull-to-refresh and AppBar refresh.
class PayslipScreen extends StatefulWidget {
  const PayslipScreen({super.key});

  @override
  State<PayslipScreen> createState() => _PayslipScreenState();
}

class _PayslipScreenState extends State<PayslipScreen> {
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
        title: const Text('Payslip'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => _controller.reload(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: AsyncView<List<PayPeriod>>(
        controller: _controller,
        load: () => HrisApi.instance.payPeriods(type: 'payslip'),
        useGlobalLoader: true,
        builder: (context, periods) {
          return PeriodGridScreen(
            title: 'Payslip',
            idLabel: 'PayslipID',
            kind: PeriodKind.payslip,
            years: const ['2026', '2025', '2024'],
            embedded: true,
            onRefresh: _handleRefresh,
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
        width: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.fieldFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line),
        ),
        child: Icon(Icons.file_download_outlined,
            size: 20,
            color: enabled ? AppColors.inkSoft : AppColors.inkFaint),
      ),
    );
  }
}
