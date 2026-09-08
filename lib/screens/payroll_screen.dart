import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

class PayrollScreen extends StatelessWidget {
  const PayrollScreen({super.key});

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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
          children: [
            _LatestPayslip(),
            const SizedBox(height: 24),
            const SectionHeader(title: 'Breakdown'),
            const SizedBox(height: 14),
            _Breakdown(),
            const SizedBox(height: 24),
            SectionHeader(
                title: 'Payslip history',
                actionLabel: 'Export all',
                onAction: () => showToast(context, 'Exporting history…')),
            const SizedBox(height: 14),
            ...kPayslips.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PayslipRow(payslip: p),
                )),
          ],
        ),
      ),
    );
  }
}

class _LatestPayslip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: kBrandShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Net pay • May 2026',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5)),
              const Spacer(),
              StatusPill(
                  label: 'Paid',
                  color: Colors.white,
                  bg: Colors.white.withValues(alpha: 0.2),
                  icon: Icons.check_circle_rounded),
            ],
          ),
          const SizedBox(height: 14),
          const Text('₱ 86,420.00',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  height: 1,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Deposited to BPI •••• 4821 on May 30',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.88),
                  fontSize: 13)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _chip('Gross', '₱ 110,000'),
                _divider(),
                _chip('Deductions', '₱ 23,580'),
                _divider(),
                _chip('Net', '₱ 86,420'),
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
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14)),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );

  Widget _divider() => Container(
      width: 1, height: 30, color: Colors.white.withValues(alpha: 0.2));
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
