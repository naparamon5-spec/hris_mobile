import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/hris_api.dart';
import '../theme/app_colors.dart';
import '../widgets/ui.dart';
import 'create_other_request_screen.dart';

/// "Other Requests" — the employee's filed requests from th_request_head
/// (Request #, Date Applied, Request Type, Approved By, Status), with a search
/// box and status filter side by side, plus a Create button.
class OtherRequestsScreen extends StatefulWidget {
  const OtherRequestsScreen({
    super.key,
    this.initialRecordId,
    this.initialRecordNo,
  });

  final String? initialRecordId;
  final String? initialRecordNo;

  @override
  State<OtherRequestsScreen> createState() => _OtherRequestsScreenState();
}

class _OtherRequestsScreenState extends State<OtherRequestsScreen> {
  String _selectedStatus = 'All';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  List<_Other> _all = [];
  bool _loading = true;
  String? _error;
  bool _hasHandledInitial = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => showLoadingOverlay(context, immediate: true));
    try {
      final rows = await HrisApi.instance.requestRecords('other');
      if (!mounted) return;
      setState(() {
        _all = rows.map(_Other.fromRequest).toList();
        _loading = false;
      });
      if (!_hasHandledInitial) {
        _hasHandledInitial = true;
        _checkInitialRecord();
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } finally {
      if (mounted) hideLoadingOverlay(context);
    }
  }

  void _openDetailSheet(_Other record) {
    showPremiumBottomSheet(
      context,
      isScrollControlled: true,
      builder: (ctx) => _OtherRequestDetailSheet(
        record: record,
        onRefresh: _load,
      ),
    );
  }

  void _checkInitialRecord() {
    final targetId = widget.initialRecordId?.trim();
    final targetNo = widget.initialRecordNo?.trim();
    if ((targetId == null || targetId.isEmpty) &&
        (targetNo == null || targetNo.isEmpty)) {
      return;
    }

    _Other? match;
    for (final r in _all) {
      if ((targetNo != null &&
              targetNo.isNotEmpty &&
              (r.no.toLowerCase() == targetNo.toLowerCase() ||
                  targetNo.contains(r.no))) ||
          (targetId != null &&
              targetId.isNotEmpty &&
              (r.no.toLowerCase() == targetId.toLowerCase() ||
                  targetId.contains(r.no)))) {
        match = r;
        break;
      }
    }

    if (match != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _openDetailSheet(match!);
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterSheet() {
    showPremiumBottomSheet(
      context,
      builder: (ctx) => _StatusFilterSheet(
        current: _selectedStatus,
        onApply: (s) => setState(() => _selectedStatus = s),
      ),
    );
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateOtherRequestScreen()),
    );
    if (created == true) _load();
  }

  List<_Other> get _filtered {
    var list = _all.where((r) {
      if (_selectedStatus != 'All' && r.status != _selectedStatus) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final match = r.no.toLowerCase().contains(q) ||
            r.requestType.toLowerCase().contains(q) ||
            r.approvedBy.toLowerCase().contains(q) ||
            r.status.toLowerCase().contains(q);
        if (!match) return false;
      }
      return true;
    }).toList();
    // Newest first by Date Applied.
    list.sort((a, b) => b.sortDate.compareTo(a.sortDate));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final records = _filtered;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Other Requests'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        backgroundColor: AppColors.success,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.fieldFill,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded,
                              size: 18, color: AppColors.inkFaint),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink),
                              onChanged: (v) =>
                                  setState(() => _searchQuery = v),
                              decoration: const InputDecoration(
                                isCollapsed: true,
                                filled: false,
                                hintText: 'Search requests…',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                hintStyle: TextStyle(
                                    color: AppColors.inkFaint, fontSize: 14.5),
                              ),
                            ),
                          ),
                          if (_searchQuery.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                              child: const Icon(Icons.cancel_rounded,
                                  size: 17, color: AppColors.inkFaint),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _showFilterSheet,
                    child: Container(
                      height: 46,
                      width: 52,
                      decoration: BoxDecoration(
                        color: _selectedStatus != 'All'
                            ? AppColors.dangerSoft
                            : AppColors.fieldFill,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: _selectedStatus != 'All'
                                ? AppColors.brandRed
                                : AppColors.line),
                      ),
                      child: Icon(Icons.tune_rounded,
                          color: _selectedStatus != 'All'
                              ? AppColors.brandRed
                              : AppColors.inkSoft),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildList(records)),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<_Other> records) {
    if (_loading) return const SizedBox.shrink();
    if (_error != null) {
      return RefreshIndicator(
        color: AppColors.brandRed,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 60),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_rounded,
                      size: 48, color: AppColors.inkFaint),
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppColors.inkSoft)),
                  const SizedBox(height: 12),
                  OutlinedButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.brandRed,
      onRefresh: _load,
      child: records.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 40),
                _EmptyOtherRequests(),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
              itemCount: records.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _OtherRequestCard(
                record: records[i],
                onTap: () => _openDetailSheet(records[i]),
              ),
            ),
    );
  }
}

/// One Other Request row, with the fields needed for filtering/sorting.
class _Other {
  const _Other({
    required this.no,
    required this.dateApplied,
    required this.requestType,
    required this.approvedBy,
    required this.approvedDate,
    required this.status,
    required this.year,
    required this.month,
    required this.day,
  });

  final String no;
  final String dateApplied;
  final String requestType;
  final String approvedBy;
  final String approvedDate;
  final String status;
  final int year;
  final int month;
  final int day;

  DateTime get sortDate => DateTime(year, month, day);

  factory _Other.fromRequest(RequestRecord r) {
    final d = parseAppDateTime(r.dateApplied) ?? DateTime(2000);
    return _Other(
      no: r.no,
      dateApplied: r.dateApplied,
      requestType: r.requestType ?? '',
      approvedBy: r.approvedBy ?? '',
      approvedDate: r.approvedDate ?? '',
      status: r.status,
      year: d.year,
      month: d.month,
      day: d.day,
    );
  }
}

class _OtherRequestCard extends StatelessWidget {
  const _OtherRequestCard({required this.record, this.onTap});
  final _Other record;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('#${record.no}',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink)),
                  const SizedBox(width: 8),
                  if (record.requestType.isNotEmpty)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.fieldFill,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(record.requestType,
                          style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.inkSoft)),
                    ),
                  const Spacer(),
                  _StatusBadge(status: record.status),
                ],
              ),
              const SizedBox(height: 10),
              _row('Date Applied', record.dateApplied),
              if (record.approvedBy.isNotEmpty) ...[
                const SizedBox(height: 6),
                _row('Approved By', record.approvedBy),
              ],
              if (record.approvedDate.isNotEmpty) ...[
                const SizedBox(height: 6),
                _row('Approved Date', record.approvedDate),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Text(label.toUpperCase(),
                style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkFaint)),
          ),
          Expanded(
            child: Text(value.isEmpty ? '—' : value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink)),
          ),
        ],
      );
}

class _OtherRequestDetailSheet extends StatelessWidget {
  const _OtherRequestDetailSheet(
      {required this.record, required this.onRefresh});
  final _Other record;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Text('#${record.no}',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink)),
              const Spacer(),
              _StatusBadge(status: record.status),
            ],
          ),
          const SizedBox(height: 16),
          _detailRow('Request Type',
              record.requestType.isEmpty ? '—' : record.requestType),
          const SizedBox(height: 12),
          _detailRow('Date Applied',
              record.dateApplied.isEmpty ? '—' : record.dateApplied),
          if (record.approvedBy.isNotEmpty) ...[
            const SizedBox(height: 12),
            _detailRow('Approved By', record.approvedBy),
          ],
          if (record.approvedDate.isNotEmpty) ...[
            const SizedBox(height: 12),
            _detailRow('Approved Date', record.approvedDate),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: AppColors.inkFaint,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    Color bg;
    Color fg;
    if (s.contains('approved') && !s.contains('for') && !s.contains('dis')) {
      bg = AppColors.successSoft;
      fg = AppColors.success;
    } else if (s.contains('disapprove') || s.contains('reject')) {
      bg = AppColors.dangerSoft;
      fg = AppColors.brandRed;
    } else if (s.contains('for approval') || s.contains('pending')) {
      bg = AppColors.warningSoft;
      fg = AppColors.warning;
    } else if (s.contains('cancel')) {
      bg = AppColors.dangerSoft;
      fg = AppColors.brandRed;
    } else {
      bg = AppColors.ink.withValues(alpha: 0.08);
      fg = AppColors.ink;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w800, color: fg)),
    );
  }
}

class _EmptyOtherRequests extends StatelessWidget {
  const _EmptyOtherRequests();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: const BoxDecoration(
              color: AppColors.fieldFill,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.inbox_rounded,
                size: 32, color: AppColors.inkFaint),
          ),
          const SizedBox(height: 16),
          const Text('No requests found',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink)),
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Try adjusting your search or filters, or tap Create to file a '
              'new request.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.inkSoft),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// STATUS FILTER SHEET
// -----------------------------------------------------------------------------
class _StatusFilterSheet extends StatefulWidget {
  const _StatusFilterSheet({required this.current, required this.onApply});
  final String current;
  final ValueChanged<String> onApply;

  @override
  State<_StatusFilterSheet> createState() => _StatusFilterSheetState();
}

class _StatusFilterSheetState extends State<_StatusFilterSheet> {
  late String _status = widget.current;

  static const _statuses = [
    'All', 'Active', 'For Approval', 'Approved', 'Posted', 'Cancelled',
    'Disapproved'
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Filter Records',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() => _status = 'All'),
                child: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Status',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _statuses.map((s) {
              final sel = _status == s;
              return ChoiceChip(
                label: Text(s),
                selected: sel,
                selectedColor: AppColors.dangerSoft,
                labelStyle: TextStyle(
                  color: sel ? AppColors.brandRed : AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
                onSelected: (_) => setState(() => _status = s),
              );
            }).toList(),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(_status);
                Navigator.pop(context);
              },
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }
}
