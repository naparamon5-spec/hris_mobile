import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/ui.dart';
import '../widgets/verify_identity.dart';
import 'payslip_detail_screen.dart';
import 'timesheet_detail_screen.dart';

/// Which detail a period card opens (behind an identity check).
enum PeriodKind { payslip, timesheet }

/// One pay/timesheet period shown as a card. [dates] holds one or two
/// pre-formatted date strings (Timesheet shows two, Payslip shows one range).
class PeriodEntry {
  const PeriodEntry(this.period, this.dates, {this.year});

  final String period;
  final List<String> dates;

  /// Calendar year this period belongs to, used by the year filter.
  final String? year;
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
    required this.kind,
    this.embedded = false,
    this.headerAction,
    this.onRefresh,
  });

  /// When true, renders only the body (the parent supplies Scaffold + AppBar).
  final bool embedded;

  /// Optional widget shown next to the year dropdown (e.g. a bulk-download
  /// button on the payslip page).
  final Widget? headerAction;

  /// Optional pull-to-refresh callback.
  final Future<void> Function()? onRefresh;

  final String title;

  /// e.g. 'TimesheetID' or 'PayslipID'.
  final String idLabel;
  final List<String> years;
  final List<PeriodEntry> periods;
  final PeriodKind kind;

  @override
  State<PeriodGridScreen> createState() => _PeriodGridScreenState();
}

class _PeriodGridScreenState extends State<PeriodGridScreen> {
  late String _year;

  /// Years actually present in the data (falls back to the passed-in list).
  List<String> get _years {
    final fromData = widget.periods
        .map((p) => p.year)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    return fromData.isNotEmpty ? fromData : widget.years;
  }

  /// Periods for the selected year (entries with no year always show).
  List<PeriodEntry> get _filtered => widget.periods
      .where((p) => p.year == null || p.year == _year)
      .toList();

  @override
  void initState() {
    super.initState();
    final ys = _years;
    _year = ys.isNotEmpty ? ys.first : widget.years.first;
  }

  // Clean bottom-sheet year picker (consistent with the app's other pickers).
  Future<void> _pickYear(BuildContext context, List<String> years) async {
    final picked = await showPremiumBottomSheet<String>(
      context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text('Select Year',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            for (final y in years) ...[
              _yearOption(ctx, y),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
    if (picked != null && mounted) setState(() => _year = picked);
  }

  Widget _yearOption(BuildContext ctx, String y) {
    final selected = y == _year;
    return Material(
      color: selected ? AppColors.dangerSoft : AppColors.fieldFill,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.pop(ctx, y),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.brandRed : AppColors.line,
              width: selected ? 1.6 : 1.3,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.event_rounded,
                  size: 20,
                  color: selected ? AppColors.brandRed : AppColors.inkSoft),
              const SizedBox(width: 12),
              Expanded(
                child: Text(y,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: selected ? AppColors.brandRed : AppColors.ink,
                    )),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded,
                    color: AppColors.brandRed, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final years = _years;
    final periods = _filtered;
    final body = SafeArea(
        top: !widget.embedded,
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.headerAction != null) ...[
                        widget.headerAction!,
                        const SizedBox(width: 10),
                      ],
                      GestureDetector(
                        onTap: () => _pickYear(context, years),
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: AppColors.fieldFill,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.line),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.event_rounded,
                                  size: 16, color: AppColors.inkSoft),
                              const SizedBox(width: 8),
                              Text(
                                _year,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.keyboard_arrow_down_rounded,
                                  size: 20, color: AppColors.inkSoft),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: widget.onRefresh != null
                  ? RefreshIndicator(
                      color: AppColors.brandRed,
                      onRefresh: widget.onRefresh!,
                      child: periods.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                const SizedBox(height: 80),
                                Center(
                                  child: Text(
                                    'No ${widget.title.toLowerCase()} records found for $_year',
                                    style: const TextStyle(
                                      color: AppColors.inkSoft,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                              itemCount: periods.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, i) => _PeriodCard(
                                year: periods[i].year ?? _year,
                                idLabel: widget.idLabel,
                                entry: periods[i],
                                kind: widget.kind,
                                title: widget.title,
                              ),
                            ),
                    )
                  : periods.isEmpty
                      ? Center(
                          child: Text(
                            'No ${widget.title.toLowerCase()} records found for $_year',
                            style: const TextStyle(
                              color: AppColors.inkSoft,
                              fontSize: 14,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                          itemCount: periods.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) => _PeriodCard(
                            year: periods[i].year ?? _year,
                            idLabel: widget.idLabel,
                            entry: periods[i],
                            kind: widget.kind,
                            title: widget.title,
                          ),
                        ),
            ),
          ],
        ));
    if (widget.embedded) return body;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(widget.title)),
      body: body,
    );
  }
}

class _PeriodCard extends StatelessWidget {
  const _PeriodCard({
    required this.year,
    required this.idLabel,
    required this.entry,
    required this.kind,
    required this.title,
  });

  final String year;
  final String idLabel;
  final PeriodEntry entry;
  final PeriodKind kind;
  final String title;

  // Payslip is gated behind a password check; timesheet opens directly.
  Future<void> _open(BuildContext context) async {
    if (kind == PeriodKind.payslip) {
      final ok = await verifyIdentity(
        context,
        message:
            'For your privacy, please confirm your password to view this payslip.',
      );
      if (!ok || !context.mounted) return;
    }
    final id = '$year-${entry.period}';
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => kind == PeriodKind.payslip
          ? PayslipDetailScreen(id: id, title: title)
          : TimesheetDetailScreen(id: id, title: title),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: () => _open(context),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$idLabel $year:${entry.period}',
                  style: TextStyle(
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
          if (kind == PeriodKind.payslip) ...[
            const Icon(Icons.lock_outline_rounded,
                size: 16, color: AppColors.inkFaint),
            const SizedBox(width: 2),
          ],
          const Icon(Icons.chevron_right_rounded, color: AppColors.inkFaint),
        ],
      ),
    );
  }
}
