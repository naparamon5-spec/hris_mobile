import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/hris_api.dart';
import '../data/mock_data.dart';
import '../data/payslip_pdf.dart';
import '../theme/app_colors.dart';
import '../widgets/downloadable.dart';
import '../widgets/ui.dart';

/// Bulk payslip download: pick multiple pay periods, confirm with a password,
/// then export all selected payslips into one PDF (one per page) to save/print.
class BulkPayslipScreen extends StatefulWidget {
  const BulkPayslipScreen({super.key, required this.periods});

  final List<PayPeriod> periods;

  @override
  State<BulkPayslipScreen> createState() => _BulkPayslipScreenState();
}

class _BulkPayslipScreenState extends State<BulkPayslipScreen> {
  final Set<String> _selected = {};
  bool _busy = false;

  String _idOf(PayPeriod p) => '${p.year ?? ''}-${p.code}';

  void _toggle(String id) {
    setState(() {
      if (!_selected.add(id)) _selected.remove(id);
    });
  }

  void _toggleAll() {
    setState(() {
      if (_selected.length == widget.periods.length) {
        _selected.clear();
      } else {
        _selected
          ..clear()
          ..addAll(widget.periods.map(_idOf));
      }
    });
  }

  Future<void> _download() async {
    if (_busy || _selected.isEmpty) return;

    // Password verification before releasing the payslips.
    final password = await promptPassword(
      context,
      title: 'Confirm to download',
      message:
          'Enter your password to download ${_selected.length} payslip(s).',
      buttonLabel: 'Confirm',
    );
    if (password == null || !mounted) return;

    setState(() => _busy = true);
    showLoadingOverlay(context);
    try {
      final ok = await HrisApi.instance.verifyPassword(password);
      if (!ok) {
        if (mounted) hideLoadingOverlay(context);
        if (mounted) {
          showToast(context, 'The password you entered is incorrect.',
              isSuccess: false, title: 'Incorrect Password');
        }
        return;
      }

      // Fetch the selected payslips (in the order shown) and build one PDF.
      final ids = widget.periods
          .map(_idOf)
          .where(_selected.contains)
          .toList();
      final slips = <Payslip>[];
      for (final id in ids) {
        slips.add(await HrisApi.instance.payslip(id));
      }
      final bytes = await buildPayslipsPdf(slips);

      if (mounted) hideLoadingOverlay(context);
      if (mounted) {
        await sharePdfBytes(context, bytes, 'Payslips_${slips.length}');
      }
    } on ApiException catch (e) {
      if (mounted) hideLoadingOverlay(context);
      if (mounted) {
        showToast(context, e.message, isSuccess: false, title: 'Error');
      }
    } catch (e) {
      if (mounted) hideLoadingOverlay(context);
      if (mounted) {
        showToast(context, "Couldn't prepare the payslips.\n($e)",
            isSuccess: false, title: 'Download Failed');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allSelected =
        _selected.length == widget.periods.length && widget.periods.isNotEmpty;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Download Payslips'),
        actions: [
          TextButton(
            onPressed: widget.periods.isEmpty ? null : _toggleAll,
            child: Text(allSelected ? 'Clear' : 'Select all',
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: widget.periods.isEmpty
          ? const Center(
              child: Text('No pay periods available.',
                  style: TextStyle(color: AppColors.inkSoft)))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              itemCount: widget.periods.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final p = widget.periods[i];
                final id = _idOf(p);
                final on = _selected.contains(id);
                return Material(
                  color: on ? AppColors.dangerSoft : AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _toggle(id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: on ? AppColors.brandRed : AppColors.line),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            on
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            color: on ? AppColors.brandRed : AppColors.inkFaint,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Period ${p.code}'
                                    '${p.year != null ? ' • ${p.year}' : ''}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14)),
                                const SizedBox(height: 2),
                                Text(p.range,
                                    style: const TextStyle(
                                        fontSize: 12.5,
                                        color: AppColors.inkSoft)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_busy || _selected.isEmpty) ? null : _download,
              icon: const Icon(Icons.print_rounded, size: 18),
              label: Text(_selected.isEmpty
                  ? 'Select payslips to download'
                  : 'Download ${_selected.length} payslip(s)'),
            ),
          ),
        ),
      ),
    );
  }
}
