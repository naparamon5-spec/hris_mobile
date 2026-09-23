import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/hris_api.dart';
import '../theme/app_colors.dart';
import '../widgets/ui.dart';
import 'create_leave_of_absence_screen.dart';

class LeaveOfAbsenceScreen extends StatefulWidget {
  const LeaveOfAbsenceScreen({
    super.key,
    this.initialRecordId,
    this.initialRecordNo,
  });

  final String? initialRecordId;
  final String? initialRecordNo;

  @override
  State<LeaveOfAbsenceScreen> createState() => _LeaveOfAbsenceScreenState();
}

class _LeaveOfAbsenceScreenState extends State<LeaveOfAbsenceScreen> {
  List<_Loa> _allRecords = [];
  bool _loading = true;
  String? _error;
  bool _hasHandledInitial = false;

  late DateTimeRange _dateRange;
  late String _dateLabel;
  String _selectedStatus = 'All';
  String _selectedType = 'All';
  String _searchQuery = '';
  bool _isSearching = false;
  bool _sortAscending = false;

  final _searchController = TextEditingController();

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
    try {
      final rows = await HrisApi.instance.requestRecords('loa');
      if (!mounted) return;
      setState(() {
        _allRecords = rows.map(_Loa.fromRequest).toList();
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
    }
  }

  Future<void> _checkInitialRecord() async {
    final targetId = widget.initialRecordId?.trim();
    final targetNo = widget.initialRecordNo?.trim();
    if ((targetId == null || targetId.isEmpty) &&
        (targetNo == null || targetNo.isEmpty)) {
      return;
    }

    _Loa? match;
    for (final r in _allRecords) {
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
            _selectedType = 'All';
          });
        }
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showPremiumBottomSheet(
            context,
            isScrollControlled: true,
            builder: (ctx) => _LoaActionSheet(record: match!, onRefresh: _load),
          );
        }
      });
      return;
    }

    final numericId = int.tryParse(targetId ?? '');
    if (numericId != null && numericId > 0) {
      try {
        final single = await HrisApi.instance.getRequest('loa', numericId);
        final loaRecord = _Loa.fromRequest(single);
        if (mounted) {
          showPremiumBottomSheet(
            context,
            isScrollControlled: true,
            builder: (ctx) =>
                _LoaActionSheet(record: loaRecord, onRefresh: _load),
          );
        }
      } catch (_) {}
    }
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
        currentType: _selectedType,
        onApply: (status, type) {
          setState(() {
            _selectedStatus = status;
            _selectedType = type;
          });
        },
      ),
    );
  }

  List<_Loa> get _filteredRecords {
    var list = _allRecords.where((r) {
      // Date filter — records with no parseable date always pass.
      if (r.hasDate) {
        final rDate = r.sortDate;
        final inRange = !rDate.isBefore(_dateRange.start) &&
            !rDate.isAfter(_dateRange.end.add(const Duration(days: 1)));
        if (!inRange) return false;
      }

      // Status filter
      if (_selectedStatus != 'All' && r.status != _selectedStatus) return false;

      // Type filter
      if (_selectedType != 'All' && !r.type.contains(_selectedType)) {
        return false;
      }

      // Search query
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchNo = r.no.toLowerCase().contains(q);
        final matchType = r.type.toLowerCase().contains(q);
        final matchApprover = r.approvedBy.toLowerCase().contains(q);
        if (!matchNo && !matchType && !matchApprover) return false;
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
                  hintText: 'Search by No., Type, Approver…',
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
            : const Text('Leave of Absence'),
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
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => const CreateLeaveOfAbsenceScreen(),
            ),
          );
          if (created == true) _load();
        },
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
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Row(
                children: [
                  // Tappable Date Filter Pill
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
                  // Filter icon button
                  GestureDetector(
                    onTap: _showFilterSheet,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: (_selectedStatus != 'All' || _selectedType != 'All')
                            ? AppColors.dangerSoft
                            : AppColors.fieldFill,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: (_selectedStatus != 'All' || _selectedType != 'All')
                              ? AppColors.brandRed
                              : AppColors.line,
                        ),
                      ),
                      child: Icon(
                        Icons.filter_list_rounded,
                        size: 20,
                        color: (_selectedStatus != 'All' || _selectedType != 'All')
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
                  ? Center(
                      child: CircularProgressIndicator(
                          color: AppColors.brandRed))
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
                                    onPressed: _load, child: const Text('Retry')),
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
                                        child: const Icon(Icons.event_busy_rounded,
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
                                        style: TextStyle(
                                            fontSize: 13, color: AppColors.inkSoft),
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
                                            _selectedType = 'All';
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
                              itemBuilder: (context, i) =>
                                  _LoaCard(record: records[i], onRefresh: _load),
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
        isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
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
// FILTER OPTIONS SHEET (STATUS & LEAVE TYPE)
// -----------------------------------------------------------------------------
class _FilterOptionsSheet extends StatefulWidget {
  const _FilterOptionsSheet({
    required this.currentStatus,
    required this.currentType,
    required this.onApply,
  });

  final String currentStatus;
  final String currentType;
  final void Function(String status, String type) onApply;

  @override
  State<_FilterOptionsSheet> createState() => _FilterOptionsSheetState();
}

class _FilterOptionsSheetState extends State<_FilterOptionsSheet> {
  late String _status = widget.currentStatus;
  late String _type = widget.currentType;

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
                onPressed: () {
                  setState(() {
                    _status = 'All';
                    _type = 'All';
                  });
                },
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
          const SizedBox(height: 16),
          const Text(
            'Leave Type',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['All', 'Approved Leave', 'Approved UT'].map((t) {
              final sel = _type == t;
              return ChoiceChip(
                label: Text(t),
                selected: sel,
                selectedColor: AppColors.dangerSoft,
                labelStyle: TextStyle(
                  color: sel ? AppColors.brandRed : AppColors.inkSoft,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
                onSelected: (_) => setState(() => _type = t),
              );
            }).toList(),
          ),
          const SizedBox(height: 22),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onApply(_status, _type);
            },
            child: const Text('Apply Filters'),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// LOA RECORD CARD
// -----------------------------------------------------------------------------
class _LoaCard extends StatelessWidget {
  const _LoaCard({required this.record, required this.onRefresh});

  final _Loa record;
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
        return AppColors.brandRed; // Red — cancelled/voided
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
      builder: (ctx) => _LoaActionSheet(record: record, onRefresh: onRefresh),
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
              Text(
                record.no,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const Spacer(),
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
              Expanded(child: _kv('LOA date', record.loaDate)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _kv('Approved by', record.approvedBy)),
              Expanded(child: _kv('Approved date', record.approvedDate)),
            ],
          ),
          // Reason on the LOA card (single-day records carry it; multi-day
          // posted rows don't and stay hidden).
          if ((record.reason ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            _kv('Reason', (record.reason ?? '').trim()),
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
          style: TextStyle(
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
// RECORD ACTIONS SHEET (Send for Approval / Edit / Cancel / Reverse / Resend)
// -----------------------------------------------------------------------------
class _LoaActionSheet extends StatelessWidget {
  _LoaActionSheet({required this.record, required this.onRefresh});

  final _Loa record;
  final VoidCallback onRefresh;

  Color get _statusColor => _LoaCard.statusColor(record.status);

  /// Actions available for the record's current status.
  List<_LoaAction> _actionsFor(String status) {
    switch (status) {
      case 'Posted':
        // Final state — no actions at all.
        return [];
      case 'Approved':
      case 'Cancelled':
        // Only reversible states. Reversing sends the record back to Active.
        return [
          _LoaAction('Reverse Record', Icons.undo_rounded,
              color: Color(0xFF6B7280), destructive: true),
        ];
      case 'Rejected':
      case 'Disapproved':
        return [
          _LoaAction('Edit Record', Icons.edit_outlined, color: AppColors.info),
          _LoaAction('Send for Approval', Icons.verified_outlined,
              color: AppColors.warning),
          _LoaAction('Cancel Record', Icons.cancel_outlined,
              color: AppColors.brandRed, destructive: true),
        ];
      case 'For Approval':
      case 'Pending':
        // Already submitted — can't edit/cancel/re-submit; only re-notify.
        return [
          _LoaAction('Resend', Icons.send_rounded, color: AppColors.warning),
        ];
      default: // Active / draft — created but not yet sent for approval
        return [
          _LoaAction('Send for Approval', Icons.verified_outlined,
              color: AppColors.warning),
          _LoaAction('Edit Record', Icons.edit_outlined, color: AppColors.info),
          _LoaAction('Cancel Record', Icons.cancel_outlined,
              color: AppColors.brandRed, destructive: true),
        ];
    }
  }

  Future<void> _run(BuildContext sheetContext, _LoaAction a) async {
    // Use the root navigator's context so the loading overlay and onRefresh()
    // still run after the sheet is popped (the sheet's own context unmounts).
    final context = Navigator.of(sheetContext, rootNavigator: true).context;
    Navigator.pop(sheetContext); // close the sheet

    if (a.label == 'Edit Record') {
      final fromDt = parseAppDateTime(record.dateFrom, isFrom: true);
      final toDt = parseAppDateTime(record.dateTo, isFrom: false);

      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => CreateLeaveOfAbsenceScreen(
            initialId: record.id > 0 ? record.id : null,
            initialNo: record.no,
            initialLeaveType: record.type,
            initialDateFrom: fromDt,
            initialDateTo: toDt,
            initialReason: record.reason,
            initialTxnDate: record.loaDate,
          ),
        ),
      );
      if (saved == true) onRefresh();
      return;
    }

    if (a.label == 'Send for Approval') {
      showLoadingOverlay(context);
      try {
        await HrisApi.instance.sendForApproval('loa', record.id);
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
        await HrisApi.instance.reverseRecord('loa', record.id);
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
        await HrisApi.instance.resendRecord('loa', record.id);
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
        await HrisApi.instance.cancelRecord('loa', record.id);
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
          await HrisApi.instance.approveRecord('loa', record.id);
        } else {
          await HrisApi.instance.disapproveRecord('loa', record.id);
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
          Text(record.loaDate,
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

  Widget _tile(BuildContext context, _LoaAction a) {
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
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
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

class _LoaAction {
  const _LoaAction(this.label, this.icon,
      {this.color, this.destructive = false});
  final String label;
  final IconData icon;
  final Color? color;
  final bool destructive;
}

class _Loa {
  const _Loa({
    required this.id,
    required this.no,
    required this.dateApplied,
    required this.loaDate,
    required this.type,
    required this.approvedBy,
    required this.approvedDate,
    required this.year,
    required this.month,
    required this.day,
    this.hasDate = true,
    this.status = 'Posted',
    this.reason,
    this.dateFrom,
    this.dateTo,
    this.appliedHours,
    this.requestRecord,
  });

  final int id;
  final String no;
  final String dateApplied;
  final String loaDate;
  final String type;
  final String approvedBy;
  final String approvedDate;
  final int year;
  final int month;
  final int day;

  /// Whether [year]/[month]/[day] came from a real, parseable date.
  final bool hasDate;
  final String status;
  final String? reason;
  final String? dateFrom;
  final String? dateTo;
  final String? appliedHours;
  final RequestRecord? requestRecord;

  /// The record's filter/sort date — the leave (transaction) date shown on the
  /// card, falling back to the date it was applied.
  DateTime get sortDate => DateTime(year, month, day);

  factory _Loa.fromRequest(RequestRecord r) {
    final d = parseAppDateTime(r.txnDate) ??
        parseAppDateTime(r.dateFrom) ??
        r.appliedDate;
    final base = d ?? DateTime(2000);
    return _Loa(
      id: r.id,
      no: r.no,
      dateApplied: r.dateApplied,
      loaDate: r.txnDate,
      type: r.leaveType ?? 'Approved Leave',
      approvedBy: r.approvedBy ?? r.filedBy ?? '',
      approvedDate: r.approvedDate ?? '',
      year: base.year,
      month: base.month,
      day: base.day,
      hasDate: d != null,
      status: r.status,
      reason: r.reason,
      dateFrom: r.dateFrom,
      dateTo: r.dateTo,
      appliedHours: r.appliedHours,
      requestRecord: r,
    );
  }
}
