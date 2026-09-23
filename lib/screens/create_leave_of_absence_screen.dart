import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/hris_api.dart';
import '../theme/app_colors.dart';
import '../widgets/ui.dart';

/// A clearly-visible field border (the theme's hairline is too faint on the
/// form background), and its focused/active variant.
const Color _kFieldBorder = Color(0xFFC3C9D4);
const double _kBorderWidth = 1.6;

/// Create Leave of Absence — simple filing form matching the web layout.
/// Every field shows a visible border that turns red while it's active
/// (focused / being edited). Applied Hours = the From–To span less a 1-hour
/// break for spans of five hours or more (so 08:00 AM–06:00 PM → 9:00).
class CreateLeaveOfAbsenceScreen extends StatefulWidget {
  const CreateLeaveOfAbsenceScreen({
    super.key,
    this.initialId,
    this.initialNo,
    this.initialLeaveType,
    this.initialDateFrom,
    this.initialDateTo,
    this.initialReason,
    this.initialTxnDate,
  });

  final int? initialId;
  final String? initialNo;
  final String? initialLeaveType;
  final DateTime? initialDateFrom;
  final DateTime? initialDateTo;
  final String? initialReason;
  final String? initialTxnDate;

  @override
  State<CreateLeaveOfAbsenceScreen> createState() =>
      _CreateLeaveOfAbsenceScreenState();
}

class _CreateLeaveOfAbsenceScreenState
    extends State<CreateLeaveOfAbsenceScreen> {
  late DateTime _from;
  late DateTime _to;
  late String _leaveType;
  final _reason = TextEditingController();

  /// Which field is currently active, so its border shows red.
  String? _active;

  /// True when the "To" date is before "From" — used to flag the fields in red
  /// immediately (not only on submit).
  bool get _invalidRange => _to.isBefore(_from);

  bool get _isEditing => widget.initialId != null;

  static const _leaveTypes = <String>[
    'Approved Leave',
    'Approved UT (AM/PM)',
    'Vacation Leave',
    'Sick Leave',
    'Additional VL',
    'Accumulated Leave',
  ];

  static DateTime? parseDateTime(dynamic val, {bool isFrom = true}) {
    if (val == null) return null;
    if (val is DateTime) return val;
    final str = val.toString().trim();
    if (str.isEmpty) return null;

    final iso = DateTime.tryParse(str);
    if (iso != null) {
      if (str.length <= 10) {
        return DateTime(iso.year, iso.month, iso.day, isFrom ? 8 : 18, 0);
      }
      return iso;
    }

    const months = {
      'january': 1, 'february': 2, 'march': 3, 'april': 4, 'may': 5,
      'june': 6, 'july': 7, 'august': 8, 'september': 9, 'october': 10,
      'november': 11, 'december': 12, 'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4,
      'jun': 6, 'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    };

    final m1 = RegExp(
            r'^(\d{1,2})/(\d{1,2})/(\d{4})(?:\s+(\d{1,2}):(\d{1,2})(?:\s*(AM|PM))?)?',
            caseSensitive: false)
        .firstMatch(str);
    if (m1 != null) {
      final mon = int.parse(m1.group(1)!);
      final day = int.parse(m1.group(2)!);
      final yr = int.parse(m1.group(3)!);
      if (m1.group(4) != null) {
        var hr = int.parse(m1.group(4)!);
        final min = int.parse(m1.group(5) ?? '0');
        final ampm = m1.group(6)?.toUpperCase();
        if (ampm == 'PM' && hr < 12) hr += 12;
        if (ampm == 'AM' && hr == 12) hr = 0;
        return DateTime(yr, mon, day, hr, min);
      }
      return DateTime(yr, mon, day, isFrom ? 8 : 18, 0);
    }

    final m2 = RegExp(
            r'^([A-Za-z]+)\s+(\d{1,2}),?\s+(\d{4})(?:\s+(\d{1,2}):(\d{1,2})(?:\s*(AM|PM))?)?',
            caseSensitive: false)
        .firstMatch(str);
    if (m2 != null) {
      final mon = months[m2.group(1)!.toLowerCase()];
      if (mon != null) {
        final day = int.parse(m2.group(2)!);
        final yr = int.parse(m2.group(3)!);
        if (m2.group(4) != null) {
          var hr = int.parse(m2.group(4)!);
          final min = int.parse(m2.group(5) ?? '0');
          final ampm = m2.group(6)?.toUpperCase();
          if (ampm == 'PM' && hr < 12) hr += 12;
          if (ampm == 'AM' && hr == 12) hr = 0;
          return DateTime(yr, mon, day, hr, min);
        }
        return DateTime(yr, mon, day, isFrom ? 8 : 18, 0);
      }
    }

    return null;
  }

  static String _normalizeLeaveType(String? t) {
    if (t == null || t.isEmpty) return 'Approved Leave';
    // Match an existing option case-insensitively so a value coming back from
    // the server keeps the user's real leave type instead of collapsing to
    // "Approved Leave".
    final lower = t.toLowerCase().trim();
    for (final option in _leaveTypes) {
      if (option.toLowerCase() == lower) return option;
    }
    if (lower.contains('accumulated')) return 'Accumulated Leave';
    if (lower.contains('additional') && lower.contains('vl')) {
      return 'Additional VL';
    }
    if (lower == 'vl' || lower.contains('vacation')) return 'Vacation Leave';
    if (lower == 'sl' || lower.contains('sick')) return 'Sick Leave';
    if (lower.contains('ut')) return 'Approved UT (AM/PM)';
    return 'Approved Leave';
  }

  bool _loadingServer = false;

  /// Leave types offered in the picker. Approved Leave / Approved UT are always
  /// available; VL, SL, Additional VL and Accumulated Leave are added only when
  /// the employee actually has that balance (loaded from the leave balance).
  List<String> _availableTypes = const [
    'Approved Leave',
    'Approved UT (AM/PM)',
  ];

  @override
  void initState() {
    super.initState();
    _leaveType = _normalizeLeaveType(widget.initialLeaveType);
    _reason.text = widget.initialReason ?? '';
    _loadLeaveTypes();

    final now = DateTime.now();
    _from = parseAppDateTime(widget.initialDateFrom, isFrom: true) ??
        parseAppDateTime(widget.initialTxnDate, isFrom: true) ??
        DateTime(now.year, now.month, now.day, 8, 0);

    _to = parseAppDateTime(widget.initialDateTo, isFrom: false) ??
        parseAppDateTime(widget.initialTxnDate, isFrom: false) ??
        DateTime(now.year, now.month, now.day, 18, 0);

    if (widget.initialId != null && widget.initialId! > 0) {
      _loadServerRecord();
    }
  }

  /// Builds the picker list from the employee's leave balance: the two default
  /// types plus any of VL / SL / Additional VL / Accumulated Leave they hold.
  Future<void> _loadLeaveTypes() async {
    try {
      final bal = await HrisApi.instance.leaveBalance();
      bool bucket(String needle) => bal.buckets.any((b) =>
          b.type.toLowerCase().contains(needle) && b.remaining > 0);
      final hasVL = bucket('vacation') || bucket('vl ') || bucket(' vl') ||
          (bal.vlPaidHours ?? 0) > 0;
      final hasSL = bucket('sick') || bucket('sl ') || bucket(' sl') ||
          (bal.slPaidHours ?? 0) > 0;
      final hasAdditionalVL =
          bucket('additional') || (bal.additionalVl != null);
      final hasAccumulated = bucket('accumulated');

      final types = <String>[
        'Approved Leave',
        'Approved UT (AM/PM)',
        if (hasVL) 'Vacation Leave',
        if (hasSL) 'Sick Leave',
        if (hasAdditionalVL) 'Additional VL',
        if (hasAccumulated) 'Accumulated Leave',
      ];
      if (mounted) setState(() => _availableTypes = types);
    } catch (_) {
      // Keep the two defaults if the balance can't be loaded.
    }
  }

  Future<void> _loadServerRecord() async {
    setState(() => _loadingServer = true);
    try {
      final r = await HrisApi.instance.getRequest('loa', widget.initialId!);
      if (!mounted) return;
      setState(() {
        final rawType = r.leaveType ??
            r.rawJson?['leave_type'] ??
            r.rawJson?['type'] ??
            r.rawJson?['category'];
        if (rawType != null && rawType.toString().trim().isNotEmpty) {
          _leaveType = _normalizeLeaveType(rawType.toString());
        }

        final rawReason = r.reason ??
            r.rawJson?['reason'] ??
            r.rawJson?['remarks'] ??
            r.rawJson?['purpose'] ??
            r.rawJson?['description'] ??
            r.rawJson?['notes'] ??
            r.rawJson?['justification'] ??
            r.rawJson?['details'];
        if (rawReason != null && rawReason.toString().trim().isNotEmpty) {
          _reason.text = rawReason.toString().trim();
        }

        final rawFrom = r.dateFrom ??
            r.rawJson?['date_from'] ??
            r.rawJson?['start_date'] ??
            r.rawJson?['from'] ??
            r.rawJson?['date_start'] ??
            r.rawJson?['from_datetime'] ??
            r.txnDate;
        if (rawFrom != null) {
          final df = parseAppDateTime(rawFrom, isFrom: true);
          if (df != null) _from = df;
        }

        final rawTo = r.dateTo ??
            r.rawJson?['date_to'] ??
            r.rawJson?['end_date'] ??
            r.rawJson?['to'] ??
            r.rawJson?['date_end'] ??
            r.rawJson?['to_datetime'] ??
            r.txnDate;
        if (rawTo != null) {
          final dt = parseAppDateTime(rawTo, isFrom: false);
          if (dt != null) _to = dt;
        }
      });
    } catch (e) {
      debugPrint('Error loading LOA server record by ID: $e');
    } finally {
      if (mounted) setState(() => _loadingServer = false);
    }
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  int get _appliedMinutes {
    var mins = _to.difference(_from).inMinutes;
    if (mins < 0) mins = 0;
    if (mins >= 300) mins -= 60; // 1-hour break on spans of 5h+
    return mins;
  }

  String get _appliedHours =>
      '${_appliedMinutes ~/ 60}:${(_appliedMinutes % 60).toString().padLeft(2, '0')}';

  /// Decimal hours for the DB (no_of_hours), e.g. 9.0.
  double get _appliedHoursDecimal =>
      double.parse((_appliedMinutes / 60).toStringAsFixed(2));

  Future<void> _pickLeaveType() async {
    setState(() => _active = 'type');
    final picked = await showPremiumBottomSheet<String>(
      context,
      builder: (ctx) =>
          _LeaveTypeSheet(current: _leaveType, types: _availableTypes),
    );
    if (picked != null && mounted) _leaveType = picked;
    if (mounted) setState(() => _active = null);
  }

  Future<void> _pick(bool isFrom) async {
    setState(() => _active = isFrom ? 'from' : 'to');
    final base = isFrom ? _from : _to;
    final date = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date != null && mounted) {
      // Time is editable; it defaults to the current value (8:00 AM / 6:00 PM).
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(base),
      );
      final t = time ?? TimeOfDay.fromDateTime(base);
      final dt = DateTime(date.year, date.month, date.day, t.hour, t.minute);
      if (isFrom) {
        _from = dt;
      } else {
        _to = dt;
      }
    }
    if (mounted) setState(() => _active = null);
  }

  String _fmt(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    var h = d.hour % 12;
    if (h == 0) h = 12;
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    final min = d.minute.toString().padLeft(2, '0');
    return '$mm/$dd/${d.year} ${h.toString().padLeft(2, '0')}:$min $ampm';
  }

  bool _submitting = false;

  String _fmtDate(DateTime d) =>
      '${_monthName(d.month)} ${d.day.toString().padLeft(2, '0')}, ${d.year}';

  static String _monthName(int m) => const [
        'January', 'February', 'March', 'April', 'May', 'June', 'July',
        'August', 'September', 'October', 'November', 'December'
      ][m - 1];

  Future<void> _submit() async {
    if (_submitting) return;
    // The invalid range is already flagged inline (red fields), so just block
    // the submit quietly — no sliding toast.
    if (_invalidRange) return;
    setState(() => _submitting = true);
    showLoadingOverlay(context);
    try {
      final payload = {
        'leave_type': _leaveType,
        'date_from': _from.toIso8601String(),
        'date_to': _to.toIso8601String(),
        'no_of_hours': _appliedHoursDecimal,
        'txn_date': _fmtDate(_from),
        'applied_hours': _appliedHours,
        'reason': _reason.text.trim(),
      };

      if (_isEditing) {
        await HrisApi.instance.updateRequest('loa', widget.initialId!, payload);
        if (!mounted) return;
        hideLoadingOverlay(context);
        await showToast(context,
            'Leave of absence record has been updated.',
            isSuccess: true, title: 'Record Updated');
      } else {
        await HrisApi.instance.createRequest('loa', payload);
        if (!mounted) return;
        hideLoadingOverlay(context);
        await showToast(context,
            'Your leave of absence has been created. Open it and tap “Send for Approval” when ready.',
            isSuccess: true, title: 'Record Created');
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      hideLoadingOverlay(context);
      if (mounted) {
        showToast(context, e.message, isSuccess: false, title: 'Submission Error');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      // Keep the whole form on one screen — no scrolling.
      // Let the keyboard shift the layout so the Reason field stays visible.
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(_isEditing
            ? 'Edit ${widget.initialNo ?? "Leave of Absence"}'
            : 'Create Leave of Absence'),
      ),
      body: _loadingServer
          ? Center(child: CircularProgressIndicator(color: AppColors.brandRed))
          : SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              _Labeled(
                label: 'From',
                child: _DateField(
                  value: _fmt(_from),
                  active: _active == 'from',
                  error: _invalidRange,
                  onTap: () => _pick(true),
                ),
              ),
              const SizedBox(height: 12),
              _Labeled(
                label: 'To',
                child: _DateField(
                  value: _fmt(_to),
                  active: _active == 'to',
                  error: _invalidRange,
                  onTap: () => _pick(false),
                ),
              ),
              if (_invalidRange) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.error_outline_rounded,
                        size: 15, color: AppColors.brandRed),
                    const SizedBox(width: 6),
                    Text(
                      '"To" must be the same as or after "From".',
                      style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.brandRed,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _Labeled(
                      label: 'Applied Hours',
                      child: _HoursField(value: _appliedHours),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Labeled(
                      label: 'Current Remaining',
                      child: const _HoursField(value: '00:00', muted: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _Labeled(
                label: 'Leave Type',
                child: _SelectField(
                  value: _leaveType,
                  active: _active == 'type',
                  onTap: _pickLeaveType,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Reason',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 7),
              // Use bounded minLines/maxLines instead of expands:true —
              // expanding TextFields inside nested Expanded columns drop
              // keystrokes on iOS when the keyboard reflows the layout.
              TextField(
                controller: _reason,
                minLines: 4,
                maxLines: 8,
                textAlignVertical: TextAlignVertical.top,
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  hintText: 'Add a reason for this request…',
                  filled: true,
                  fillColor: AppColors.fieldFill,
                  enabledBorder: _border(_kFieldBorder, _kBorderWidth),
                  focusedBorder: _border(AppColors.brandRed, 1.8),
                ),
              ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: Text(_isEditing ? 'Save Changes' : 'Create'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static OutlineInputBorder _border(Color color, double width) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );
}

class _Labeled extends StatelessWidget {
  const _Labeled({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 7),
        child,
      ],
    );
  }
}

/// Tappable date-time field with a visible border (red while active).
class _DateField extends StatelessWidget {
  const _DateField({
    required this.value,
    required this.active,
    required this.onTap,
    this.error = false,
  });

  final String value;
  final bool active;
  final VoidCallback onTap;

  /// When true the field is outlined in red to flag an invalid date range.
  final bool error;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: error ? AppColors.dangerSoft : AppColors.fieldFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: error
                ? AppColors.brandRed
                : (active ? AppColors.brandRed : _kFieldBorder),
            width: error ? 1.6 : _kBorderWidth,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ),
            const Icon(Icons.calendar_month_rounded,
                size: 20, color: AppColors.inkSoft),
          ],
        ),
      ),
    );
  }
}

/// Read-only hh:mm field with a leading clock box and a visible border.
class _HoursField extends StatelessWidget {
  const _HoursField({required this.value, this.muted = false});

  final String value;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.fieldFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kFieldBorder, width: _kBorderWidth),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 54,
            decoration: const BoxDecoration(
              color: Color(0xFFE7E8EC),
              borderRadius: BorderRadius.horizontal(left: Radius.circular(13)),
            ),
            child: const Icon(Icons.schedule_rounded,
                size: 20, color: AppColors.inkSoft),
          ),
          const SizedBox(width: 14),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: muted ? AppColors.inkFaint : AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tappable select field (opens a bottom-sheet picker) with a visible border.
class _SelectField extends StatelessWidget {
  const _SelectField({
    required this.value,
    required this.active,
    required this.onTap,
  });

  final String value;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.fieldFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? AppColors.brandRed : _kFieldBorder,
            width: _kBorderWidth,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded,
                size: 22, color: AppColors.inkSoft),
          ],
        ),
      ),
    );
  }
}

/// Modern bottom-sheet picker for the leave type.
class _LeaveTypeSheet extends StatelessWidget {
  const _LeaveTypeSheet({required this.current, required this.types});

  final String current;
  final List<String> types;

  IconData _iconFor(String t) => t.contains('UT')
      ? Icons.timelapse_rounded
      : Icons.event_available_rounded;

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
          const Text('Select Leave Type',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          for (final t in types) ...[
            _option(context, t),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _option(BuildContext context, String t) {
    final selected = t == current;
    return Material(
      color: selected ? AppColors.dangerSoft : AppColors.fieldFill,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.pop(context, t),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.brandRed : _kFieldBorder,
              width: selected ? 1.6 : 1.3,
            ),
          ),
          child: Row(
            children: [
              Icon(_iconFor(t),
                  size: 22,
                  color: selected ? AppColors.brandRed : AppColors.inkSoft),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  t,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: selected ? AppColors.brandRed : AppColors.ink,
                  ),
                ),
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
}
