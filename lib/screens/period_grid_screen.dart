import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/ui.dart';

/// One pay/timesheet period shown as a card. [dates] holds one or two
/// pre-formatted date strings (Timesheet shows two, Payslip shows one range).
class PeriodEntry {
  const PeriodEntry(this.period, this.dates);

  final String period;
  final List<String> dates;
}

/// Simple year-selector + card list used by both Timesheet and Payslip.
/// Clean single-column layout (Sprout-style) that auto-sizes to its content,
/// so cards never overflow.
class PeriodGridScreen extends StatefulWidget {
  const PeriodGridScreen({
    super.key,
    required this.title,
    required this.idLabel,
    required this.years,
    required this.periods,
  });

  final String title;

  /// e.g. 'TimesheetID' or 'PayslipID'.
  final String idLabel;
  final List<String> years;
  final List<PeriodEntry> periods;

  @override
  State<PeriodGridScreen> createState() => _PeriodGridScreenState();
}

class _PeriodGridScreenState extends State<PeriodGridScreen> {
  late String _year = widget.years.first;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: AppColors.ink,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.fieldFill,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _year,
                        icon: const Icon(Icons.unfold_more_rounded,
                            size: 18, color: AppColors.inkSoft),
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                        dropdownColor: AppColors.card,
                        items: widget.years
                            .map((y) => DropdownMenuItem(
                                  value: y,
                                  child: Text(y),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _year = v ?? _year),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                itemCount: widget.periods.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) => _PeriodCard(
                  year: _year,
                  idLabel: widget.idLabel,
                  entry: widget.periods[i],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodCard extends StatelessWidget {
  const _PeriodCard({
    required this.year,
    required this.idLabel,
    required this.entry,
  });

  final String year;
  final String idLabel;
  final PeriodEntry entry;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: () => showToast(context, 'Open $idLabel $year:${entry.period}'),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$idLabel $year:${entry.period}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandRed,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Period ${entry.period}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 13, color: AppColors.inkSoft),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        entry.dates.join('  –  '),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.inkSoft,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.inkFaint),
        ],
      ),
    );
  }
}
