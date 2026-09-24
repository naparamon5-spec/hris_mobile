import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'app_session.dart';
import 'hris_api.dart';
import 'mock_data.dart';

/// Employee details shown on the payslip header (from the profile).
class _Emp {
  _Emp({this.company = '', this.id = '', this.name = '', this.department = '', this.sss = '', this.tin = ''});
  final String company, id, name, department, sss, tin;
}

/// Loads the employee details once (best-effort) so the PDF header matches the
/// web payslip (Employee ID / Employee / Department / SSS No. / Tin No.).
Future<_Emp> _loadEmp() async {
  final s = AppSession.instance;
  final base = _Emp(
    company: s.company ?? s.tenant?.name ?? '',
    id: s.userId ?? '',
    name: s.userName ?? '',
    department: s.position ?? '',
  );
  try {
    final p = await HrisApi.instance.getProfile();
    return _Emp(
      company: base.company,
      id: p.employeeId.isNotEmpty ? p.employeeId : base.id,
      name: p.name.isNotEmpty ? p.name : base.name,
      department: p.department.isNotEmpty ? p.department : base.department,
      sss: p.background.sss ?? '',
      tin: p.background.tin ?? '',
    );
  } catch (_) {
    return base;
  }
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

pw.Page _payslipPage(Payslip slip, _Emp emp) {
  const red = PdfColor.fromInt(0xFFE43834);
  const ink = PdfColor.fromInt(0xFF1A1A1A);
  const soft = PdfColor.fromInt(0xFF6B7280);
  const line = PdfColor.fromInt(0xFFE5E7EB);

  final company = emp.company;
  final generated = _fmtNow();

  pw.Widget infoRow(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 90,
              child: pw.Text(label,
                  style: pw.TextStyle(fontSize: 9, color: soft)),
            ),
            pw.Expanded(
              child: pw.Text(value,
                  style: pw.TextStyle(
                      fontSize: 9.5,
                      fontWeight: pw.FontWeight.bold,
                      color: ink)),
            ),
          ],
        ),
      );

  pw.Widget amountRow(String label, String amount, {bool bold = false}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 3),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label,
                style: pw.TextStyle(
                    fontSize: 10,
                    color: ink,
                    fontWeight:
                        bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
            pw.Text(amount,
                style: pw.TextStyle(
                    fontSize: 10,
                    color: ink,
                    fontWeight:
                        bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          ],
        ),
      );

  pw.Widget sectionTitle(String t) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 10, bottom: 2),
        child: pw.Text(t,
            style: pw.TextStyle(
                fontSize: 11, fontWeight: pw.FontWeight.bold, color: red)),
      );

  return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // ---- Header ----
          if (company.isNotEmpty)
            pw.Text(company,
                style: pw.TextStyle(
                    fontSize: 15, fontWeight: pw.FontWeight.bold, color: ink)),
          pw.SizedBox(height: 2),
          pw.Text('PAYSLIP',
              style: pw.TextStyle(
                  fontSize: 10,
                  letterSpacing: 2,
                  fontWeight: pw.FontWeight.bold,
                  color: red)),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Pay Period',
                      style: pw.TextStyle(fontSize: 9, color: soft)),
                  pw.Text(slip.period,
                      style: pw.TextStyle(
                          fontSize: 12, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Net Pay',
                      style: pw.TextStyle(fontSize: 9, color: soft)),
                  pw.Text(slip.net,
                      style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: red)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text('Date Generated : $generated',
              style: pw.TextStyle(fontSize: 8.5, color: soft)),
          pw.SizedBox(height: 12),
          pw.Divider(color: line, height: 1),
          pw.SizedBox(height: 10),

          // ---- Employee block (matches the web payslip) ----
          infoRow('Employee ID:', emp.id),
          infoRow('Employee:', emp.name),
          if (emp.department.isNotEmpty) infoRow('Department:', emp.department),
          if (emp.sss.isNotEmpty) infoRow('SSS No.:', emp.sss),
          if (emp.tin.isNotEmpty) infoRow('Tin No.:', emp.tin),
          pw.SizedBox(height: 10),
          pw.Divider(color: line, height: 1),

          // ---- Earnings ----
          sectionTitle('Earnings'),
          for (final e in slip.earnings) amountRow(e.label, e.amount),
          if (slip.gross != null) ...[
            pw.Divider(color: line, height: 10),
            amountRow('Total Earnings', slip.gross!, bold: true),
          ],

          // ---- Deductions ----
          sectionTitle('Deductions'),
          for (final d in slip.deductionItems) amountRow(d.label, d.amount),
          if (slip.deductions != null) ...[
            pw.Divider(color: line, height: 10),
            amountRow('Total Deductions', slip.deductions!, bold: true),
          ],

          pw.SizedBox(height: 16),
          pw.Container(
            width: double.infinity,
            padding:
                const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFFDECEC),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Net Pay',
                    style: pw.TextStyle(
                        fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.Text(slip.net,
                    style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: red)),
              ],
            ),
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
