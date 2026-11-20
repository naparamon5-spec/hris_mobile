import 'package:flutter/material.dart';

import '../screens/approvals_center_screen.dart' show approvalStatusColor;
import '../theme/app_colors.dart';
import 'ui.dart';

/// The request an approver just decided from an approval email, with the same
/// details as the email and the website result page (the server sends them):
/// heading, Requested By, Record Details (Date Applied / Sent / Resent), the
/// rows and Total Hours, plus the status after the decision.
class EmailDecisionSheet extends StatelessWidget {
  const EmailDecisionSheet({super.key, required this.details, required this.status});

  final Map<String, dynamic> details;
  final String status;

  String _s(String key) => '${details[key] ?? ''}'.trim();

  @override
  Widget build(BuildContext context) {
    final isCa = details['isCa'] == true;
    final isOther = details['isOther'] == true;
    final rows = (details['rows'] as List? ?? const [])
        .whereType<Map>()
        .map((r) => r.cast<String, dynamic>())
        .toList();
    final otherParts = _s('otherDetail').split(' : ');

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    _s('heading'),
                    style: const TextStyle(
                        fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.ink),
                  ),
                ),
                const SizedBox(width: 10),
                StatusPill(label: status, color: approvalStatusColor(status)),
              ],
            ),
            const SizedBox(height: 18),
            const _Label('Requested By'),
            Text(_s('name'),
                style: const TextStyle(
                    fontSize: 15.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
            if (_s('position').isNotEmpty)
              Text(_s('position'), style: const TextStyle(color: AppColors.inkSoft)),
            if (_s('department').isNotEmpty)
              Text(_s('department'), style: const TextStyle(color: AppColors.inkSoft)),
            const SizedBox(height: 18),
            const _Label('Record Details'),
            if (isOther) ...[
              _Fact('Request #', _s('num')),
              _Fact('Date Applied', _s('applied')),
              _Fact('Application', _s('appType')),
              if (_s('otherDetail').isNotEmpty)
                _Fact(otherParts.first, otherParts.skip(1).join(' : ')),
            ] else ...[
              _Fact('Date Applied', _s('applied')),
              _Fact('Date Sent', _s('sent')),
              _Fact('Date Resent', _s('resent')),
              if (isCa) _Fact('Call Approval Date', _s('caDate')),
            ],
            if (!isOther) ...[
              const SizedBox(height: 14),
              for (final r in rows) _RowCard(row: r, isCa: isCa),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('Total Hours',
                          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)),
                    ),
                    Text(_s('totalHours'),
                        style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: .8, color: AppColors.inkFaint),
        ),
      );
}

class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 130,
              child: Text(label, style: const TextStyle(color: AppColors.inkSoft)),
            ),
            Expanded(
              child: Text(value.isEmpty ? '—' : value,
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
            ),
          ],
        ),
      );
}

/// One row of the request (Date From / Date To / Reason / Applied Hours, or
/// for Call Approval Time From / Time To / Customer / Purpose / Applied Hours).
class _RowCard extends StatelessWidget {
  const _RowCard({required this.row, required this.isCa});
  final Map<String, dynamic> row;
  final bool isCa;

  String _s(String key) => '${row[key] ?? ''}'.trim();

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.fieldFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          children: [
            _Fact(isCa ? 'Time From' : 'Date From', _s('from')),
            _Fact(isCa ? 'Time To' : 'Date To', _s('to')),
            if (isCa) _Fact('Customer', _s('customer')),
            _Fact(isCa ? 'Purpose' : 'Reason', _s('reason')),
            _Fact('Applied Hours', _s('hours')),
          ],
        ),
      );
}
