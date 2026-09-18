import 'package:flutter/material.dart';

import '../data/hris_api.dart';
import '../data/mock_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/async_view.dart';
import '../widgets/ui.dart';

class PayrollScreen extends StatefulWidget {
  const PayrollScreen({super.key});

  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen> {
  final _reload = AsyncViewController();

  @override
  void dispose() {
    _reload.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: canPop,
        title: const Text('Payroll'),
        actions: [
          IconButton(
            onPressed: () => showToast(context, 'Downloading payslip PDF…'),
            icon: const Icon(Icons.file_download_outlined),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: AsyncView<(List<Payslip>, Payslip?)>(
          controller: _reload,
          load: () async {
            final list = await HrisApi.instance.payslips();
            final latest = list.isEmpty
                ? null
                : await HrisApi.instance.payslip(list.first.id!);
            return (list, latest);
          },
          useGlobalLoader: true,
          builder: (context, data) {
            final (payslips, latest) = data;
            return RefreshIndicator(
              color: AppColors.brandRed,
              onRefresh: () async => _reload.reload(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  if (latest != null) _LatestPayslip(payslip: latest),
                  const SizedBox(height: 24),
                  const SectionHeader(title: 'Breakdown'),
                  const SizedBox(height: 14),
                  _Breakdown(),
                  const SizedBox(height: 24),
                  SectionHeader(
                      title: 'Payslip history',
                      actionLabel: 'Export all',
                      onAction: () =>
                          showToast(context, 'Exporting history…')),
                  const SizedBox(height: 14),
                  ...payslips.map((p) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _PayslipRow(payslip: p),
                      )),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LatestPayslip extends StatelessWidget {
  const _LatestPayslip({required this.payslip});
  final Payslip payslip;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Net pay • ${payslip.period}',
                style: const TextStyle(
                  color: AppColors.inkSoft,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              StatusPill(
                label: payslip.status,
                color: AppColors.success,
                icon: Icons.check_circle_rounded,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            payslip.net,
            style: TextStyle(
              color: AppColors.brandRed,
              fontSize: 34,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            payslip.payDate != null
                ? 'Deposited on ${payslip.payDate}'
                : 'Pending deposit',
            style: const TextStyle(
              color: AppColors.inkSoft,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.fieldFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _chip('Gross', payslip.gross ?? '—'),
                _divider(),
                _chip('Deductions', payslip.deductions ?? '—'),
                _divider(),
                _chip('Net', payslip.net),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value) => Expanded(
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
              ),
            ),
            const SizedBox(height: 2),
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
      );

  Widget _divider() => Container(
        width: 1,
        height: 24,
        color: AppColors.line,
      );
}

class _Breakdown extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        children: [
          _line('Basic salary', '₱ 95,000.00', AppColors.ink, false),
          _line('Allowances', '₱ 12,000.00', AppColors.ink, false),
          _line('Overtime', '₱ 3,000.00', AppColors.success, false),
          const Divider(height: 28),
          _line('SSS contribution', '– ₱ 1,350.00', AppColors.brandRed, false),
          _line('PhilHealth', '– ₱ 1,375.00', AppColors.brandRed, false),
          _line('Pag-IBIG', '– ₱ 200.00', AppColors.brandRed, false),
          _line('Withholding tax', '– ₱ 20,655.00', AppColors.brandRed, false),
          const Divider(height: 28),
          _line('Net pay', '₱ 86,420.00', AppColors.ink, true),
        ],
      ),
    );
  }

  Widget _line(String label, String value, Color valueColor, bool bold) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: bold ? 15.5 : 14,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                  color: bold ? AppColors.ink : AppColors.inkSoft)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontSize: bold ? 16 : 14,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
                  color: valueColor)),
        ],
      ),
    );
  }
}

class _PayslipRow extends StatelessWidget {
  const _PayslipRow({required this.payslip});
  final Payslip payslip;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(14),
      onTap: () => showToast(context, 'Opening ${payslip.period} payslip'),
      child: Row(
        children: [
          IconBadge(
              icon: Icons.receipt_long_rounded,
              color: AppColors.brandMaroon,
              size: 46,
              iconSize: 23),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(payslip.period,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 14.5)),
                const SizedBox(height: 3),
                Text('Net • ${payslip.net}',
                    style: const TextStyle(
                        color: AppColors.inkSoft,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          StatusPill(label: payslip.status, color: AppColors.success),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: AppColors.inkFaint),
        ],
      ),
    );
  }
}
