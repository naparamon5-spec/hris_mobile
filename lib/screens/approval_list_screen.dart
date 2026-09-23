import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/hris_api.dart';
import '../theme/app_colors.dart';
import '../widgets/ui.dart';
import 'create_call_approval_screen.dart';
import 'create_time_entry_screen.dart';

/// A single approval record shown in the [ApprovalListScreen] table/cards.
///
/// Shared by Call Approval, Manual Arrival/Departure and Overtime — they all
/// use the same columns: reference no., date applied, a transaction date,
/// approver and approved date plus a status.
class ApprovalRecord {
  const ApprovalRecord({
    required this.id,
    required this.no,
    required this.dateApplied,
    required this.txnDate,
    required this.approvedBy,
    required this.approvedDate,
    required this.year,
    required this.month,
    required this.day,
    this.hasDate = true,
    this.status = 'Posted',
    this.witnessedBy = '',
    this.appliedHours = '',
    this.approvedHours = '',
    this.reason,
    this.dateFrom,
    this.dateTo,
    this.requestRecord,
  });

  final int id;
  final String no;
  final String dateApplied;

  /// The transaction date (CA date, arrival/departure date, overtime date).
  final String txnDate;
  final String approvedBy;
  final String approvedDate;

  /// Only used by Manual Arrival/Departure, which shows a witness instead of
  /// an approved date.
  final String witnessedBy;

  /// Only used by Overtime, which shows applied/approved hours.
  final String appliedHours;
  final String approvedHours;
  final int year;
  final int month;
  final int day;

  /// Whether [year]/[month]/[day] came from a real, parseable date.
  final bool hasDate;
  final String status;
  final String? reason;
  final String? dateFrom;
  final String? dateTo;
  final RequestRecord? requestRecord;

  /// The record's filter/sort date — the transaction date shown on the card,
  /// falling back to the date it was applied.
  DateTime get sortDate => DateTime(year, month, day);

  /// Builds a card record from a backend [RequestRecord].
  factory ApprovalRecord.fromRequest(RequestRecord r) {
    // Filter/sort by the transaction date (what the card shows), then the
    // filing date; keep records visible even when neither parses.
    final d = parseAppDateTime(r.txnDate) ??
        r.appliedDate ??
        parseAppDateTime(r.dateFrom);
    return ApprovalRecord(
      id: r.id,
      no: r.no,
      dateApplied: r.dateApplied,
      txnDate: r.txnDate,
      approvedBy: r.approvedBy ?? r.filedBy ?? '',
      approvedDate: r.approvedDate ?? '',
      year: (d ?? DateTime(2000)).year,
      month: (d ?? DateTime(2000)).month,
      day: (d ?? DateTime(2000)).day,
      hasDate: d != null,
      status: r.status,
      witnessedBy: r.witnessedBy ?? '',
      appliedHours: r.appliedHours ?? '',
      approvedHours: r.approvedHours ?? '',
      reason: r.reason,
      dateFrom: r.dateFrom,
      dateTo: r.dateTo,
      requestRecord: r,
    );
  }
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
    required this.type,
    this.showWitnessedBy = false,
    this.showHours = false,
    this.initialRecordId,
    this.initialRecordNo,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  /// Label for the transaction date column (e.g. 'CA date').
  final String txnDateLabel;

  /// Backend request type: 'call-approval' | 'manual-ad' | 'overtime'.
  final String type;

  /// When true the second detail row shows "Witnessed by / Approved by"
  /// (Manual Arrival/Departure); otherwise "Approved by / Approved date".
  final bool showWitnessedBy;

  /// When true an extra "Applied hours / Approved hours" row is shown
  /// (Overtime).
  final bool showHours;

  final String? initialRecordId;
  final String? initialRecordNo;

  @override
  State<ApprovalListScreen> createState() => _ApprovalListScreenState();
}

class _ApprovalListScreenState extends State<ApprovalListScreen> {
  late DateTimeRange _dateRange;
  late String _dateLabel;
  String _selectedStatus = 'All';
  String _searchQuery = '';
  bool _isSearching = false;
  bool _sortAscending = false;
  bool _hasHandledInitial = false;

  final _searchController = TextEditingController();

  List<ApprovalRecord> _all = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Default to the whole current year so records are visible by default.
    final now = DateTime.now();
    _dateRange = DateTimeRange(
      start: DateTime(now.year, 1, 1),
      end: DateTime(now.year, 12, 31),
    );
    _dateLabel = 'Year ${now.year}';
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    // Cover the whole screen with the blur loader while records load.
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => showLoadingOverlay(context, immediate: true));
    try {
      final rows = await HrisApi.instance.requestRecords(widget.type);
      if (!mounted) return;
      setState(() {
        _all = rows.map(ApprovalRecord.fromRequest).toList();
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

  void _openRecordActions(ApprovalRecord rec) {
    showPremiumBottomSheet(
      context,
      isScrollControlled: true,
      builder: (ctx) => _ApprovalActionSheet(
        record: rec,
        type: widget.type,
        title: widget.title,
        txnDateLabel: widget.txnDateLabel,
        onRefresh: _load,
      ),
    );
  }

  Future<void> _checkInitialRecord() async {
    final targetId = widget.initialRecordId?.trim();
    final targetNo = widget.initialRecordNo?.trim();
    if ((targetId == null || targetId.isEmpty) &&
        (targetNo == null || targetNo.isEmpty)) {
      return;
    }

    ApprovalRecord? match;
    for (final r in _all) {
      if ((targetId != null && targetId.isNotEmpty && r.id.toString() == targetId) ||
          (targetNo != null &&
              targetNo.isNotEmpty &&
              (r.no.toLowerCase() == targetNo.toLowerCase() ||
                  targetNo.contains(r.no)))) {
        match = r;
        break;
      }
    }

    if (match != null) {
      if (match.hasDate) {
        final rDate = match.sortDate;
        if (rDate.isBefore(_dateRange.start) ||
            rDate.isAfter(_dateRange.end.add(const Duration(days: 1)))) {
          setState(() {
            _dateRange = DateTimeRange(
              start: DateTime(rDate.year, 1, 1),
              end: DateTime(rDate.year, 12, 31),
            );
            _dateLabel = 'Year ${rDate.year}';
            _selectedStatus = 'All';
          });
        }
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _openRecordActions(match!);
        }
      });
      return;
    }

    final numericId = int.tryParse(targetId ?? '');
    if (numericId != null && numericId > 0) {
      try {
        final single =
            await HrisApi.instance.getRequest(widget.type, numericId);
        final record = ApprovalRecord.fromRequest(single);
        if (mounted) {
          _openRecordActions(record);
        }
      } catch (_) {}
    }
  }

  Future<void> _openCreate() async {
    // Call Approval has a dedicated multi-row form; Manual A/D and Overtime
    // share a single-entry (date + time span + reason) form.
    final isOvertime = widget.type == 'overtime';
    final Widget dest = widget.type == 'call-approval'
        ? CreateCallApprovalScreen(type: widget.type, title: widget.title)
        : CreateTimeEntryScreen(
            type: widget.type,
            title: widget.title,
            // 'MAD date' -> 'MAD Date', 'Overtime date' -> 'Overtime Date'
            dateLabel: widget.txnDateLabel.replaceAll('date', 'Date'),
            // Overtime counts every hour; Manual A/D deducts a 1h break.
            deductBreak: !isOvertime,
            defaultFrom: isOvertime
                ? const TimeOfDay(hour: 19, minute: 0)
                : const TimeOfDay(hour: 8, minute: 0),
            defaultTo: isOvertime
                ? const TimeOfDay(hour: 0, minute: 0)
                : const TimeOfDay(hour: 18, minute: 0),
          );
    final created =
        await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => dest));
    if (created == true) _load();
  }

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
            colorScheme: ColorScheme.light(
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
    showPremiumBottomSheet(
      context,
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
    showPremiumBottomSheet(
      context,
      builder: (ctx) => _FilterOptionsSheet(
        currentStatus: _selectedStatus,
        onApply: (status) {
          setState(() => _selectedStatus = status);
        },
      ),
    );
  }

  List<ApprovalRecord> get _filteredRecords {
    var list = _all.where((r) {
      // Date filter — only applied to records with a real date; records whose
      // date couldn't be parsed always pass so they're never hidden.
      if (r.hasDate) {
        final rDate = r.sortDate;
        final inRange = !rDate.isBefore(_dateRange.start) &&
            !rDate.isAfter(_dateRange.end.add(const Duration(days: 1)));
        if (!inRange) return false;
      }

      if (_selectedStatus != 'All' && r.status != _selectedStatus) return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matches = r.no.toLowerCase().contains(q) ||
            r.approvedBy.toLowerCase().contains(q) ||
            r.status.toLowerCase().contains(q) ||
            r.txnDate.toLowerCase().contains(q) ||
            (r.reason?.toLowerCase().contains(q) ?? false);
        if (!matches) return false;
      }

      return true;
    }).toList();

    list.sort((a, b) => _sortAscending
        ? a.sortDate.compareTo(b.sortDate)
        : b.sortDate.compareTo(a.sortDate));

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
                style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w600),
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: const InputDecoration(
                  hintText: 'Search by No., Status, Approver…',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  filled: false,
                  isCollapsed: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
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
            tooltip: 'Refresh',
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
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
        onPressed: _openCreate,
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
              child: _loading
                  ? const SizedBox.shrink()
                  : _error != null
                  ? RefreshIndicator(
                      color: AppColors.brandRed,
                      onRefresh: _load,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: 400,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.cloud_off_rounded,
                                    size: 48, color: AppColors.inkFaint),
                                const SizedBox(height: 12),
                                Text(_error!,
                                    style: const TextStyle(color: AppColors.inkSoft)),
                                const SizedBox(height: 12),
                                OutlinedButton(
                                    onPressed: _load,
                                    child: const Text('Retry')),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.brandRed,
                      onRefresh: _load,
                      child: records.isEmpty
                          ? SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: SizedBox(
                                height: 400,
                                child: Center(
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
                                            final now = DateTime.now();
                                            _dateRange = DateTimeRange(
                                              start: DateTime(now.year, 1, 1),
                                              end: DateTime(now.year, 12, 31),
                                            );
                                            _dateLabel = 'All ${now.year}';
                                            _selectedStatus = 'All';
                                            _searchQuery = '';
                                          });
                                        },
                                        child: const Text('Reset Date Range & Filters'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                              itemCount: records.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 12),
                              itemBuilder: (context, i) => _ApprovalCard(
                                record: records[i],
                                icon: widget.icon,
                                txnDateLabel: widget.txnDateLabel,
                                showWitnessedBy: widget.showWitnessedBy,
                                showHours: widget.showHours,
                                type: widget.type,
                                title: widget.title,
                                onRefresh: _load,
                              ),
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
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);
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
          _presetTile('This Month', monthStart, monthEnd),
          _presetTile(
              'Last 3 Months', DateTime(now.year, now.month - 2, 1), monthEnd),
          _presetTile(
              'Last 6 Months', DateTime(now.year, now.month - 5, 1), monthEnd),
          _presetTile('Year to Date ${now.year}', DateTime(now.year, 1, 1),
              monthEnd),
          _presetTile('This Year ${now.year}', DateTime(now.year, 1, 1),
              DateTime(now.year, 12, 31)),
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
              child: Icon(Icons.date_range_rounded,
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
            children: const [
              'All',
              'Active',
              'For Approval',
              'For Witness Approval',
              'Approved',
              'Posted',
              'Cancelled',
              'Disapproved'
            ].map((s) {
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
    required this.showHours,
    required this.type,
    required this.title,
    required this.onRefresh,
  });

  final ApprovalRecord record;
  final IconData icon;
  final String txnDateLabel;
  final bool showWitnessedBy;
  final bool showHours;
  final String type;
  final String title;
  final VoidCallback onRefresh;

  static Color statusColor(String status) {
    switch (status) {
      case 'For Approval':
      case 'For Witness Approval':
      case 'Pending':
        return AppColors.warning; // Yellow — awaiting a decision
      case 'Approved':
        return AppColors.success;
      case 'Posted':
        return AppColors.info;
      case 'Active':
      case 'Saved':
        return AppColors.inkSoft; // Neutral — draft, not yet submitted
      case 'Cancelled':
      case 'Void':
        return AppColors.inkFaint;
      case 'Rejected':
      case 'Disapproved':
      case 'Witness Disapproved':
      default:
        return AppColors.brandRed;
    }
  }

  void _openActions(BuildContext context) {
    showPremiumBottomSheet(
      context,
      isScrollControlled: true,
      builder: (ctx) => _ApprovalActionSheet(
        record: record,
        type: type,
        title: title,
        txnDateLabel: txnDateLabel,
        onRefresh: onRefresh,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: () => _openActions(context),
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
                color: statusColor(record.status),
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
          if (showHours) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _kv('Applied hours', record.appliedHours)),
                Expanded(child: _kv('Approved hours', record.approvedHours)),
              ],
            ),
          ],
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
          // Show reason for MAD/OT and purpose for CA — from the DB.
          if ((record.reason ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            _kv(type == 'call-approval' ? 'Purpose' : 'Reason',
                (record.reason ?? '').trim()),
          ],
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
        SizedBox(height: 3),
        Text(
          value.isEmpty ? '—' : value,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// APPROVAL RECORD ACTIONS SHEET
// -----------------------------------------------------------------------------
class _ApprovalActionSheet extends StatelessWidget {
  _ApprovalActionSheet({
    required this.record,
    required this.type,
    required this.title,
    required this.txnDateLabel,
    required this.onRefresh,
  });

  final ApprovalRecord record;
  final String type;
  final String title;
  final String txnDateLabel;
  final VoidCallback onRefresh;

  Color get _statusColor => _ApprovalCard.statusColor(record.status);

  List<_ApprovalActionItem> _actionsFor(String status) {
    switch (status) {
      case 'Posted':
        // Final state — no actions at all.
        return [];
      case 'Approved':
      case 'Cancelled':
        // Only reversible states. Reversing sends the record back to Active.
        return [
          _ApprovalActionItem('Reverse Record', Icons.undo_rounded,
              color: Color(0xFF6B7280), destructive: true),
        ];
      case 'For Approval':
      case 'For Witness Approval':
      case 'Pending':
        // Already submitted for approval — can't edit/cancel/re-submit; the
        // owner can only re-notify the approver.
        return [
          _ApprovalActionItem('Resend', Icons.send_rounded,
              color: AppColors.warning),
        ];
      case 'Rejected':
        // Rejected back to the owner — fix and re-file.
        return [
          _ApprovalActionItem('Edit Record', Icons.edit_outlined,
              color: AppColors.info),
          _ApprovalActionItem('Send for Approval', Icons.verified_outlined,
              color: AppColors.warning),
          _ApprovalActionItem('Cancel Record', Icons.cancel_outlined,
              color: AppColors.brandRed, destructive: true),
        ];
      default: // draft / Active — not yet sent for approval
        return [
          _ApprovalActionItem('Send for Approval', Icons.verified_outlined,
              color: AppColors.warning),
          _ApprovalActionItem('Edit Record', Icons.edit_outlined,
              color: AppColors.info),
          _ApprovalActionItem('Cancel Record', Icons.cancel_outlined,
              color: AppColors.brandRed, destructive: true),
        ];
    }
  }

  Future<void> _run(BuildContext sheetContext, _ApprovalActionItem a) async {
    // Use the ROOT navigator's context for everything after the sheet closes.
    // The sheet's own context becomes unmounted the moment we pop it, which
    // would make every `context.mounted` check false — skipping the loading
    // overlay dismissal (stuck spinner) and onRefresh() (stale status).
    final context = Navigator.of(sheetContext, rootNavigator: true).context;
    Navigator.pop(sheetContext);

    if (a.label == 'Edit Record') {
      final initialDate = parseAppDateTime(record.dateFrom) ??
          parseAppDateTime(record.txnDate);

      final isOvertime = type == 'overtime';
      final Widget dest = type == 'call-approval'
          ? CreateCallApprovalScreen(
              type: type,
              title: title,
              initialId: record.id > 0 ? record.id : null,
              initialNo: record.no,
              initialDate: initialDate,
              initialRows: _rowsFromRequest(record.requestRecord),
            )
          : CreateTimeEntryScreen(
              type: type,
              title: title,
              dateLabel: txnDateLabel.replaceAll('date', 'Date'),
              deductBreak: !isOvertime,
              initialId: record.id > 0 ? record.id : null,
              initialNo: record.no,
              initialDate: initialDate,
              initialFrom: _timeFrom(record.requestRecord?.timeFrom) ??
                  _timeFrom(record.requestRecord?.dateFrom),
              initialTo: _timeFrom(record.requestRecord?.timeTo) ??
                  _timeFrom(record.requestRecord?.dateTo),
              initialReason: record.reason,
            );
      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => dest),
      );
      if (saved == true) onRefresh();
      return;
    }

    if (a.label == 'Send for Approval') {
      showLoadingOverlay(context);
      try {
        await HrisApi.instance.sendForApproval(type, record.id);
        if (context.mounted) {
          hideLoadingOverlay(context);
          showToast(context, '${record.no} submitted for approval.',
              isSuccess: true, title: 'Sent for Approval');
          onRefresh();
        }
      } on ApiException catch (e) {
        if (context.mounted) {
          hideLoadingOverlay(context);
          showToast(context, e.message, isSuccess: false, title: 'Error');
        }
      }
      return;
    }

    if (a.label == 'Reverse Record') {
      final ok = await showConfirmDialog(
        context,
        title: 'Reverse Record',
        message: 'Are you sure you want to reverse record ${record.no}?',
        confirmLabel: 'Yes, Reverse',
      );
      if (!ok) return;

      if (context.mounted) showLoadingOverlay(context);
      try {
        await HrisApi.instance.reverseRecord(type, record.id);
        if (context.mounted) {
          hideLoadingOverlay(context);
          showToast(context, '${record.no} has been reversed.',
              isSuccess: true, title: 'Record Reversed');
          onRefresh();
        }
      } on ApiException catch (e) {
        if (context.mounted) {
          hideLoadingOverlay(context);
          showToast(context, e.message, isSuccess: false, title: 'Error');
        }
      }
      return;
    }

    if (a.label == 'Resend') {
      showLoadingOverlay(context);
      try {
        await HrisApi.instance.resendRecord(type, record.id);
        if (context.mounted) {
          hideLoadingOverlay(context);
          showToast(context, '${record.no} resent successfully.',
              isSuccess: true, title: 'Resent');
          onRefresh();
        }
      } on ApiException catch (e) {
        if (context.mounted) {
          hideLoadingOverlay(context);
          showToast(context, e.message, isSuccess: false, title: 'Error');
        }
      }
      return;
    }

    if (a.label == 'Cancel Record') {
      final ok = await showConfirmDialog(
        context,
        title: 'Cancel Record',
        message: 'Are you sure you want to cancel record ${record.no}?',
        confirmLabel: 'Yes, Cancel',
      );
      if (!ok) return;

      if (context.mounted) showLoadingOverlay(context);
      try {
        await HrisApi.instance.cancelRecord(type, record.id);
        if (context.mounted) {
          hideLoadingOverlay(context);
          showToast(context, '${record.no} cancelled.',
              isSuccess: true, title: 'Record Cancelled');
          onRefresh();
        }
      } on ApiException catch (e) {
        if (context.mounted) {
          hideLoadingOverlay(context);
          showToast(context, e.message, isSuccess: false, title: 'Error');
        }
      }
      return;
    }

    if (a.label == 'Approve' || a.label == 'Disapprove') {
      final approve = a.label == 'Approve';
      final ok = await showConfirmDialog(
        context,
        title: '${a.label} Record',
        message:
            'Are you sure you want to ${a.label.toLowerCase()} record ${record.no}?',
        confirmLabel: 'Yes, ${a.label}',
      );
      if (!ok) return;

      if (context.mounted) showLoadingOverlay(context);
      try {
        if (approve) {
          await HrisApi.instance.approveRecord(type, record.id);
        } else {
          await HrisApi.instance.disapproveRecord(type, record.id);
        }
        if (context.mounted) {
          hideLoadingOverlay(context);
          showToast(context,
              '${record.no} ${approve ? 'approved' : 'disapproved'}.',
              isSuccess: true,
              title: approve ? 'Record Approved' : 'Record Disapproved');
          onRefresh();
        }
      } on ApiException catch (e) {
        if (context.mounted) {
          hideLoadingOverlay(context);
          showToast(context, e.message, isSuccess: false, title: 'Error');
        }
      }
      return;
    }

    showToast(context, '${a.label} — ${record.no} done.',
        isSuccess: true, title: a.label);
    onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    final actions = _actionsFor(record.status);
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
              Text(record.no,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w900)),
              const Spacer(),
              StatusPill(
                label: record.status,
                color: _statusColor,
                icon: Icons.check_circle_rounded,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('$title • ${record.txnDate}',
              style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
          const SizedBox(height: 16),
          if (actions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No actions available for a posted record.',
                style: TextStyle(fontSize: 13.5, color: AppColors.inkSoft),
              ),
            ),
          for (final a in actions) ...[
            _tile(context, a),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, _ApprovalActionItem a) {
    final color = a.color ??
        (a.destructive
            ? AppColors.brandRed
            : AppColors.ink);
    return Material(
      color: AppColors.fieldFill,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _run(context, a),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(a.icon, size: 20, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  a.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.inkFaint),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApprovalActionItem {
  const _ApprovalActionItem(this.label, this.icon,
      {this.color, this.destructive = false});
  final String label;
  final IconData icon;
  final Color? color;
  final bool destructive;
}

// -----------------------------------------------------------------------------
// EDIT PREFILL HELPERS
// -----------------------------------------------------------------------------

/// Pull the Call Approval rows (Time From / Time To / Customer / Purpose) out
/// of the raw record JSON so the Edit screen can show them immediately, before
/// the server round-trip finishes.
List<Map<String, dynamic>>? _rowsFromRequest(RequestRecord? r) {
  if (r == null) return null;
  final raw = r.rawJson;
  if (raw == null) return null;
  final sources = <Map>[raw, if (raw['data'] is Map) raw['data'] as Map];
  for (final s in sources) {
    for (final key in const [
      'rows',
      'lines',
      'details',
      'items',
      'entries',
      'call_rows',
      'ca_rows',
    ]) {
      final v = s[key];
      if (v is List && v.isNotEmpty) {
        return v.whereType<Map>().map((m) => m.cast<String, dynamic>()).toList();
      }
    }
  }
  return null;
}

/// Parse a clock string ("14:30", "02:30 PM") or an ISO datetime into a
/// TimeOfDay for prefilling the Edit form. Returns null when unparseable.
TimeOfDay? _timeFrom(String? s) {
  if (s == null) return null;
  final str = s.trim();
  if (str.isEmpty) return null;
  final iso = DateTime.tryParse(str);
  if (iso != null) return TimeOfDay(hour: iso.hour, minute: iso.minute);
  final m = RegExp(r'(\d{1,2}):(\d{2})\s*([AaPp][Mm])?').firstMatch(str);
  if (m == null) return null;
  var h = int.parse(m.group(1)!);
  final min = int.parse(m.group(2)!);
  final ampm = m.group(3)?.toLowerCase();
  if (ampm == 'pm' && h < 12) h += 12;
  if (ampm == 'am' && h == 12) h = 0;
  return TimeOfDay(hour: h % 24, minute: min);
}
