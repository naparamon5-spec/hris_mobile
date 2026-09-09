import 'package:flutter/material.dart';

import 'period_grid_screen.dart';

/// PAYSLIP — a year selector over a grid of pay-period cards (a single
/// MM/DD/YYYY date range each), mirroring the HRIS web payslip page.
class PayslipScreen extends StatelessWidget {
  const PayslipScreen({super.key});

  static const _periods = <PeriodEntry>[
    PeriodEntry('001', ['12/16/2025 – 01/06/2026']),
    PeriodEntry('002', ['01/07/2026 – 01/22/2026']),
    PeriodEntry('003', ['01/23/2026 – 02/06/2026']),
    PeriodEntry('004', ['02/07/2026 – 02/20/2026']),
    PeriodEntry('005', ['02/21/2026 – 03/05/2026']),
    PeriodEntry('006', ['03/06/2026 – 03/22/2026']),
    PeriodEntry('007', ['03/23/2026 – 04/06/2026']),
    PeriodEntry('008', ['04/07/2026 – 04/21/2026']),
    PeriodEntry('009', ['04/22/2026 – 05/06/2026']),
    PeriodEntry('010', ['05/07/2026 – 05/22/2026']),
    PeriodEntry('011', ['05/23/2026 – 06/06/2026']),
    PeriodEntry('012', ['06/07/2026 – 06/22/2026']),
    PeriodEntry('013', ['06/23/2026 – 07/06/2026']),
    PeriodEntry('014', ['07/07/2026 – 07/22/2026']),
    PeriodEntry('015', ['07/23/2026 – 08/06/2026']),
    PeriodEntry('016', ['08/07/2026 – 08/22/2026']),
    PeriodEntry('017', ['08/23/2026 – 09/06/2026']),
    PeriodEntry('018', ['09/07/2026 – 09/22/2026']),
    PeriodEntry('019', ['09/23/2026 – 10/06/2026']),
    PeriodEntry('020', ['10/07/2026 – 10/22/2026']),
    PeriodEntry('021', ['10/23/2026 – 11/06/2026']),
    PeriodEntry('022', ['11/07/2026 – 11/22/2026']),
    PeriodEntry('023', ['11/23/2026 – 12/06/2026']),
    PeriodEntry('024', ['12/07/2026 – 12/22/2026']),
  ];

  @override
  Widget build(BuildContext context) {
    return const PeriodGridScreen(
      title: 'Payslip',
      idLabel: 'PayslipID',
      years: ['2026', '2025', '2024'],
      periods: _periods,
    );
  }
}
