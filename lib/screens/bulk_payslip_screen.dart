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
  final _search = TextEditingController();
  String _query = '';

  /// Year filter ('All' or e.g. '2026'); defaults to the newest year.
  late String _year = _years.isEmpty ? 'All' : _years.first;

  String _idOf(PayPeriod p) => '${p.year ?? ''}-${p.code}';

  /// Years present in the periods, newest first.
  List<String> get _years {
    final ys =
        widget.periods.map((p) => p.year).whereType<String>().toSet().toList()
          ..sort(
            (a, b) => (int.tryParse(b) ?? 0).compareTo(int.tryParse(a) ?? 0),
          );
    return ys;
  }

  /// Periods matching the year chip and the search (period no. or dates).
  List<PayPeriod> get _visible {
    final q = _query.trim().toLowerCase();
    return widget.periods.where((p) {
      if (_year != 'All' && p.year != _year) return false;
      if (q.isEmpty) return true;
      final code = p.code.toLowerCase();
      return code.contains(q) ||
          (int.tryParse(code)?.toString() ?? '') == q ||
          p.range.toLowerCase().contains(q) ||
          'period ${p.code} ${p.year ?? ''}'.toLowerCase().contains(q);
    }).toList();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _toggle(String id) {
    setState(() {
      if (!_selected.add(id)) _selected.remove(id);
    });
  }

  /// Selects / clears the periods currently shown (other years keep theirs).
  void _toggleAll() {
    final ids = _visible.map(_idOf).toList();
    setState(() {
      if (ids.every(_selected.contains)) {
        _selected.removeAll(ids);
      } else {
        _selected.addAll(ids);
      }
    });
  }

  Widget _filters() {
    final chips = ['All', ..._years];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            controller: _search,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Search period no. or month (e.g. 12, Oct)',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () => setState(() {
                        _search.clear();
                        _query = '';
                      }),
                    ),
            ),
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            itemCount: chips.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final y = chips[i];
              final on = y == _year;
              return ChoiceChip(
                label: Text(y),
                selected: on,
                showCheckmark: false,
                onSelected: (_) => setState(() => _year = y),
                selectedColor: AppColors.brandRed,
                backgroundColor: AppColors.card,
                side: BorderSide(
                  color: on ? AppColors.brandRed : AppColors.line,
                ),
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: on ? Colors.white : AppColors.inkSoft,
                ),
              );
            },
          ),
        ),
      ],
    );
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
          showToast(
            context,
            'The password you entered is incorrect.',
            isSuccess: false,
            title: 'Incorrect Password',
          );
        }
        return;
      }

      // Fetch the selected payslips (newest first, across all years).
      final ids = widget.periods.map(_idOf).where(_selected.contains).toList();
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
        showToast(
          context,
          "Couldn't prepare the payslips.\n($e)",
          isSuccess: false,
          title: 'Download Failed',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    final allSelected =
        visible.isNotEmpty && visible.map(_idOf).every(_selected.contains);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Download Payslips'),
        actions: [
          TextButton(
            onPressed: visible.isEmpty ? null : _toggleAll,
            child: Text(
              allSelected ? 'Clear' : 'Select all',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      body: widget.periods.isEmpty
          ? const Center(
              child: Text(
                'No pay periods available.',
                style: TextStyle(color: AppColors.inkSoft),
              ),
            )
          : Column(
              children: [
                _filters(),
                Expanded(
                  child: visible.isEmpty
                      ? const Center(
                          child: Text(
                            'No payslips match your filter.',
                            style: TextStyle(color: AppColors.inkSoft),
                          ),
                        )
                      : _list(visible),
                ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_busy || _selected.isEmpty) ? null : _download,
              icon: const Icon(Icons.print_rounded, size: 18),
              label: Text(
                _selected.isEmpty
                    ? 'Select payslips to download'
                    : 'Download ${_selected.length} payslip(s)',
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _list(List<PayPeriod> periods) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      itemCount: periods.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final p = periods[i];
        final id = _idOf(p);
        final on = _selected.contains(id);
        return Material(
          color: on ? AppColors.dangerSoft : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _toggle(id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: on ? AppColors.brandRed : AppColors.line,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    on ? Icons.check_circle_rounded : Icons.circle_outlined,
                    color: on ? AppColors.brandRed : AppColors.inkFaint,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Period ${p.code}'
                          '${p.year != null ? ' • ${p.year}' : ''}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          p.range,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
