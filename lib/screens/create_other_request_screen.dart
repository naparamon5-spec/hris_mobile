import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/hris_api.dart';
import '../theme/app_colors.dart';
import '../widgets/ui.dart';

const Color _kFieldBorder = Color(0xFFC3C9D4);
const double _kBorderWidth = 1.6;

/// One selectable Other-Request type (code + label), matching the web dropdown.
class _OtherType {
  const _OtherType(this.code, this.label);
  final String code;
  final String label;
}

const _otherTypes = <_OtherType>[
  _OtherType('ID', 'ID'),
  _OtherType('COE', 'Certificate of Employment'),
  _OtherType('EPP', 'Employee Purchase Program'),
  _OtherType('COL', 'Company Loan'),
  _OtherType('BUP', 'Benefits Upgrade'),
  _OtherType('ITR', 'Income Tax Return (ITR)'),
];

enum _FieldKind { text, multiline, radio, dropdown }

const _months = [
  'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August',
  'September', 'October', 'November', 'December'
];

// Benefit-upgrade options depend on the chosen plan.
const _bupPremium = [
  'Medicine Allowance',
  'Rice Allowance',
  'Grocery Reimbursement',
  'Cash',
];
const _bupElite = [
  'Medicine Allowance',
  'Rice Allowance',
  'Grocery Reimbursement',
  'Cash',
  'Additional 5 days vacation leave valid for 1year only',
  'Enroll 1 dependent HMO (subject for approval of provider)',
  'Education/Training/Certification Reimbursement',
];

/// A field shown for a specific request type.
class _FieldDef {
  const _FieldDef(
    this.key,
    this.label, {
    this.kind = _FieldKind.text,
    this.required = false,
    this.hint,
    this.options,
    this.defaultValue,
    this.keyboard,
  });
  final String key;
  final String label;
  final _FieldKind kind;
  final bool required;
  final String? hint;
  final List<String>? options; // radio options
  final String? defaultValue; // radio default selection
  final TextInputType? keyboard;
}

/// Per-type fields, matching the web forms. Add more types as provided.
const Map<String, List<_FieldDef>> _typeFields = {
  'ID': [
    _FieldDef('reason', 'Reason',
        kind: _FieldKind.multiline,
        hint: 'Please specify i.e. lost, change of name, etc.'),
    _FieldDef('emergency_contact_name', 'Emergency Contact Name',
        required: true),
    _FieldDef('relationship', 'Relationship with Employee', required: true),
    _FieldDef('contact_number', 'Contact Number',
        required: true, keyboard: TextInputType.phone),
    _FieldDef('email', 'Email', keyboard: TextInputType.emailAddress),
    _FieldDef('address', 'Address', required: true, kind: _FieldKind.multiline),
  ],
  'COE': [
    _FieldDef('reason', 'Reason',
        kind: _FieldKind.multiline,
        hint:
            'Please specify i.e. loan application, visa application, credit card application, etc.'),
    _FieldDef('compensation', '',
        kind: _FieldKind.radio,
        options: ['Without Compensation', 'With Compensation'],
        defaultValue: 'Without Compensation'),
  ],
  'EPP': [
    _FieldDef('epp_type', 'EPP Type',
        kind: _FieldKind.radio, required: true, options: ['Cash', 'Charge']),
  ],
  'COL': [
    _FieldDef('reason', 'Reason',
        kind: _FieldKind.multiline,
        hint:
            'Please specify i.e. medical emergency, death of immediate family, or natural disaster etc.'),
    _FieldDef('terms', 'Terms',
        kind: _FieldKind.radio,
        options: ['5 Months', '10 Months'],
        defaultValue: '5 Months'),
    _FieldDef('loan_amount', 'Loan Amount',
        keyboard: TextInputType.number),
  ],
  'BUP': [
    _FieldDef('month', 'Choose Month',
        kind: _FieldKind.dropdown, options: _months, defaultValue: 'January'),
    _FieldDef('plan', '',
        kind: _FieldKind.radio,
        options: ['PREMIUM', 'ELITE'],
        defaultValue: 'PREMIUM'),
    // options are resolved dynamically from the chosen plan.
    _FieldDef('benefit_upgrade', 'Choose your benefit upgrade',
        kind: _FieldKind.radio, required: true, options: []),
  ],
  'ITR': [
    _FieldDef('reason', 'Reason', kind: _FieldKind.multiline),
  ],
};

/// Create Other Request — Request Type + type-specific fields, matching the web
/// layout. NOTE: submitting does NOT write to the database; the backend
/// validates and acknowledges the request only.
class CreateOtherRequestScreen extends StatefulWidget {
  const CreateOtherRequestScreen({super.key});

  @override
  State<CreateOtherRequestScreen> createState() =>
      _CreateOtherRequestScreenState();
}

class _CreateOtherRequestScreenState extends State<CreateOtherRequestScreen> {
  _OtherType _type = _otherTypes.first;
  final Map<String, TextEditingController> _fieldCtrls = {};
  final Map<String, String> _radios = {};
  bool _submitting = false;
  String? _active;

  List<_FieldDef> get _fields => _typeFields[_type.code] ?? const [];

  TextEditingController _ctrl(String key) =>
      _fieldCtrls.putIfAbsent(key, () => TextEditingController());

  String? _radioValue(_FieldDef f) => _radios[f.key] ?? f.defaultValue;

  // Info banner only when there are starred text fields (matches the web).
  bool get _hasRequired =>
      _fields.any((f) => f.required && f.kind != _FieldKind.radio);

  @override
  void dispose() {
    for (final c in _fieldCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickType() async {
    setState(() => _active = 'type');
    final picked = await showPremiumBottomSheet<_OtherType>(
      context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text('Select Request Type',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            for (final t in _otherTypes) ...[
              _typeOption(ctx, t),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
    if (picked != null && mounted) setState(() => _type = picked);
    if (mounted) setState(() => _active = null);
  }

  Widget _typeOption(BuildContext ctx, _OtherType t) {
    final selected = t.code == _type.code;
    return Material(
      color: selected ? AppColors.dangerSoft : AppColors.fieldFill,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.pop(ctx, t),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.brandRed : AppColors.line,
              width: selected ? 1.6 : 1.3,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: selected ? AppColors.brandRed : AppColors.card,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.line),
                ),
                child: Text(t.code,
                    style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        color: selected ? Colors.white : AppColors.inkSoft)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(t.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: selected ? AppColors.brandRed : AppColors.ink,
                    )),
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

  Future<void> _submit() async {
    if (_submitting) return;
    for (final f in _fields) {
      if (!f.required) continue;
      final empty = f.kind == _FieldKind.radio
          ? _radioValue(f) == null
          : _ctrl(f.key).text.trim().isEmpty;
      if (empty) {
        showToast(context, 'Please provide "${f.label}".',
            isSuccess: false, title: 'Required Field');
        return;
      }
    }

    setState(() => _submitting = true);
    showLoadingOverlay(context);
    try {
      final payload = <String, dynamic>{'request_type': _type.code};
      for (final f in _fields) {
        payload[f.key] =
            f.kind == _FieldKind.radio ? _radioValue(f) : _ctrl(f.key).text.trim();
      }
      await HrisApi.instance.createRequest('other', payload);
      if (!mounted) return;
      hideLoadingOverlay(context);
      await showToast(context, 'Your ${_type.label} request has been submitted.',
          isSuccess: true, title: 'Request Submitted');
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
      appBar: AppBar(title: const Text('Create Other Request')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          children: [
            _label('Request Type'),
            const SizedBox(height: 7),
            GestureDetector(
              onTap: _pickType,
              child: Container(
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.fieldFill,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color:
                        _active == 'type' ? AppColors.brandRed : _kFieldBorder,
                    width: _kBorderWidth,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Text(_type.code,
                          style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              color: AppColors.inkSoft)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(_type.label,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink)),
                    ),
                    const Icon(Icons.keyboard_arrow_down_rounded,
                        size: 22, color: AppColors.inkSoft),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_hasRequired) ...[
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.infoSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Please fill all required fields (*) before submitting the application.',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.info),
                ),
              ),
              const SizedBox(height: 16),
            ],
            ..._fields.map(_buildField),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
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
                  child: const Text('Create'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Options for a radio field — dynamic for the benefit upgrade (plan-based).
  List<String> _optionsFor(_FieldDef f) {
    if (f.key == 'benefit_upgrade') {
      final plan = _radios['plan'] ?? 'PREMIUM';
      return plan == 'ELITE' ? _bupElite : _bupPremium;
    }
    return f.options ?? const [];
  }

  Widget _buildField(_FieldDef f) {
    if (f.kind == _FieldKind.radio) return _radioField(f);
    if (f.kind == _FieldKind.dropdown) return _dropdownField(f);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel(f),
          const SizedBox(height: 7),
          TextField(
            controller: _ctrl(f.key),
            keyboardType: f.keyboard,
            minLines: f.kind == _FieldKind.multiline ? 4 : 1,
            maxLines: f.kind == _FieldKind.multiline ? 6 : 1,
            textCapitalization: f.kind == _FieldKind.multiline
                ? TextCapitalization.sentences
                : TextCapitalization.words,
            decoration: InputDecoration(
              // Multiline (Reason) shows the hint as a caption below, like the
              // web; single-line fields use it as a placeholder.
              hintText: f.kind == _FieldKind.multiline ? null : f.hint,
              filled: true,
              fillColor: AppColors.fieldFill,
              enabledBorder: _border(_kFieldBorder, _kBorderWidth),
              focusedBorder: _border(AppColors.brandRed, 1.8),
            ),
          ),
          if (f.hint != null && f.kind == _FieldKind.multiline)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 2),
              child: Text(f.hint!,
                  style: const TextStyle(
                      fontSize: 11.5, color: AppColors.inkFaint)),
            ),
        ],
      ),
    );
  }

  Widget _radioField(_FieldDef f) {
    final value = _radioValue(f);
    final options = _optionsFor(f);
    // Two-column layout (matches the web); long labels wrap within their cell.
    final rows = <Widget>[];
    for (var i = 0; i < options.length; i += 2) {
      final left = options[i];
      final right = i + 1 < options.length ? options[i + 1] : null;
      rows.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _radioOption(f.key, left, value == left)),
          const SizedBox(width: 12),
          Expanded(
            child: right == null
                ? const SizedBox()
                : _radioOption(f.key, right, value == right),
          ),
        ],
      ));
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (f.label.isNotEmpty) ...[
            _fieldLabel(f),
            const SizedBox(height: 6),
          ],
          ...rows,
        ],
      ),
    );
  }

  Widget _radioOption(String key, String opt, bool selected) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => setState(() {
        _radios[key] = opt;
        // Changing the plan resets the benefit selection (options differ).
        if (key == 'plan') _radios.remove('benefit_upgrade');
      }),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? AppColors.brandRed : AppColors.inkFaint,
              size: 22,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Text(opt,
                    style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdownField(_FieldDef f) {
    final value = _radioValue(f);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel(f),
          const SizedBox(height: 7),
          Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.fieldFill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _kFieldBorder, width: _kBorderWidth),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: AppColors.inkSoft),
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink),
                dropdownColor: AppColors.card,
                items: (f.options ?? [])
                    .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _radios[f.key] = v ?? value ?? ''),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(_FieldDef f) => Row(
        children: [
          Text(f.label,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.ink)),
          if (f.required)
            Text(' *',
                style: TextStyle(
                    color: AppColors.brandRed,
                    fontWeight: FontWeight.w900,
                    fontSize: 14)),
        ],
      );

  Widget _label(String t) => Text(t,
      style: const TextStyle(
          fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.ink));

  static OutlineInputBorder _border(Color color, double width) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );
}
