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
    this.initialId,
    this.initialNo,
    this.initialDate,
    this.initialRows,
  });

  final String type;
  final String title;

  /// When set, the screen loads the record for editing and PUTs on submit.
  final int? initialId;
  final String? initialNo;
  final DateTime? initialDate;

  /// Seed rows shown before the server fetch resolves — one per line the user
  /// entered on Create. Each map may carry: from (TimeOfDay), to (TimeOfDay),
  /// customer (String), purpose (String).
  final List<Map<String, dynamic>>? initialRows;

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
    if (mins < 0) mins += 24 * 60;
    return mins;
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
  late DateTime _date;
  final List<_CallRow> _rows = [];
  bool _submitting = false;

  bool get _isEditing => widget.initialId != null;

  /// Blocks the form until the full record is fetched (edit mode) only if
  /// we have no initial rows to show immediately.
  bool _loadingRecord = false;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate ?? DateTime.now();
    final seeds = widget.initialRows;
    if (seeds != null && seeds.isNotEmpty) {
      for (final s in seeds) {
        _rows.add(_rowFromSeed(s));
      }
    } else {
      _rows.add(_CallRow());
    }

    if (_isEditing && widget.initialId! > 0) {
      if (seeds == null || seeds.isEmpty) {
        _loadingRecord = true;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadServerRecord());
    }
  }

  Future<void> _loadServerRecord() async {
    try {
      final r =
          await HrisApi.instance.getRequest(widget.type, widget.initialId!);
      if (!mounted) return;
      // Apply server values BEFORE the form's inputs are built. No later
      // overwrite = no lost keystrokes.
      final d = parseAppDateTime(r.txnDate) ??
          parseAppDateTime(r.rawJson?['ca_date']) ??
          parseAppDateTime(r.rawJson?['date']) ??
          parseAppDateTime(r.dateFrom);
      if (d != null) _date = d;
      final serverRows = _extractRowsFromRaw(r.rawJson);
      if (serverRows.isNotEmpty) {
        for (final row in _rows) {
          row.dispose();
        }
        _rows
          ..clear()
          ..addAll(serverRows.map(_rowFromSeed));
      }
    } catch (_) {
      // Fall back to whatever was passed in — form still opens.
    } finally {
      if (mounted) setState(() => _loadingRecord = false);
    }
  }

  /// Pull the list of call rows out of the raw record JSON, tolerating the
  /// various shapes the backend might return them in.
  List<Map<String, dynamic>> _extractRowsFromRaw(Map<String, dynamic>? raw) {
    if (raw == null) return const [];
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
    return const [];
  }

  _CallRow _rowFromSeed(Map<String, dynamic> s) {
    final row = _CallRow();
    final from = _timeFromSeed(s, const ['from', 'time_from', 'date_from', 'from_time']);
    final to = _timeFromSeed(s, const ['to', 'time_to', 'date_to', 'to_time']);
    if (from != null) row.from = from;
    if (to != null) row.to = to;
    row.customer.text = _stringFromSeed(s, const ['customer', 'customer_name', 'client']);
    row.purpose.text =
        _stringFromSeed(s, const ['purpose', 'reason', 'remarks', 'details', 'notes']);
    return row;
  }

  TimeOfDay? _timeFromSeed(Map<String, dynamic> s, List<String> keys) {
    for (final k in keys) {
      final v = s[k];
      if (v == null) continue;
      if (v is TimeOfDay) return v;
      final str = v.toString().trim();
      if (str.isEmpty) continue;
      // Try ISO-8601 first (server returns datetimes for date_from/date_to).
      final iso = DateTime.tryParse(str);
      if (iso != null) {
        final local = iso.isUtc ? iso.toLocal() : iso;
        return TimeOfDay(hour: local.hour, minute: local.minute);
      }
      // Otherwise HH:mm[am/pm] or HH:mm.
      final m = RegExp(r'(\d{1,2}):(\d{2})\s*([AaPp][Mm])?').firstMatch(str);
      if (m != null) {
        var h = int.parse(m.group(1)!);
        final min = int.parse(m.group(2)!);
        final ampm = m.group(3)?.toLowerCase();
        if (ampm == 'pm' && h < 12) h += 12;
        if (ampm == 'am' && h == 12) h = 0;
        return TimeOfDay(hour: h % 24, minute: min);
      }
    }
    return null;
  }

  String _stringFromSeed(Map<String, dynamic> s, List<String> keys) {
    for (final k in keys) {
      final v = s[k];
      if (v == null) continue;
      final str = v.toString().trim();
      if (str.isNotEmpty) return str;
    }
    return '';
  }

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
      final payload = {
        'date': _fmtDate(_date),
        'txn_date': _fmtDate(_date),
        'rows': _rows.map((r) => r.toJson(_date)).toList(),
      };
      if (_isEditing) {
        await HrisApi.instance
            .updateRequest(widget.type, widget.initialId!, payload);
        if (!mounted) return;
        await showToast(context, '${widget.title} record has been updated.',
            isSuccess: true, title: 'Record Updated');
      } else {
        await HrisApi.instance.createRequest(widget.type, payload);
        if (!mounted) return;
        await showToast(context,
            '${widget.title} has been created. Open it and tap “Send for Approval” when ready.',
            isSuccess: true, title: 'Record Created');
      }
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
      appBar: AppBar(
          title: Text(_isEditing
              ? 'Edit ${widget.initialNo ?? widget.title}'
              : 'Create ${widget.title}')),
      body: _loadingRecord
          ? Center(
              child: CircularProgressIndicator(color: AppColors.brandRed))
          : SafeArea(
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
                      : Text(_isEditing ? 'Save Changes' : 'Create',
                          style: const TextStyle(
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
    // ObjectKey ties the widget subtree to the _CallRow instance — not the
    // index — so adding/removing rows can't scramble which controller a
    // TextField is bound to.
    return Container(
      key: ObjectKey(row),
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
