import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/hris_api.dart';
import '../theme/app_colors.dart';
import '../widgets/ui.dart';

/// A clearly-visible field border (matches Create Leave of Absence), and its
/// focused/active variant.
const Color _kFieldBorder = Color(0xFFC3C9D4);
const double _kBorderWidth = 1.6;

/// Single-entry create form used by Manual Arrival/Departure and Overtime.
/// Styled identically to Create Leave of Absence: a date, Time From / Time To,
/// an auto-computed Applied Hours (hh:mm), and a Reason. Applied Hours = the
/// From–To span less a 1-hour break for spans of five hours or more (Manual
/// A/D); overtime counts every hour. Submits to `POST /auth/requests/:type` as
/// a draft that the user can later send for approval.
class CreateTimeEntryScreen extends StatefulWidget {
  const CreateTimeEntryScreen({
    super.key,
    required this.type,
    required this.title,
    required this.dateLabel,
    this.deductBreak = true,
    this.defaultFrom = const TimeOfDay(hour: 8, minute: 0),
    this.defaultTo = const TimeOfDay(hour: 18, minute: 0),
    this.initialId,
    this.initialNo,
    this.initialDate,
    this.initialFrom,
    this.initialTo,
    this.initialReason,
  });

  final String type;
  final String title;

  /// Label above the date field, e.g. 'MAD Date' or 'Overtime Date'.
  final String dateLabel;

  /// Manual A/D deducts a 1-hour break on spans of 5h+; overtime counts every
  /// hour, so it passes false.
  final bool deductBreak;

  final TimeOfDay defaultFrom;
  final TimeOfDay defaultTo;

  final int? initialId;
  final String? initialNo;
  final DateTime? initialDate;
  final TimeOfDay? initialFrom;
  final TimeOfDay? initialTo;
  final String? initialReason;

  @override
  State<CreateTimeEntryScreen> createState() => _CreateTimeEntryScreenState();
}

class _CreateTimeEntryScreenState extends State<CreateTimeEntryScreen> {
  late DateTime _date;
  late TimeOfDay _from;
  late TimeOfDay _to;
  final _reason = TextEditingController();
  bool _submitting = false;

  /// Which field is currently active, so its border shows red.
  String? _active;

  bool get _isEditing => widget.initialId != null;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate ?? DateTime.now();
    _from = widget.initialFrom ?? widget.defaultFrom;
    _to = widget.initialTo ?? widget.defaultTo;
    _reason.text = widget.initialReason ?? '';

    if (widget.initialId != null && widget.initialId! > 0) {
      _loadServerRecord();
    }
  }

  Future<void> _loadServerRecord() async {
    try {
      final r = await HrisApi.instance.getRequest(widget.type, widget.initialId!);
      if (!mounted) return;
      setState(() {
        if (r.reason != null && r.reason!.isNotEmpty) {
          _reason.text = r.reason!;
        }
        final d = parseAppDateTime(r.dateFrom) ?? parseAppDateTime(r.txnDate);
        if (d != null) _date = d;
        final tf = _parseClock(r.timeFrom);
        if (tf != null) _from = tf;
        final tt = _parseClock(r.timeTo);
        if (tt != null) _to = tt;
      });
    } catch (_) {}
  }

  // "HH:mm" (24h) -> TimeOfDay; null on anything unparseable.
  TimeOfDay? _parseClock(String? s) {
    if (s == null) return null;
    final m = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(s.trim());
    if (m == null) return null;
    return TimeOfDay(hour: int.parse(m.group(1)!), minute: int.parse(m.group(2)!));
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  int get _appliedMinutes {
    var mins = (_to.hour * 60 + _to.minute) - (_from.hour * 60 + _from.minute);
    if (mins < 0) mins += 24 * 60; // spans crossing midnight (e.g. 7PM–12AM)
    if (widget.deductBreak && mins >= 300) mins -= 60; // 1-hour break on 5h+
    return mins;
  }

  String get _appliedHours =>
      '${_appliedMinutes ~/ 60}:${(_appliedMinutes % 60).toString().padLeft(2, '0')}';

  String _fmtDate(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';

  String _fmtTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final ampm = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '${h.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')} $ampm';
  }

  Future<void> _pickDate() async {
    setState(() => _active = 'date');
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) _date = picked;
    if (mounted) setState(() => _active = null);
  }

  Future<void> _pickTime(bool isFrom) async {
    setState(() => _active = isFrom ? 'from' : 'to');
    final picked = await showTimePicker(
      context: context,
      initialTime: isFrom ? _from : _to,
    );
    if (picked != null && mounted) {
      if (isFrom) {
        _from = picked;
      } else {
        _to = picked;
      }
    }
    if (mounted) setState(() => _active = null);
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    showLoadingOverlay(context);
    try {
      final payload = {
        'txn_date': _fmtDate(_date),
        'time_from': _fmtTime(_from),
        'time_to': _fmtTime(_to),
        'applied_hours': _appliedHours,
        'reason': _reason.text.trim(),
      };

      if (_isEditing) {
        await HrisApi.instance.updateRequest(widget.type, widget.initialId!, payload);
        if (!mounted) return;
        hideLoadingOverlay(context);
        await showToast(context, '${widget.title} record has been updated.',
            isSuccess: true, title: 'Record Updated');
      } else {
        await HrisApi.instance.createRequest(widget.type, payload);
        if (!mounted) return;
        hideLoadingOverlay(context);
        await showToast(
            context,
            'Your ${widget.title} record has been created. Open it and tap “Send for Approval” when ready.',
            isSuccess: true,
            title: 'Record Created');
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
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(_isEditing
            ? 'Edit ${widget.initialNo ?? widget.title}'
            : 'Create ${widget.title}'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Labeled(
                label: widget.dateLabel,
                child: _TapField(
                  value: _fmtDate(_date),
                  active: _active == 'date',
                  icon: Icons.calendar_month_rounded,
                  onTap: _pickDate,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _Labeled(
                      label: 'Time From',
                      child: _TapField(
                        value: _fmtTime(_from),
                        active: _active == 'from',
                        icon: Icons.schedule_rounded,
                        onTap: () => _pickTime(true),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Labeled(
                      label: 'Time To',
                      child: _TapField(
                        value: _fmtTime(_to),
                        active: _active == 'to',
                        icon: Icons.schedule_rounded,
                        onTap: () => _pickTime(false),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _Labeled(
                label: 'Applied Hours',
                child: _HoursField(value: _appliedHours),
              ),
              const SizedBox(height: 12),
              // Reason flexes to fill whatever height is left.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reason',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Expanded(
                      child: TextField(
                        controller: _reason,
                        expands: true,
                        maxLines: null,
                        textAlignVertical: TextAlignVertical.top,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: 'Add a reason for this request…',
                          filled: true,
                          fillColor: AppColors.fieldFill,
                          enabledBorder: _border(_kFieldBorder, _kBorderWidth),
                          focusedBorder: _border(AppColors.brandRed, 1.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _submitting ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      child: Text(_isEditing ? 'Save Changes' : 'Create'),
                    ),
                  ),
                ],
              ),
            ],
          ),
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

/// Tappable field with a visible border (red while active) and a trailing icon.
class _TapField extends StatelessWidget {
  const _TapField({
    required this.value,
    required this.active,
    required this.icon,
    required this.onTap,
  });

  final String value;
  final bool active;
  final IconData icon;
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
            Icon(icon, size: 20, color: AppColors.inkSoft),
          ],
        ),
      ),
    );
  }
}

/// Read-only hh:mm field with a leading clock box and a visible border.
class _HoursField extends StatelessWidget {
  const _HoursField({required this.value});

  final String value;

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
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
