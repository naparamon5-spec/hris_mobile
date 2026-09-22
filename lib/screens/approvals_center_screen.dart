import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/hris_api.dart';
import '../theme/app_colors.dart';
import '../widgets/ui.dart';

/// Department approver's inbox for a single dedicated view:
/// - Records Approval (module: 'records', scope: 'pending')
/// - Approved Records (module: 'records', scope: 'history')
/// - Request Approval (module: 'requests', scope: 'pending')
/// - Approved Requests (module: 'requests', scope: 'history')
class ApprovalsCenterScreen extends StatefulWidget {
  const ApprovalsCenterScreen({
    super.key,
    this.module = 'records',
    this.scope = 'pending',
  });

  /// 'records' = Records Approval (LOA/CA/MAD/OT); 'requests' = Request Approval
  /// (Other Requests — COE/EPP/ITR/COL/BUP/ID from th_request_head).
  final String module;

  /// 'pending' = Filings awaiting a decision; 'history' = Decided filings.
  final String scope;

  @override
  State<ApprovalsCenterScreen> createState() => _ApprovalsCenterScreenState();
}

class _ApprovalsCenterScreenState extends State<ApprovalsCenterScreen> {
  List<ApprovalTask> _tasks = [];
  bool _loading = true;
  String? _error;

  bool _isSearching = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  // Shared filters.
  String _appFilter = 'All'; // 'All' | 'LOA' | 'CA' | 'MAD' | 'OT' (or COE, etc.)
  String _empFilter = 'All';
  String _historyStatus = 'All';

  late DateTimeRange _dateRange;
  late String _dateLabel;

  // Multi-select state for pending filings (keys = task.key).
  final Set<String> _selected = {};

  bool get _isRequests => widget.module == 'requests';
  bool get _isPending => widget.scope == 'pending';

  String get _screenTitle {
    if (_isRequests) {
      return _isPending ? 'Request Approval' : 'Approved Requests';
    } else {
      return _isPending ? 'Records Approval' : 'Approved Records';
    }
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateRange = DateTimeRange(
      start: DateTime(now.year, 1, 1),
      end: DateTime(now.year, 12, 31),
    );
    _dateLabel = 'Year ${now.year}';
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await HrisApi.instance.approvalTasks(
        widget.scope,
        module: widget.module,
      );
      if (!mounted) return;
      setState(() {
        _tasks = rows;
        _selected.removeWhere((k) => !rows.any((t) => t.key == k));
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  // ---- filtering ----
  DateTime? _taskDate(ApprovalTask t) {
    return parseAppDateTime(t.approvedDate) ??
        parseAppDateTime(t.txnDate) ??
        parseAppDateTime(t.dateApplied) ??
        parseAppDateTime(t.dateSent);
  }

  bool _matchesFilters(ApprovalTask t) {
    if (_appFilter != 'All' && t.app != _appFilter) return false;
    // For request approval pending, employee filter is not used.
    if (!_isRequests && _empFilter != 'All' && t.employee != _empFilter) return false;
    if (!_isPending && _historyStatus != 'All' && t.status != _historyStatus) {
      return false;
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      if (!(t.employee.toLowerCase().contains(q) ||
          t.no.toLowerCase().contains(q) ||
          t.app.toLowerCase().contains(q) ||
          t.status.toLowerCase().contains(q) ||
          t.txnDate.toLowerCase().contains(q) ||
          t.dateApplied.toLowerCase().contains(q) ||
          t.approvedDate.toLowerCase().contains(q))) {
        return false;
      }
    }
    // Date range filter
    final dt = _taskDate(t);
    if (dt != null) {
      final start = DateTime(_dateRange.start.year, _dateRange.start.month, _dateRange.start.day);
      final end = DateTime(_dateRange.end.year, _dateRange.end.month, _dateRange.end.day, 23, 59, 59);
      if (dt.isBefore(start) || dt.isAfter(end)) {
        return false;
      }
    }
    return true;
  }

  List<ApprovalTask> get _visibleTasks => _tasks.where(_matchesFilters).toList();

  /// Distinct employee names across the task feed (for the employee filter).
  List<String> get _employees {
    final set = <String>{};
    for (final t in _tasks) {
      if (t.employee.isNotEmpty) set.add(t.employee);
    }
    final list = set.toList()..sort();
    return ['All', ...list];
  }

  // ---- date range selection ----
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
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
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
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
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

  // ---- batch decisions ----
  Future<void> _batchDecide(bool approve) async {
    final tasks =
        _visibleTasks.where((t) => _selected.contains(t.key)).toList();
    if (tasks.isEmpty) return;

    final verb = approve ? 'Approve' : 'Disapprove';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        title: Text('$verb ${tasks.length} record${tasks.length == 1 ? '' : 's'}',
            style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Text(
            'Are you sure you want to ${verb.toLowerCase()} the ${tasks.length} selected filing${tasks.length == 1 ? '' : 's'}?'),
        // A single Row here — AlertDialog's default OverflowBar stacks
        // Expanded children vertically, which produced the ugly full-width
        // stacked buttons.
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    side: const BorderSide(color: AppColors.line),
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cancel',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        approve ? AppColors.success : AppColors.brandRed,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  // Single word so it never wraps inside the narrow Expanded.
                  child: Text(verb,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (ok != true) return;

    if (mounted) showLoadingOverlay(context);
    var done = 0;
    var failed = 0;
    for (final t in tasks) {
      try {
        if (approve) {
          await HrisApi.instance.approveRecord(t.type, t.id);
        } else {
          await HrisApi.instance.disapproveRecord(t.type, t.id);
        }
        done++;
      } catch (_) {
        failed++;
      }
    }
    if (!mounted) return;
    hideLoadingOverlay(context);
    setState(() => _selected.clear());
    showToast(
      context,
      failed == 0
          ? '$done record${done == 1 ? '' : 's'} ${approve ? 'approved' : 'disapproved'}.'
          : '$done ${approve ? 'approved' : 'disapproved'}, $failed failed.',
      isSuccess: failed == 0,
      title: approve ? 'Approved' : 'Disapproved',
    );
    await _load();
  }

  void _openDetail(ApprovalTask task) {
    showPremiumBottomSheet(
      context,
      isScrollControlled: true,
      builder: (ctx) => _ApprovalDetailSheet(
        task: task,
        isRequests: _isRequests,
        onDecided: _load,
      ),
    );
  }

  // ---- filter sheets ----
  void _showAppFilter() {
    _showChoiceSheet(
      title: _isRequests ? 'Request Type' : 'Application Type',
      current: _appFilter,
      options: _isRequests
          ? const ['All', 'COE', 'EPP', 'ITR', 'COL', 'BUP', 'ID']
          : const ['All', 'LOA', 'CA', 'MAD', 'OT'],
      onApply: (v) => setState(() => _appFilter = v),
    );
  }

  void _showEmpFilter() {
    _showChoiceSheet(
      title: 'Employee',
      current: _empFilter,
      options: _employees,
      onApply: (v) => setState(() => _empFilter = v),
    );
  }

  void _showHistoryStatusFilter() {
    _showChoiceSheet(
      title: 'Status',
      current: _historyStatus,
      options: const [
        'All',
        'Approved',
        'Posted',
        'Disapproved',
        'Witness Disapproved',
        'Cancelled',
      ],
      onApply: (v) => setState(() => _historyStatus = v),
    );
  }

  void _showChoiceSheet({
    required String title,
    required String current,
    required List<String> options,
    required void Function(String) onApply,
  }) {
    showPremiumBottomSheet(
      context,
      isScrollControlled: true,
      builder: (ctx) => _ChoiceSheet(
        title: title,
        current: current,
        options: options,
        onApply: onApply,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  hintText: 'Search by name, ID, type, date…',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  isCollapsed: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                  hintStyle: TextStyle(color: AppColors.inkFaint, fontSize: 15),
                ),
              )
            : Text(_screenTitle),
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
        ],
      ),
      body: SafeArea(
        child: _loading
            ? Center(
                child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary))
            : _error != null
                ? _errorState(_error!, _load)
                : _content(),
      ),
    );
  }

  Widget _content() {
    final rows = _visibleTasks;
    final allSelected =
        rows.isNotEmpty && rows.every((t) => _selected.contains(t.key));

    return Column(
      children: [
        _dateFilterBar(),
        _filterBar(),
        if (_isPending && rows.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
            child: Row(
              children: [
                InkWell(
                  onTap: () => setState(() {
                    if (allSelected) {
                      _selected.clear();
                    } else {
                      _selected.addAll(rows.map((t) => t.key));
                    }
                  }),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    child: Row(
                      children: [
                        Icon(
                          allSelected
                              ? Icons.check_box_rounded
                              : Icons.check_box_outline_blank_rounded,
                          size: 20,
                          color: allSelected
                              ? Theme.of(context).colorScheme.primary
                              : AppColors.inkSoft,
                        ),
                        const SizedBox(width: 6),
                        Text(allSelected ? 'Unselect all' : 'Select all',
                            style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.inkSoft)),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                if (_selected.isNotEmpty)
                  Text('${_selected.length} selected',
                      style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink)),
              ],
            ),
          ),
        Expanded(
          child: rows.isEmpty
              ? _emptyState(
                  icon: _isPending ? Icons.inbox_rounded : Icons.history_rounded,
                  title: _isPending ? 'All caught up' : 'Nothing here',
                  subtitle: _isPending
                      ? 'No filings are waiting for your approval.'
                      : 'Decided filings will appear here.',
                )
              : RefreshIndicator(
                  color: Theme.of(context).colorScheme.primary,
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                        16, 4, 16, _selected.isEmpty ? 24 : 96),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: rows.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final t = rows[i];
                      return _TaskCard(
                        task: t,
                        isRequests: _isRequests,
                        selectable: _isPending,
                        selected: _selected.contains(t.key),
                        onToggle: () => setState(() {
                          if (!_selected.add(t.key)) _selected.remove(t.key);
                        }),
                        onTap: () => _openDetail(t),
                      );
                    },
                  ),
                ),
        ),
        if (_isPending && _selected.isNotEmpty) _batchBar(),
      ],
    );
  }

  Widget _dateFilterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
      child: GestureDetector(
        onTap: _showDateFilterSheet,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.fieldFill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today_rounded,
                  size: 16, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Date: $_dateLabel',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const Spacer(),
              const Icon(Icons.keyboard_arrow_down_rounded,
                  size: 18, color: AppColors.inkSoft),
            ],
          ),
        ),
      ),
    );
  }

  // ---- shared filter bar ----
  Widget _filterBar() {
    final showEmp = !_isRequests;
    final showStatus = !_isPending;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Row(
        children: [
          Expanded(
            child: _filterChip(
              label: _appFilter == 'All'
                  ? 'All Applications'
                  : _appFilter,
              active: _appFilter != 'All',
              onTap: _showAppFilter,
            ),
          ),
          if (showEmp) ...[
            const SizedBox(width: 8),
            Expanded(
              child: _filterChip(
                label: _empFilter == 'All' ? 'All Employees' : _empFilter,
                active: _empFilter != 'All',
                onTap: _showEmpFilter,
              ),
            ),
          ],
          if (showStatus) ...[
            const SizedBox(width: 8),
            _iconFilter(
              active: _historyStatus != 'All',
              onTap: _showHistoryStatusFilter,
            ),
          ],
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: active ? primary.withValues(alpha: 0.12) : AppColors.fieldFill,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: active ? primary : AppColors.line),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: active ? primary : AppColors.ink,
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 18, color: active ? primary : AppColors.inkSoft),
          ],
        ),
      ),
    );
  }

  Widget _iconFilter({required bool active, required VoidCallback onTap}) {
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: active ? primary.withValues(alpha: 0.12) : AppColors.fieldFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? primary : AppColors.line),
        ),
        child: Icon(Icons.filter_list_rounded,
            size: 20, color: active ? primary : AppColors.ink),
      ),
    );
  }

  Widget _batchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.card,
        boxShadow: [
          BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _batchDecide(false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.brandRed,
                  side: BorderSide(color: AppColors.brandRed, width: 1.4),
                  backgroundColor: AppColors.dangerSoft,
                  minimumSize: const Size.fromHeight(50),
                ),
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text('Disapprove',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _batchDecide(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size.fromHeight(50),
                ),
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('Approve',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Center(
          child: Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
                color: AppColors.fieldFill, shape: BoxShape.circle),
            child: Icon(icon, size: 30, color: AppColors.inkFaint),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink)),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(subtitle,
              style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
        ),
      ],
    );
  }

  Widget _errorState(String msg, Future<void> Function() retry) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.inkFaint),
          const SizedBox(height: 12),
          Text(msg, style: const TextStyle(color: AppColors.inkSoft)),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: retry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// STATUS COLORS
// -----------------------------------------------------------------------------
Color approvalStatusColor(String status) {
  switch (status) {
    case 'For Approval':
    case 'For Witness Approval':
    case 'Pending':
      return AppColors.warning;
    case 'Approved':
      return AppColors.success;
    case 'Posted':
      return AppColors.info;
    case 'Active':
    case 'Saved':
      return AppColors.inkSoft;
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

// -----------------------------------------------------------------------------
// TASK CARD
// -----------------------------------------------------------------------------
class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.onTap,
    this.isRequests = false,
    this.selectable = false,
    this.selected = false,
    this.onToggle,
  });

  final ApprovalTask task;
  final bool isRequests;
  final VoidCallback onTap;
  final bool selectable;
  final bool selected;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      // Tap anywhere on the card opens the detail sheet — the checkbox has
      // its own tap target for multi-select so both actions coexist.
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (selectable) ...[
                InkWell(
                  onTap: onToggle,
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      selected
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded,
                      size: 22,
                      color: selected ? AppColors.brandRed : AppColors.inkFaint,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              _AppBadge(app: task.app),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.employee.isEmpty ? task.no : task.employee,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 14.5),
                    ),
                    const SizedBox(height: 2),
                    Text('${task.app} • ${task.no}',
                        style: const TextStyle(
                            color: AppColors.inkSoft, fontSize: 12)),
                  ],
                ),
              ),
              StatusPill(
                label: task.status,
                color: approvalStatusColor(task.status),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 11),
            child: Divider(height: 1),
          ),
          // All four screens (Records Approval, Approved Records, Request
          // Approval, Approved Requests) use the same compact card — only the
          // top-line dates. The full details live in the detail sheet, which
          // opens when the card is tapped.
          Row(
            children: [
              Expanded(
                child: _kv(
                  isRequests ? 'Request date' : 'Application date',
                  task.dateApplied,
                ),
              ),
              Expanded(child: _kv('Date sent', task.dateSent)),
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
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: AppColors.inkFaint,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value.isEmpty ? '—' : value,
          style: const TextStyle(
              fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.ink),
        ),
      ],
    );
  }
}

class _AppBadge extends StatelessWidget {
  const _AppBadge({required this.app});
  final String app;

  Color get _color {
    switch (app) {
      case 'LOA':
        return AppColors.info;
      case 'OT':
        return AppColors.warning;
      case 'CA':
        return AppColors.success;
      case 'MAD':
        return AppColors.brandRed;
      default:
        return AppColors.inkSoft;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        app,
        style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w900, color: _color),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// DETAIL / SINGLE DECISION SHEET
// -----------------------------------------------------------------------------
class _ApprovalDetailSheet extends StatefulWidget {
  const _ApprovalDetailSheet({
    required this.task,
    required this.onDecided,
    this.isRequests = false,
  });

  final ApprovalTask task;
  final bool isRequests;
  final VoidCallback onDecided;

  @override
  State<_ApprovalDetailSheet> createState() => _ApprovalDetailSheetState();
}

class _ApprovalDetailSheetState extends State<_ApprovalDetailSheet> {
  bool _busy = false;

  Future<void> _decide(bool approve) async {
    if (_busy) return;
    setState(() => _busy = true);
    final t = widget.task;
    try {
      if (approve) {
        await HrisApi.instance.approveRecord(t.type, t.id);
      } else {
        await HrisApi.instance.disapproveRecord(t.type, t.id);
      }
      if (!mounted) return;
      Navigator.pop(context);
      showToast(
        context,
        '${t.no} ${approve ? 'approved' : 'disapproved'}.',
        isSuccess: true,
        title: approve ? 'Approved' : 'Disapproved',
      );
      widget.onDecided();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showToast(context, e.message, isSuccess: false, title: 'Error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.task;
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
              _AppBadge(app: t.app),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.employee.isEmpty ? t.no : t.employee,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text('${t.category} • ${t.no}',
                        style: const TextStyle(
                            fontSize: 12.5, color: AppColors.inkSoft)),
                  ],
                ),
              ),
              StatusPill(
                label: t.status,
                color: approvalStatusColor(t.status),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.isRequests) ...[
            _kv('Company', t.company),
            _kv('Request type', t.requestTypeName),
            _kv('Request date', t.dateApplied),
            _kv('Date sent', t.dateSent),
            _kv('Reason', t.reason),
          ] else ...[
            _kv('Application date', t.dateApplied),
            _kv('Date sent', t.dateSent),
            if (t.txnDate.isNotEmpty) _kv('Record date', t.txnDate),
            _kv('Applied hours', t.appliedHours),
            _kv('Approved OT hours', t.approvedOtHours),
            // Reason (LOA / MAD / OT) or Purpose (CA) — from the head table.
            _kv(t.app == 'CA' ? 'Purpose' : 'Reason', t.reason),
          ],
          if (t.approvedDate.isNotEmpty) _kv('Approved date', t.approvedDate),
          if (t.approvedBy.isNotEmpty) _kv('Decided by', t.approvedBy),
          const SizedBox(height: 18),
          if (t.isPending)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : () => _decide(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.brandRed,
                      side:
                          BorderSide(color: AppColors.brandRed, width: 1.4),
                      backgroundColor: AppColors.dangerSoft,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Disapprove',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _busy ? null : () => _decide(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    icon: _busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.2, color: Colors.white))
                        : const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Approve',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.fieldFill,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'This filing was ${t.status.toLowerCase()}.',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: AppColors.inkSoft),
              ),
            ),
        ],
      ),
    );
  }

  Widget _kv(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: AppColors.inkFaint,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// GENERIC CHOICE SHEET (application type / employee / status)
// -----------------------------------------------------------------------------
class _ChoiceSheet extends StatelessWidget {
  const _ChoiceSheet({
    required this.title,
    required this.current,
    required this.options,
    required this.onApply,
  });

  final String title;
  final String current;
  final List<String> options;
  final void Function(String) onApply;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

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
          const SizedBox(height: 18),
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 380),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: options.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final opt = options[i];
                final sel = opt == current;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    opt,
                    style: TextStyle(
                      fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
                      color: sel ? primary : AppColors.ink,
                    ),
                  ),
                  trailing: sel
                      ? Icon(Icons.check_rounded, color: primary)
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    onApply(opt);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// DATE RANGE SELECTION SHEET
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
    final primary = Theme.of(context).colorScheme.primary;

    final presets = <Map<String, dynamic>>[
      {
        'label': 'Year ${now.year}',
        'start': DateTime(now.year, 1, 1),
        'end': DateTime(now.year, 12, 31),
      },
      {
        'label': 'This month',
        'start': DateTime(now.year, now.month, 1),
        'end': DateTime(now.year, now.month + 1, 0),
      },
      {
        'label': 'Last month',
        'start': DateTime(now.year, now.month - 1, 1),
        'end': DateTime(now.year, now.month, 0),
      },
      {
        'label': 'Year ${now.year - 1}',
        'start': DateTime(now.year - 1, 1, 1),
        'end': DateTime(now.year - 1, 12, 31),
      },
    ];

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
          const SizedBox(height: 18),
          const Text('Filter by Date Range',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          for (final p in presets) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                p['label'] as String,
                style: TextStyle(
                  fontWeight: currentLabel == p['label']
                      ? FontWeight.w800
                      : FontWeight.w600,
                  color: currentLabel == p['label']
                      ? primary
                      : AppColors.ink,
                ),
              ),
              trailing: currentLabel == p['label']
                  ? Icon(Icons.check_rounded, color: primary)
                  : null,
              onTap: () => onSelectPreset(
                p['label'] as String,
                p['start'] as DateTime,
                p['end'] as DateTime,
              ),
            ),
            const Divider(height: 1),
          ],
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.date_range_rounded, color: primary),
            title: const Text('Custom date range…',
                style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.inkSoft),
            onTap: onCustomRange,
          ),
        ],
      ),
    );
  }
}
