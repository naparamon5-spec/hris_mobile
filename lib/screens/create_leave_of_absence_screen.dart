import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Create Leave of Absence — simple filing form matching the web layout.
/// Every field shows a visible border that turns red while it's active
/// (focused / being edited). Applied Hours = the From–To span less a 1-hour
/// break for spans of five hours or more (so 08:00 AM–06:00 PM → 9:00).
class CreateLeaveOfAbsenceScreen extends StatefulWidget {
  const CreateLeaveOfAbsenceScreen({super.key});

  @override
  State<CreateLeaveOfAbsenceScreen> createState() =>
      _CreateLeaveOfAbsenceScreenState();
}

class _CreateLeaveOfAbsenceScreenState
    extends State<CreateLeaveOfAbsenceScreen> {
  DateTime _from = DateTime(2026, 9, 9, 8, 0);
  DateTime _to = DateTime(2026, 9, 9, 18, 0);
  String _leaveType = 'Approved Leave';
  final _reason = TextEditingController();

  /// Which field is currently active, so its border shows red.
  String? _active;

  static const _leaveTypes = <String>[
    'Approved Leave',
    'Approved UT (AM/PM)',
    'Sick Leave',
    'Vacation Leave',
    'Emergency Leave',
  ];

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  String get _appliedHours {
    var mins = _to.difference(_from).inMinutes;
    if (mins < 0) mins = 0;
    if (mins >= 300) mins -= 60; // 1-hour break on spans of 5h+
    return '${mins ~/ 60}:${(mins % 60).toString().padLeft(2, '0')}';
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
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(base),
      );
      if (time != null && mounted) {
        final dt =
            DateTime(date.year, date.month, date.day, time.hour, time.minute);
        if (isFrom) {
          _from = dt;
        } else {
          _to = dt;
        }
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

  void _submit() {
    if (_to.isBefore(_from)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('"To" must be after "From".')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Leave of absence submitted for approval.')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      // Keep the whole form on one screen — no scrolling.
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text('Create Leave of Absence')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Labeled(
                label: 'From',
                child: _DateField(
                  value: _fmt(_from),
                  active: _active == 'from',
                  onTap: () => _pick(true),
                ),
              ),
              const SizedBox(height: 12),
              _Labeled(
                label: 'To',
                child: _DateField(
                  value: _fmt(_to),
                  active: _active == 'to',
                  onTap: () => _pick(false),
                ),
              ),
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
                child: _TypeDropdown(
                  value: _leaveType,
                  items: _leaveTypes,
                  onChanged: (v) =>
                      setState(() => _leaveType = v ?? _leaveType),
                ),
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
                          enabledBorder: _border(AppColors.line, 1.4),
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
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Submit Request'),
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

/// Tappable date-time field with a visible border (red while active).
class _DateField extends StatelessWidget {
  const _DateField({
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
            color: active ? AppColors.brandRed : AppColors.line,
            width: active ? 1.8 : 1.4,
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
        border: Border.all(color: AppColors.line, width: 1.4),
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

/// Leave-type dropdown with a visible border.
class _TypeDropdown extends StatelessWidget {
  const _TypeDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.fieldFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line, width: 1.4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          borderRadius: BorderRadius.circular(14),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.inkSoft),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
          dropdownColor: AppColors.card,
          items: [
            for (final item in items)
              DropdownMenuItem(value: item, child: Text(item)),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
