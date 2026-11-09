import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/data/hris_api.dart';
import 'package:hris_mobile/data/mock_data.dart';
import 'package:hris_mobile/data/ph_holidays.dart';

void main() {
  group('sortDeductions', () {
    List<String> sorted(List<String> labels) => sortDeductions([
      for (final l in labels) PayItem(label: l, amount: '0'),
    ]).map((e) => e.label).toList();

    test('matches the website order and keeps ties in server order', () {
      expect(
        sorted([
          'Uniform',
          'WITHHOLDING TAX',
          'SSS PREMIUM',
          'HDMF PREMIUM',
          'MANDATORY PRVIDENT FUND',
          'NHIP PREMIUM',
          'Company Loan',
          'SSS Loan',
          'Canteen',
        ]),
        [
          'Company Loan',
          'SSS Loan',
          'NHIP PREMIUM',
          'MANDATORY PRVIDENT FUND',
          'HDMF PREMIUM',
          'SSS PREMIUM',
          'WITHHOLDING TAX',
          'Uniform',
          'Canteen',
        ],
      );
    });

    test('recognises alternate labels', () {
      expect(deductionRank('PHIC'), 1);
      expect(deductionRank('Phil-Health'), 1);
      expect(deductionRank('Provident Fund'), 2);
      expect(deductionRank('Pag-IBIG'), 3);
      expect(deductionRank('Pag-IBIG Loan'), 0);
      expect(deductionRank('SSS_EE'), 4);
      expect(deductionRank('W/Tax'), 5);
      expect(deductionRank('WTAX'), 5);
      expect(deductionRank('Non-Taxable Adjustment'), 6);
    });

    test('Payslip.fromJson applies it and keeps zero rows', () {
      final slip = Payslip.fromJson({
        'deduction_items': [
          {'label': 'WITHHOLDING TAX', 'amount': 'P 0.00'},
          {'label': 'Company Loan', 'amount': 'P 1,000.00'},
        ],
      });
      expect(
        slip.deductionItems.map((e) => e.label),
        ['Company Loan', 'WITHHOLDING TAX'],
      );
    });
  });

  group('paydayFromCutoff', () {
    DateTime pay(int y, int m, int d) =>
        PayCalendarPeriod.paydayFromCutoff(DateTime.utc(y, m, d));

    test('weekday paydays stay put', () {
      expect(pay(2026, 10, 10), DateTime.utc(2026, 10, 15)); // Thu
      expect(pay(2026, 10, 25), DateTime.utc(2026, 10, 30)); // Fri
    });

    test('Sunday moves back to Friday', () {
      expect(pay(2026, 11, 10), DateTime.utc(2026, 11, 13)); // Sun 15th
      expect(pay(2026, 8, 25), DateTime.utc(2026, 8, 28)); // Sun 30th
    });

    test('Saturday moves back to Friday', () {
      expect(pay(2026, 8, 10), DateTime.utc(2026, 8, 14)); // Sat 15th
      expect(pay(2026, 5, 25), DateTime.utc(2026, 5, 29)); // Sat 30th
    });

    test('February uses its last day, then shifts', () {
      expect(pay(2026, 2, 25), DateTime.utc(2026, 2, 27)); // Sat 28th
      expect(pay(2027, 2, 25), DateTime.utc(2027, 2, 26)); // Sun 28th
    });

    test('a holiday moves to the last working day before it', () {
      expect(pay(2026, 11, 25), DateTime.utc(2026, 11, 27)); // Bonifacio, Mon
      expect(pay(2026, 12, 25), DateTime.utc(2026, 12, 29)); // Rizal, Wed
      expect(pay(2027, 8, 25), DateTime.utc(2027, 8, 27)); // Heroes, Mon
    });

    test('keeps moving back through consecutive days off', () {
      // Good Friday is Mar 30, 2029 and Maundy Thursday is Mar 29.
      expect(pay(2029, 3, 25), DateTime.utc(2029, 3, 28));
    });
  });

  group('isPhilippineHoliday', () {
    test('matches the 2026 and 2027 proclamations', () {
      for (final d in [
        DateTime.utc(2026, 2, 17),
        DateTime.utc(2026, 4, 2),
        DateTime.utc(2026, 4, 3),
        DateTime.utc(2026, 4, 4),
        DateTime.utc(2026, 8, 31),
        DateTime.utc(2026, 11, 2),
        DateTime.utc(2026, 12, 24),
        DateTime.utc(2027, 2, 6),
        DateTime.utc(2027, 3, 25),
        DateTime.utc(2027, 3, 26),
        DateTime.utc(2027, 3, 27),
        DateTime.utc(2027, 8, 30),
      ]) {
        expect(isPhilippineHoliday(d), isTrue, reason: '$d');
      }
    });

    test('leaves working days alone', () {
      for (final d in [
        DateTime.utc(2026, 2, 25), // EDSA is a special working day
        DateTime.utc(2026, 4, 5), // Easter Sunday itself
        DateTime.utc(2026, 8, 24), // Not the last Monday of August
        DateTime.utc(2026, 11, 13),
      ]) {
        expect(isPhilippineHoliday(d), isFalse, reason: '$d');
      }
    });
  });
}
