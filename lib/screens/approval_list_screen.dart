import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/ui.dart';

/// A single approval record shown in the [ApprovalListScreen] table/cards.
///
/// Shared by Call Approval, Manual Arrival/Departure and Overtime — they all
/// use the same columns: reference no., date applied, a transaction date,
/// approver and approved date plus a status.
class ApprovalRecord {
  const ApprovalRecord(
    this.no,
    this.dateApplied,
    this.txnDate,
    this.approvedBy,
    this.approvedDate, {
    required this.year,
    required this.month,
    required this.day,
    this.status = 'Posted',
    this.witnessedBy = '',
  });

  final String no;
  final String dateApplied;

  /// The transaction date (CA date, arrival/departure date, overtime date).
  final String txnDate;
  final String approvedBy;
  final String approvedDate;

  /// Only used by Manual Arrival/Departure, which shows a witness instead of
  /// an approved date.
  final String witnessedBy;
  final int year;
  final int month;
  final int day;
  final String status;
}

/// Generic list screen used by the three request types that share the same
/// shape (Call Approval, Manual Arrival/Departure, Overtime). Mirrors the
/// Leave of Absence screen's look & feel (date-range pill, filter sheet,
/// search, sort, Create FAB and record cards).
class ApprovalListScreen extends StatefulWidget {
  const ApprovalListScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.txnDateLabel,
    required this.records,
    this.showWitnessedBy = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  /// Label for the transaction date column (e.g. 'CA date').
  final String txnDateLabel;
  final List<ApprovalRecord> records;

  /// When true the second detail row shows "Witnessed by / Approved by"
  /// (Manual Arrival/Departure); otherwise "Approved by / Approved date".
  final bool showWitnessedBy;

  @override
  State<ApprovalListScreen> createState() => _ApprovalListScreenState();
}

class _ApprovalListScreenState extends State<ApprovalListScreen> {
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime(2026, 8, 1),
    end: DateTime(2026, 10, 31),
  );
  String _dateLabel = 'Aug 2026 – Oct 2026';
  String _selectedStatus = 'All';
  String _searchQuery = '';
  bool _isSearching = false;
  bool _sortAscending = false;

  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _pickPreset(String label, DateTime start, DateTime end) {
    setState(() {
      _dateRange = DateTimeRange(start: start, end: end);
      _dateLabel = label;
    });
  }

  Future<void> _openCustomDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _dateRange,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.brandRed,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.ink,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final startStr = _formatMonthYear(picked.start);
      final endStr = _formatMonthYear(picked.end);
      setState(() {
        _dateRange = picked;
        _dateLabel = startStr == endStr ? startStr : '$startStr – $endStr';
      });
    }
  }

  String _formatMonthYear(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }

  void _showDateFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => _DateRangeSelectionSheet(
        currentLabel: _dateLabel,
        onSelectPreset: (label, start, end) {
          Navigator.pop(ctx);
          _pickPreset(label, start, end);
        },
        onCustomRange: () {
          Navigator.pop(ctx);
          _openCustomDateRangePicker();
        },
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => _FilterOptionsSheet(
        currentStatus: _selectedStatus,
        onApply: (status) {
          setState(() => _selectedStatus = status);
        },
      ),
    );
  }

  List<ApprovalRecord> get _filteredRecords {
    var list = widget.records.where((r) {
      final rDate = DateTime(r.year, r.month, r.day);
      final inRange = !rDate.isBefore(_dateRange.start) &&
          !rDate.isAfter(_dateRange.end.add(const Duration(days: 1)));
      if (!inRange) return false;

      if (_selectedStatus != 'All' && r.status != _selectedStatus) return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchNo = r.no.toLowerCase().contains(q);
        final matchApprover = r.approvedBy.toLowerCase().contains(q);
        if (!matchNo && !matchApprover) return false;
      }

      return true;
    }).toList();

    list.sort((a, b) {
      final dateA = DateTime(a.year, a.month, a.day);
      final dateB = DateTime(b.year, b.month, b.day);
      return _sortAscending ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
    });

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final records = _filteredRecords;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: const InputDecoration(
                  hintText: 'Search by No. or Approver…',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: AppColors.inkFaint, fontSize: 15),
                ),
              )
            : Text(widget.title),
        actions: [
          IconButton(
            tooltip: _isSearching ? 'Close Search' : 'Search',
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
            icon: Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded),
          ),
          IconButton(
            tooltip: 'Sort order',
            onPressed: () {
              setState(() => _sortAscending = !_sortAscending);
              showToast(
                context,
                _sortAscending ? 'Sorted: Oldest first' : 'Sorted: Newest first',
              );
            },
            icon: Icon(
              _sortAscending
                  ? Icons.arrow_upward_rounded
                  : Icons.swap_vert_rounded,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showToast(context, 'Create ${widget.title}'),
        backgroundColor: AppColors.success,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Create',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Text(
                widget.subtitle,
                style: const TextStyle(color: AppColors.inkSoft, fontSize: 13.5),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _showDateFilterSheet,
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
                            const Icon(Icons.calendar_today_rounded,
                                size: 17, color: AppColors.inkSoft),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _dateLabel,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down_rounded,
                                size: 20, color: AppColors.inkSoft),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _showFilterSheet,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: _selectedStatus != 'All'
                            ? AppColors.dangerSoft
                            : AppColors.fieldFill,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _selectedStatus != 'All'
                              ? AppColors.brandRed
                              : AppColors.line,
                        ),
                      ),
                      child: Icon(
                        Icons.filter_list_rounded,
                        size: 20,
                        color: _selectedStatus != 'All'
                            ? AppColors.brandRed
                            : AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: records.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: const BoxDecoration(
                              color: AppColors.fieldFill,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(widget.icon,
                                size: 30, color: AppColors.inkFaint),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'No records found',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Try adjusting your date range or filters.',
                            style: TextStyle(fontSize: 13, color: AppColors.inkSoft),
                          ),
                          const SizedBox(height: 14),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _dateRange = DateTimeRange(
                                  start: DateTime(2026, 1, 1),
                                  end: DateTime(2026, 12, 31),
                                );
                                _dateLabel = 'All 2026';
                                _selectedStatus = 'All';
                                _searchQuery = '';
                              });
                            },
                            child: const Text('Reset Date Range & Filters'),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                      itemCount: records.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, i) => _ApprovalCard(
                        record: records[i],
                        icon: widget.icon,
                        txnDateLabel: widget.txnDateLabel,
                        showWitnessedBy: widget.showWitnessedBy,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// DATE RANGE PRESETS SHEET
// -----------------------------------------------------------------------------
class _DateRangeSelectionSheet extends StatelessWidget {
  const _DateRangeSelectionSheet({
    required this.currentLabel,
    required this.onSelectPreset,
    required this.onCustomRange,
  });

  final String currentLabel;
  final void Function(String label, DateTime start, DateTime end) onSelectPreset;
  final VoidCallback onCustomRange;

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
          const Text(
            'Select Date Filter',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          _presetTile(
            'This Month (Aug 2026)',
            DateTime(2026, 8, 1),
            DateTime(2026, 8, 31),
          ),
          _presetTile(
            'Aug 2026 – Oct 2026',
            DateTime(2026, 8, 1),
            DateTime(2026, 10, 31),
          ),
          _presetTile(
            'Last 6 Months (May – Oct 2026)',
            DateTime(2026, 5, 1),
            DateTime(2026, 10, 31),
          ),
          _presetTile(
            'Year to Date 2026',
            DateTime(2026, 1, 1),
            DateTime(2026, 12, 31),
          ),
          const Divider(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.dangerSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.date_range_rounded,
                  color: AppColors.brandRed, size: 20),
            ),
            title: const Text(
              'Custom Date Range…',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
            ),
            trailing: const Icon(Icons.chevron_right_rounded,
                color: AppColors.inkFaint),
            onTap: onCustomRange,
          ),
        ],
      ),
    );
  }

  Widget _presetTile(String label, DateTime start, DateTime end) {
    final isSelected = currentLabel == label;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        isSelected
            ? Icons.radio_button_checked_rounded
            : Icons.radio_button_off_rounded,
        color: isSelected ? AppColors.brandRed : AppColors.inkFaint,
        size: 20,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          color: isSelected ? AppColors.brandRed : AppColors.ink,
          fontSize: 14,
        ),
      ),
      onTap: () => onSelectPreset(label, start, end),
    );
  }
}

// -----------------------------------------------------------------------------
// FILTER OPTIONS SHEET (STATUS)
// -----------------------------------------------------------------------------
class _FilterOptionsSheet extends StatefulWidget {
  const _FilterOptionsSheet({
    required this.currentStatus,
    required this.onApply,
  });

  final String currentStatus;
  final void Function(String status) onApply;

  @override
  State<_FilterOptionsSheet> createState() => _FilterOptionsSheetState();
}

class _FilterOptionsSheetState extends State<_FilterOptionsSheet> {
  late String _status = widget.currentStatus;

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
              const Text(
                'Filter Records',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() => _status = 'All'),
                child: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Status',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['All', 'Posted', 'Approved', 'Pending', 'Rejected']
                .map((s) {
              final sel = _status == s;
              return ChoiceChip(
                label: Text(s),
                selected: sel,
                selectedColor: AppColors.dangerSoft,
                labelStyle: TextStyle(
                  color: sel ? AppColors.brandRed : AppColors.inkSoft,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
                onSelected: (_) => setState(() => _status = s),
              );
            }).toList(),
          ),
          const SizedBox(height: 22),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onApply(_status);
            },
            child: const Text('Apply Filters'),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// APPROVAL RECORD CARD
// -----------------------------------------------------------------------------
class _ApprovalCard extends StatelessWidget {
  const _ApprovalCard({
    required this.record,
    required this.icon,
    required this.txnDateLabel,
    required this.showWitnessedBy,
  });

  final ApprovalRecord record;
  final IconData icon;
  final String txnDateLabel;
  final bool showWitnessedBy;

  Color _statusColor(String status) {
    switch (status) {
      case 'Approved':
        return AppColors.success;
      case 'Pending':
        return AppColors.warning;
      case 'Rejected':
        return AppColors.brandRed;
      case 'Posted':
      default:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: () => showToast(context, 'Open ${record.no}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(
                icon: icon,
                color: AppColors.brandRed,
                size: 40,
                iconSize: 21,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  record.no,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
              StatusPill(
                label: record.status,
                color: _statusColor(record.status),
                icon: Icons.check_circle_rounded,
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1),
          ),
          Row(
            children: [
              Expanded(child: _kv('Date applied', record.dateApplied)),
              Expanded(child: _kv(txnDateLabel, record.txnDate)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (showWitnessedBy) ...[
                Expanded(child: _kv('Witnessed by', record.witnessedBy)),
                Expanded(child: _kv('Approved by', record.approvedBy)),
              ] else ...[
                Expanded(child: _kv('Approved by', record.approvedBy)),
                Expanded(child: _kv('Approved date', record.approvedDate)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _kv(String label, String value) {
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
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}
