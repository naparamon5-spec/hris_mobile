import 'package:flutter/material.dart';

import '../data/hris_api.dart';
import '../data/mock_data.dart';
import '../theme/app_colors.dart';
import '../widgets/async_view.dart';
import '../widgets/downloadable.dart';

/// Payslip detail, shown after the identity check. Renders the earnings and
/// deductions breakdown inside a capture boundary so it can be saved/shared as
/// an image ("download the file").
class PayslipDetailScreen extends StatefulWidget {
  const PayslipDetailScreen({
    super.key,
    required this.id,
    required this.title,
  });

  /// `<pay_year>-<pay_period>`.
  final String id;
  final String title;

  @override
  State<PayslipDetailScreen> createState() => _PayslipDetailScreenState();
}

class _PayslipDetailScreenState extends State<PayslipDetailScreen> {
  final _boundaryKey = GlobalKey();
  bool _downloading = false;

  Future<void> _download() async {
    if (_downloading) return;
    setState(() => _downloading = true);
    await captureAndShare(
      context,
      _boundaryKey,
      'Payslip_${widget.id}',
      shareText: 'Payslip ${widget.id}',
    );
    if (mounted) setState(() => _downloading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Payslip')),
      body: AsyncView<Payslip>(
        load: () => HrisApi.instance.payslip(widget.id),
        useGlobalLoader: true,
        builder: (context, slip) => Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: RepaintBoundary(
                  key: _boundaryKey,
                  child: _PayslipSheet(id: widget.id, slip: slip),
                ),
              ),
            ),
            _DownloadBar(
              busy: _downloading,
              onDownload: _download,
            ),
          ],
        ),
      ),
    );
  }
}

class _PayslipSheet extends StatelessWidget {
  const _PayslipSheet({required this.id, required this.slip});

  final String id;
  final Payslip slip;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PAYSLIP',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
                color: AppColors.brandRed,
              )),
          const SizedBox(height: 4),
          Text(slip.period.isEmpty ? 'Period $id' : slip.period,
              style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink)),
          if (slip.payDate != null && slip.payDate!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Pay date • ${slip.payDate}',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkSoft)),
          ],
          const SizedBox(height: 18),
          _section('Earnings', slip.earnings, AppColors.success),
          const SizedBox(height: 16),
          _section('Deductions', slip.deductionItems, AppColors.brandRed),
          const SizedBox(height: 18),
          const Divider(height: 1, color: AppColors.line),
          const SizedBox(height: 14),
          if (slip.gross != null)
            _totalRow('Total Earnings', slip.gross!, bold: false),
          if (slip.deductions != null)
            _totalRow('Total Deductions', slip.deductions!, bold: false),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.dangerSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Net Pay',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink)),
                Text(slip.net,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.brandRed)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<PayItem> items, Color dot) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink)),
          ],
        ),
        const SizedBox(height: 10),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.only(left: 16, bottom: 4),
            child: Text('No items',
                style: TextStyle(
                    fontSize: 13,
                    color: AppColors.inkFaint,
                    fontWeight: FontWeight.w500)),
          )
        else
          ...items.map((e) => Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(e.label,
                          style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.inkSoft)),
                    ),
                    const SizedBox(width: 12),
                    Text(e.amount,
                        style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink)),
                  ],
                ),
              )),
      ],
    );
  }

  Widget _totalRow(String label, String value, {bool bold = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                  color: AppColors.inkSoft)),
          Text(value,
              style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
                  color: AppColors.ink)),
        ],
      ),
    );
  }
}

/// Bottom action bar with a single "Download / Save as image" button.
class _DownloadBar extends StatelessWidget {
  const _DownloadBar({required this.busy, required this.onDownload});

  final bool busy;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: busy ? null : onDownload,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandRed,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.2, color: Colors.white),
                  )
                : const Icon(Icons.download_rounded, size: 20),
            label: Text(busy ? 'Preparing…' : 'Download / Save as Image',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w800)),
          ),
        ),
      ),
    );
  }
}
