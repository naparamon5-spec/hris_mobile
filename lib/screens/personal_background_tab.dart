import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/hris_api.dart';
import '../theme/app_colors.dart';
import '../widgets/ui.dart';

// -----------------------------------------------------------------------------
// MODELS (local / in-memory demo data)
// -----------------------------------------------------------------------------
class FamilyMember {
  FamilyMember(this.firstName, this.middleName, this.lastName, this.relationship,
      this.birthdate);
  final String firstName, middleName, lastName, relationship, birthdate;
  String get fullName =>
      [firstName, middleName, lastName].where((s) => s.isNotEmpty).join(' ');
}

class Education {
  Education(this.school, this.attainment, this.yearGraduated);
  final String school, attainment, yearGraduated;
}

class PrevEmployment {
  PrevEmployment(this.company, this.address1, this.address2, this.address3,
      this.position, this.dateFrom, this.dateTo);
  final String company, address1, address2, address3, position, dateFrom, dateTo;
}

// -----------------------------------------------------------------------------
// PERSONAL BACKGROUND TAB
// -----------------------------------------------------------------------------
class PersonalBackgroundTab extends StatefulWidget {
  const PersonalBackgroundTab({super.key});

  @override
  State<PersonalBackgroundTab> createState() => _PersonalBackgroundTabState();
}

class _PersonalBackgroundTabState extends State<PersonalBackgroundTab> {
  Map<String, String> _info = {};

  final List<FamilyMember> _family = [];
  final List<Education> _education = [];
  final List<PrevEmployment> _employment = [];

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final bg = await HrisApi.instance.profileBackground();
      if (!mounted) return;
      setState(() {
        _info = bg.personalInfo;
        _family
          ..clear()
          ..addAll(bg.family.map((f) => FamilyMember(
                f['first_name'] ?? '',
                f['middle_name'] ?? '',
                f['last_name'] ?? '',
                f['relationship'] ?? '',
                f['birthdate'] ?? '',
              )));
        _education
          ..clear()
          ..addAll(bg.education.map((e) => Education(
                e['school'] ?? '',
                e['attainment'] ?? '',
                e['year_graduated'] ?? '',
              )));
        _employment
          ..clear()
          ..addAll(bg.previousEmployment.map((p) => PrevEmployment(
                p['company'] ?? '',
                p['address1'] ?? '',
                p['address2'] ?? '',
                p['address3'] ?? '',
                p['position'] ?? '',
                p['date_from'] ?? '',
                p['date_to'] ?? '',
              )));
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(
          child: CircularProgressIndicator(color: AppColors.brandRed));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 48, color: AppColors.inkFaint),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.inkSoft)),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // ---- Personal Information (editable) ----
        SoftCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Personal Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _editPersonalInfo,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.brandRed,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (int i = 0; i < _info.length; i++)
                _row(
                  _info.keys.elementAt(i),
                  _info.values.elementAt(i),
                  isLast: i == _info.length - 1,
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ---- Family Background ----
        _SectionWithAdd(
          title: 'Family Background',
          onAdd: _addFamily,
          isEmpty: _family.isEmpty,
          children: [
            for (int i = 0; i < _family.length; i++)
              _recordTile(
                icon: Icons.family_restroom_rounded,
                title: _family[i].fullName,
                subtitle:
                    '${_family[i].relationship}${_family[i].birthdate.isNotEmpty ? ' • ${_family[i].birthdate}' : ''}',
                onDelete: () => setState(() => _family.removeAt(i)),
              ),
          ],
        ),
        const SizedBox(height: 14),

        // ---- Educational Background ----
        _SectionWithAdd(
          title: 'Educational Background',
          onAdd: _addEducation,
          isEmpty: _education.isEmpty,
          children: [
            for (int i = 0; i < _education.length; i++)
              _recordTile(
                icon: Icons.school_rounded,
                title: _education[i].school,
                subtitle:
                    '${_education[i].attainment} • ${_education[i].yearGraduated}',
                onDelete: () => setState(() => _education.removeAt(i)),
              ),
          ],
        ),
        const SizedBox(height: 14),

        // ---- Previous Employer ----
        _SectionWithAdd(
          title: 'Previous Employer',
          onAdd: _addEmployment,
          isEmpty: _employment.isEmpty,
          children: [
            for (int i = 0; i < _employment.length; i++)
              _recordTile(
                icon: Icons.work_outline_rounded,
                title: _employment[i].company,
                subtitle:
                    '${_employment[i].position} • ${_employment[i].dateFrom} – ${_employment[i].dateTo}',
                onDelete: () => setState(() => _employment.removeAt(i)),
              ),
          ],
        ),
      ],
    );
  }

  // ---- Actions ----
  Future<void> _editPersonalInfo() async {
    final result = await showPremiumBottomSheet<Map<String, String>>(
      context,
      isScrollControlled: true,
      builder: (_) => _PersonalInfoEditSheet(initial: Map.of(_info)),
    );
    if (result != null) setState(() => _info.addAll(result));
  }

  Future<void> _addFamily() async {
    final r = await _showFormSheet<FamilyMember>(
      title: 'Add Family Background',
      builder: (ctx) => _FamilyForm(),
    );
    if (r != null) setState(() => _family.add(r));
  }

  Future<void> _addEducation() async {
    final r = await _showFormSheet<Education>(
      title: 'Add Educational Attainment',
      builder: (ctx) => _EducationForm(),
    );
    if (r != null) setState(() => _education.add(r));
  }

  Future<void> _addEmployment() async {
    final r = await _showFormSheet<PrevEmployment>(
      title: 'Add Previous Employment',
      builder: (ctx) => _EmploymentForm(),
    );
    if (r != null) setState(() => _employment.add(r));
  }

  Future<T?> _showFormSheet<T>({
    required String title,
    required Widget Function(BuildContext) builder,
  }) {
    return showPremiumBottomSheet<T>(
      context,
      isScrollControlled: true,
      builder: (ctx) => _SheetScaffold(title: title, child: builder(ctx)),
    );
  }

  // ---- Row helpers ----
  Widget _row(String label, String value, {bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 130,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.inkSoft,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, thickness: 0.8),
      ],
    );
  }

  Widget _recordTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onDelete,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.fieldFill,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            IconBadge(icon: icon, color: AppColors.brandRed, size: 40, iconSize: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.inkSoft,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.close_rounded,
                  color: AppColors.inkFaint, size: 18),
              splashRadius: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SECTION WITH "ADD" HEADER
// -----------------------------------------------------------------------------
class _SectionWithAdd extends StatelessWidget {
  const _SectionWithAdd({
    required this.title,
    required this.onAdd,
    required this.isEmpty,
    required this.children,
  });

  final String title;
  final VoidCallback onAdd;
  final bool isEmpty;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onAdd,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          if (isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Text(
                  'No data found',
                  style: TextStyle(color: AppColors.inkFaint, fontSize: 13),
                ),
              ),
            )
          else
            ...children,
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SHEET SCAFFOLD (title + scrollable body + Add Row / Close footer)
// -----------------------------------------------------------------------------
class _SheetScaffold extends StatelessWidget {
  const _SheetScaffold({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SHARED FORM FIELDS
// -----------------------------------------------------------------------------
class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.controller,
    this.required = false,
    this.keyboardType,
    this.enabled = true,
  });

  final String label;
  final TextEditingController controller;
  final bool required;
  final TextInputType? keyboardType;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label, required),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            enabled: enabled,
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: AppColors.fieldFill,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.line),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.brandRed, width: 1.6),
              ),
              suffixIcon: enabled
                  ? null
                  : const Icon(Icons.lock_outline_rounded,
                      size: 16, color: AppColors.inkFaint),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _label(String text, bool required) {
  return RichText(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: AppColors.ink,
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
      ),
      children: required
          ? [
              TextSpan(
                  text: ' *', style: TextStyle(color: AppColors.brandRed))
            ]
          : null,
    ),
  );
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.hint,
    required this.onChanged,
    this.required = false,
  });

  final String label;
  final String? value;
  final List<String> items;
  final String hint;
  final ValueChanged<String?> onChanged;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label, required),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: value,
            isExpanded: true,
            decoration: const InputDecoration(isDense: true),
            hint: Text(hint,
                style: const TextStyle(color: AppColors.inkFaint, fontSize: 14)),
            items: items
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    this.required = false,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label, required),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: onTap,
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.fieldFill,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value.isEmpty ? 'mm/dd/yyyy' : value,
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            value.isEmpty ? AppColors.inkFaint : AppColors.ink,
                      ),
                    ),
                  ),
                  const Icon(Icons.calendar_today_rounded,
                      size: 17, color: AppColors.inkSoft),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Green "Add Row" + grey "Close" footer for the add sheets.
class _AddRowFooter extends StatelessWidget {
  const _AddRowFooter({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Row',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }
}

String _fmtDate(DateTime d) {
  const m = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${m[d.month - 1]} ${d.day}, ${d.year}';
}

Future<DateTime?> _pickDate(BuildContext context) {
  return showDatePicker(
    context: context,
    initialDate: DateTime(1995),
    firstDate: DateTime(1950),
    lastDate: DateTime(2035),
    builder: (context, child) => Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.light(
          primary: AppColors.brandRed,
          onPrimary: Colors.white,
          surface: Colors.white,
          onSurface: AppColors.ink,
        ),
      ),
      child: child!,
    ),
  );
}

// -----------------------------------------------------------------------------
// FAMILY FORM
// -----------------------------------------------------------------------------
class _FamilyForm extends StatefulWidget {
  @override
  State<_FamilyForm> createState() => _FamilyFormState();
}

class _FamilyFormState extends State<_FamilyForm> {
  final _first = TextEditingController();
  final _middle = TextEditingController();
  final _last = TextEditingController();
  String? _relationship;
  String _birthdate = '';

  static const _relationships = [
    'Father', 'Mother', 'Spouse', 'Child', 'Sibling', 'Guardian', 'Other',
  ];

  @override
  void dispose() {
    _first.dispose();
    _middle.dispose();
    _last.dispose();
    super.dispose();
  }

  void _submit() {
    if (_first.text.trim().isEmpty ||
        _last.text.trim().isEmpty ||
        _relationship == null) {
      showToast(context, 'Please fill in the required fields');
      return;
    }
    Navigator.pop(
      context,
      FamilyMember(_first.text.trim(), _middle.text.trim(), _last.text.trim(),
          _relationship!, _birthdate),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _LabeledField(label: 'Firstname', controller: _first, required: true),
        _LabeledField(label: 'Middlename', controller: _middle),
        _LabeledField(label: 'Lastname', controller: _last, required: true),
        _DropdownField(
          label: 'Relationship',
          required: true,
          hint: 'Select Family Relationship',
          value: _relationship,
          items: _relationships,
          onChanged: (v) => setState(() => _relationship = v),
        ),
        _DateField(
          label: 'Birthdate',
          value: _birthdate,
          onTap: () async {
            final d = await _pickDate(context);
            if (d != null) setState(() => _birthdate = _fmtDate(d));
          },
        ),
        _AddRowFooter(onAdd: _submit),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// EDUCATION FORM
// -----------------------------------------------------------------------------
class _EducationForm extends StatefulWidget {
  @override
  State<_EducationForm> createState() => _EducationFormState();
}

class _EducationFormState extends State<_EducationForm> {
  final _school = TextEditingController();
  final _year = TextEditingController();
  String? _attainment;

  static const _attainments = [
    'Elementary',
    'Secondary / High School',
    'Senior High School',
    'Vocational',
    'College',
    'Post Graduate',
  ];

  @override
  void dispose() {
    _school.dispose();
    _year.dispose();
    super.dispose();
  }

  void _submit() {
    if (_school.text.trim().isEmpty ||
        _attainment == null ||
        _year.text.trim().isEmpty) {
      showToast(context, 'Please fill in the required fields');
      return;
    }
    Navigator.pop(
      context,
      Education(_school.text.trim(), _attainment!, _year.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _LabeledField(label: 'School', controller: _school, required: true),
        _DropdownField(
          label: 'Attainment',
          required: true,
          hint: 'Select Attainment',
          value: _attainment,
          items: _attainments,
          onChanged: (v) => setState(() => _attainment = v),
        ),
        _LabeledField(
          label: 'Year Graduated',
          controller: _year,
          required: true,
          keyboardType: TextInputType.number,
        ),
        _AddRowFooter(onAdd: _submit),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// EMPLOYMENT FORM
// -----------------------------------------------------------------------------
class _EmploymentForm extends StatefulWidget {
  @override
  State<_EmploymentForm> createState() => _EmploymentFormState();
}

class _EmploymentFormState extends State<_EmploymentForm> {
  final _company = TextEditingController();
  final _addr1 = TextEditingController();
  final _addr2 = TextEditingController();
  final _addr3 = TextEditingController();
  final _position = TextEditingController();
  String _from = '';
  String _to = '';

  @override
  void dispose() {
    _company.dispose();
    _addr1.dispose();
    _addr2.dispose();
    _addr3.dispose();
    _position.dispose();
    super.dispose();
  }

  void _submit() {
    if (_company.text.trim().isEmpty ||
        _addr1.text.trim().isEmpty ||
        _position.text.trim().isEmpty ||
        _from.isEmpty ||
        _to.isEmpty) {
      showToast(context, 'Please fill in the required fields');
      return;
    }
    Navigator.pop(
      context,
      PrevEmployment(
        _company.text.trim(),
        _addr1.text.trim(),
        _addr2.text.trim(),
        _addr3.text.trim(),
        _position.text.trim(),
        _from,
        _to,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _LabeledField(label: 'Company', controller: _company, required: true),
        _LabeledField(label: 'Address 1', controller: _addr1, required: true),
        _LabeledField(label: 'Address 2', controller: _addr2),
        _LabeledField(label: 'Address 3', controller: _addr3),
        _LabeledField(label: 'Position', controller: _position, required: true),
        _DateField(
          label: 'Date From',
          required: true,
          value: _from,
          onTap: () async {
            final d = await _pickDate(context);
            if (d != null) setState(() => _from = _fmtDate(d));
          },
        ),
        _DateField(
          label: 'Date To',
          required: true,
          value: _to,
          onTap: () async {
            final d = await _pickDate(context);
            if (d != null) setState(() => _to = _fmtDate(d));
          },
        ),
        _AddRowFooter(onAdd: _submit),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// PERSONAL INFO EDIT SHEET
// -----------------------------------------------------------------------------
class _PersonalInfoEditSheet extends StatefulWidget {
  const _PersonalInfoEditSheet({required this.initial});
  final Map<String, String> initial;

  @override
  State<_PersonalInfoEditSheet> createState() => _PersonalInfoEditSheetState();
}

class _PersonalInfoEditSheetState extends State<_PersonalInfoEditSheet> {
  // Fields sourced from the HR master record — shown but not editable here.
  static const _readOnlyKeys = {'Full Name', 'Telephone'};

  late final Map<String, TextEditingController> _controllers = {
    for (final e in widget.initial.entries) e.key: TextEditingController(text: e.value),
  };

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    Navigator.pop(
      context,
      {for (final e in _controllers.entries) e.key: e.value.text.trim()},
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: 'Edit Personal Information',
      child: Column(
        children: [
          for (final key in _controllers.keys)
            _LabeledField(
              label: key,
              controller: _controllers[key]!,
              // HR-master fields shouldn't be edited from the app.
              enabled: !_readOnlyKeys.contains(key),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandRed,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('Save Changes',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
