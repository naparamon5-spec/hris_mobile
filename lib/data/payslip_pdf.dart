import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'app_session.dart';
import 'hris_api.dart';
import 'mock_data.dart';

const _red = PdfColor.fromInt(0xFFE43834);
const _ink = PdfColor.fromInt(0xFF1A1A1A);
const _soft = PdfColor.fromInt(0xFF6B7280);
const _line = PdfColor.fromInt(0xFFE5E7EB);

/// Employee details shown on the payslip header (from the profile).
class _Emp {
  _Emp({
    this.company = '',
    this.id = '',
    this.name = '',
    this.department = '',
    this.sss = '',
    this.tin = '',
    this.logo,
  });
  final String company, id, name, department, sss, tin;
  final pw.ImageProvider? logo;
}

/// Loads the employee details + company logo once (best-effort) so the PDF
/// matches the web payslip.
Future<_Emp> _loadEmp() async {
  final s = AppSession.instance;
  String company = s.company ?? s.tenant?.name ?? '';
  String id = s.userId ?? '';
  String name = s.userName ?? '';
  String department = s.position ?? '';
  String sss = '';
  String tin = '';

  try {
    final p = await HrisApi.instance.getProfile();
    if (p.employeeId.isNotEmpty) id = p.employeeId;
    if (p.name.isNotEmpty) name = p.name;
    if (p.department.isNotEmpty) department = p.department;
    sss = p.background.sss ?? '';
    tin = p.background.tin ?? '';
  } catch (_) {}

  pw.ImageProvider? logo;
  final tid = s.tenant?.id;
  if (tid != null) {
    try {
      final bytes = await rootBundle.load('assets/logos/$tid.png');
      logo = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {}
  }

  return _Emp(
    company: company,
    id: id,
    name: name,
    department: department,
    sss: sss,
    tin: tin,
    logo: logo,
  );
}

/// Builds a single-payslip PDF laid out like the HRIS web payslip.
Future<Uint8List> buildPayslipPdf(Payslip slip) => buildPayslipsPdf([slip]);

/// Builds a PDF with one payslip per page (used by bulk download).
Future<Uint8List> buildPayslipsPdf(List<Payslip> slips) async {
  final emp = await _loadEmp();
  final doc = pw.Document();
  for (final slip in slips) {
    doc.addPage(_payslipPage(slip, emp));
  }
  return doc.save();
}

// A label above its value (used in the employee band).
pw.Widget _field(String label, String value) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label,
            style: pw.TextStyle(
                fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: _ink)),
        pw.SizedBox(height: 2),
        pw.Text(value.isEmpty ? '—' : value,
            style: const pw.TextStyle(fontSize: 9, color: _ink)),
      ],
    );

// One "label ........ amount" line. Negative amounts render in red (like web).
pw.Widget _amountRow(String label, String amount, {bool bold = false}) {
  final negative = amount.contains('-');
  final color = negative ? _red : _ink;
  final weight = bold ? pw.FontWeight.bold : pw.FontWeight.normal;
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 4),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Expanded(
          child: pw.Text(label,
              style: pw.TextStyle(fontSize: 9.5, color: color, fontWeight: weight)),
        ),
        pw.Text(amount,
            style: pw.TextStyle(fontSize: 9.5, color: color, fontWeight: weight)),
      ],
    ),
  );
}

pw.Widget _sectionTitle(String t) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Text(t,
          style: pw.TextStyle(
              fontSize: 11, fontWeight: pw.FontWeight.bold, color: _ink)),
    );

pw.Page _payslipPage(Payslip slip, _Emp emp) {
  return pw.Page(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 28),
    build: (_) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // ---- Header: logo (left) + Pay Period (right) ----
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Expanded(
              child: emp.logo != null
                  ? pw.SizedBox(
                      height: 34,
                      child: pw.Align(
                        alignment: pw.Alignment.centerLeft,
                        child: pw.Image(emp.logo!, height: 34),
                      ),
                    )
                  : pw.Text(emp.company,
                      style: pw.TextStyle(
                          fontSize: 14, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Pay Period',
                    style: pw.TextStyle(
                        fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 2),
                pw.Text(slip.period,
                    style: const pw.TextStyle(fontSize: 9.5, color: _soft)),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Divider(color: _line, height: 1),
        pw.SizedBox(height: 10),

        // ---- Employee band: two groups across the width ----
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(child: _field('Employee ID:', emp.id)),
            pw.Expanded(flex: 2, child: _field('Employee:', emp.name)),
            pw.Expanded(flex: 2, child: _field('Department:', emp.department)),
            pw.Expanded(child: _field('SSS No.:', emp.sss)),
            pw.Expanded(child: _field('Tin No.:', emp.tin)),
          ],
        ),
        pw.SizedBox(height: 14),

        // ---- Net Pay (right-aligned) ----
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('Net Pay',
                  style: pw.TextStyle(
                      fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 2),
              pw.Text(slip.net,
                  style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: _red)),
            ],
          ),
        ),
        pw.SizedBox(height: 10),

        // ---- Two columns: Earnings | Deductions ----
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Earnings
            pw.Expanded(
              child: pw.Padding(
                padding: const pw.EdgeInsets.only(right: 24),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Earnings'),
                    for (final e in slip.earnings) _amountRow(e.label, e.amount),
                    pw.Divider(color: _line, height: 12),
                    if (slip.gross != null)
                      _amountRow('Total Earnings', slip.gross!, bold: true),
                  ],
                ),
              ),
            ),
            // Deductions
            pw.Expanded(
              child: pw.Padding(
                padding: const pw.EdgeInsets.only(left: 24),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Deductions'),
                    for (final d in slip.deductionItems)
                      _amountRow(d.label, d.amount),
                    pw.Divider(color: _line, height: 12),
                    if (slip.deductions != null)
                      _amountRow('Total Deductions', slip.deductions!,
                          bold: true),
                  ],
                ),
              ),
            ),
          ],
        ),

        pw.SizedBox(height: 20),
        pw.Center(
          child: pw.Text('Date Generated : ${_fmtNow()}',
              style: const pw.TextStyle(fontSize: 8.5, color: _soft)),
        ),
      ],
    ),
  );
}

String _fmtNow() {
  final n = DateTime.now();
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  final h12 = n.hour % 12 == 0 ? 12 : n.hour % 12;
  final ampm = n.hour < 12 ? 'AM' : 'PM';
  final mm = n.minute.toString().padLeft(2, '0');
  return '${months[n.month - 1]} ${n.day}, ${n.year} $h12:$mm $ampm';
}
