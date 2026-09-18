import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/hris_api.dart';
import '../theme/app_colors.dart';
import '../widgets/ui.dart';

/// Clearly-visible field border (the theme hairline is too faint on the form).
const Color _kFieldBorder = Color(0xFFC3C9D4);

/// Create screen for the Record / Request hub, matching the web "Create Call
/// Approval" form: a date plus one or more rows of Time From / Time To / Hrs /
/// Customer / Purpose. Submits to `POST /auth/requests/:type`.
class CreateCallApprovalScreen extends StatefulWidget {
  const CreateCallApprovalScreen({
    super.key,
    required this.type,
    required this.title,
  });

  final String type;
  final String title;

  @override
  State<CreateCallApprovalScreen> createState() =>
      _CreateCallApprovalScreenState();
}

class _CallRow {
  // Default to the current time of day.
  TimeOfDay from = TimeOfDay.now();
  TimeOfDay to = TimeOfDay.now();
  final customer = TextEditingController();
  final purpose = TextEditingController();

  int get _minutes {
    var mins = (to.hour * 60 + to.minute) - (from.hour * 60 + from.minute);
    return mins < 0 ? 0 : mins;
  }

  String get hrs =>
      '${_minutes ~/ 60}:${(_minutes % 60).toString().padLeft(2, '0')}';

  double get hoursDecimal =>
      double.parse((_minutes / 60).toStringAsFixed(2));

  void dispose() {
    customer.dispose();
    purpose.dispose();
  }

  /// Builds the payload row using [date] for the calendar day + the picked
  /// times, so the server gets real datetimes.
  Map<String, dynamic> toJson(DateTime date) {
    final f = DateTime(date.year, date.month, date.day, from.hour, from.minute);
    final t = DateTime(date.year, date.month, date.day, to.hour, to.minute);
    return {
      'date_from': f.toIso8601String(),
      'date_to': t.toIso8601String(),
      'no_of_hrs': hoursDecimal,
      'customer': customer.text.trim(),
      'purpose': purpose.text.trim(),
    };
  }
}

class _CreateCallApprovalScreenState extends State<CreateCallApprovalScreen> {
  DateTime _date = DateTime.now();
  final List<_CallRow> _rows = [_CallRow()];
  bool _submitting = false;

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  String _fmtDate(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';

  String _fmtTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final ampm = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '${h.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')} $ampm';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime(_CallRow row, bool isFrom) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isFrom ? row.from : row.to,
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          row.from = picked;
        } else {
          row.to = picked;
        }
      });
    }
  }

  void _addRow() => setState(() => _rows.add(_CallRow()));

  void _removeRow(int i) {
    if (_rows.length == 1) {
      showToast(context, 'At least one row is required to submit.', isSuccess: false, title: 'No Data');
      return;
    }
    setState(() {
      _rows.removeAt(i).dispose();
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await HrisApi.instance.createRequest(widget.type, {
        'date': _fmtDate(_date),
        'txn_date': _fmtDate(_date),
        'rows': _rows.map((r) => r.toJson(_date)).toList(),
      });
      if (!mounted) return;
      await showToast(context,
          '${widget.title} has been created. Open it and tap “Send for Approval” when ready.',
          isSuccess: true, title: 'Record Created');
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message, isSuccess: false, title: 'Submission Error');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text('Create ${widget.title}')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            const Text('Call Approval Date',
                style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 8),
            _fieldBox(
              onTap: _pickDate,
              child: Row(
                children: [
                  Expanded(
                      child: Text(_fmtDate(_date),
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600))),
                  const Icon(Icons.calendar_today_rounded,
                      size: 18, color: AppColors.inkSoft),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Divider(),
            const SizedBox(height: 8),
            for (int i = 0; i < _rows.length; i++) _rowCard(i),
            const SizedBox(height: 4),
            // Full-width green Add Row button.
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addRow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Row',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
      // Bottom Cancel / Create — same layout as Create Leave of Absence.
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      _submitting ? null : () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    side: const BorderSide(color: AppColors.line),
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Cancel',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandRed,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.4, color: Colors.white),
                        )
                      : const Text('Create',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rowCard(int i) {
    final row = _rows[i];
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kFieldBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Line 1: "Time From" label + compact minus, then the field.
          Row(
            children: [
              const Text('Time From',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      color: AppColors.ink)),
              const Spacer(),
              InkWell(
                onTap: () => _removeRow(i),
                customBorder: const CircleBorder(),
                child: Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.brandRed, width: 1.6),
                  ),
                  child: Icon(Icons.remove_rounded,
                      color: AppColors.brandRed, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _timeBox(row, true, _fmtTime(row.from)),
          const SizedBox(height: 10),
          // Line 2: Time To + Hrs alongside
          Row(
            children: [
              Expanded(
                child:
                    _labeled('Time To', _timeBox(row, false, _fmtTime(row.to))),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 74,
                child: _labeled(
                  'Hrs.',
                  _fieldBox(
                    child: Text(row.hrs,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Line 3: Customer (full width)
          _labeled('Customer', _inputBox(row.customer, 'Customer')),
          const SizedBox(height: 10),
          // Line 4: Purpose (full width)
          _labeled('Purpose', _inputBox(row.purpose, 'Purpose')),
        ],
      ),
    );
  }

  Widget _labeled(String label, Widget child) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  color: AppColors.ink)),
          const SizedBox(height: 6),
          child,
        ],
      );

  Widget _fieldBox({required Widget child, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: AppColors.fieldFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kFieldBorder, width: 1.4),
        ),
        child: child,
      ),
    );
  }

  Widget _timeBox(_CallRow row, bool isFrom, String value) => _fieldBox(
        onTap: () => _pickTime(row, isFrom),
        child: Row(
          children: [
            Expanded(
                child: Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13.5))),
            const Icon(Icons.access_time_rounded,
                size: 16, color: AppColors.inkSoft),
          ],
        ),
      );

  Widget _inputBox(TextEditingController c, String hint) {
    return TextField(
      controller: c,
      minLines: 3,
      maxLines: 5,
      textCapitalization: TextCapitalization.sentences,
      textAlignVertical: TextAlignVertical.top,
      decoration: InputDecoration(
        hintText: hint,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        filled: true,
        fillColor: AppColors.fieldFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kFieldBorder, width: 1.4),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kFieldBorder, width: 1.4),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.brandRed, width: 1.6),
        ),
      ),
    );
  }
}
