import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/data/hris_api.dart';
import 'package:hris_mobile/data/payday_text.dart';

PayCalendarPeriod _period(DateTime from, DateTime to) => PayCalendarPeriod(
  payYear: '${to.year}',
  payPeriod: 'P',
  payDate: PayCalendarPeriod.paydayFromCutoff(to),
  cutoffFrom: from,
  cutoffTo: to,
);

void main() {
  group('PayCalendarPeriod.upcoming', () {
    // Nov 15 2026 is a Sunday → paid Fri Nov 13. Nov 30 (Bonifacio Day,
    // Monday) → paid Fri Nov 27.
    final paid = _period(DateTime.utc(2026, 11, 1), DateTime.utc(2026, 11, 15));

    test('moves to the next payday the day after payday', () {
      final next = PayCalendarPeriod.upcoming(
        DateTime.utc(2026, 11, 14),
        after: paid,
      );
      expect(next.payDate, DateTime.utc(2026, 11, 27));
      expect(next.daysToPayday, 13);
    });

    test('still shows today when today is payday', () {
      final next = PayCalendarPeriod.upcoming(
        DateTime.utc(2026, 11, 27),
        after: paid,
      );
      expect(next.payDate, DateTime.utc(2026, 11, 27));
      expect(next.daysToPayday, 0);
    });

    test('rolls into the next month after an early month-end payday', () {
      final next = PayCalendarPeriod.upcoming(
        DateTime.utc(2026, 11, 28),
        after: paid,
      );
      expect(next.payDate, DateTime.utc(2026, 12, 15));
    });
  });

  group('PaydayText', () {
    final now = DateTime(2026, 11, 10);

    test('corrects an unshifted payday date to the dashboard date', () {
      final (_, body) = PaydayText.apply(
        'payday',
        'Payday reminder',
        'Your payday is on Nov 15, 2026.',
        now: now,
      );
      expect(body, 'Your payday is on Nov 13, 2026.');
    });

    test('handles long month names and month-end paydays', () {
      expect(
        PaydayText.fix('Payday: November 30', now: now),
        'Payday: November 27',
      );
    });

    test('leaves an already-correct date alone', () {
      expect(PaydayText.fix('Payday on Nov 13', now: now), 'Payday on Nov 13');
    });

    test('does not touch payslip notifications', () {
      final (_, body) = PaydayText.apply(
        'payslip',
        'Payslip ready',
        'Your payslip for Nov 1 - Nov 15 is ready.',
        now: now,
      );
      expect(body, 'Your payslip for Nov 1 - Nov 15 is ready.');
    });
  });

  group('dashboard payday flow (PayCalendarNext.resolve)', () {
    // Server stuck on the Nov 16–30 period (paid early on Fri Nov 27, since
    // Nov 30 is Bonifacio Day); pay-periods list only has up to Nov 1–15.
    final server = PayCalendarNext(
      next: _period(DateTime.utc(2026, 11, 16), DateTime.utc(2026, 11, 30)),
    );
    final computed = PayCalendarNext(
      next: _period(DateTime.utc(2026, 11, 1), DateTime.utc(2026, 11, 15)),
    );

    PayCalendarPeriod on(int month, int day) => PayCalendarNext.resolve(
      server: server,
      computed: computed,
      today: DateTime(2026, month, day),
    )!.next;

    test('Nov 26: next payday Nov 27, 1 day', () {
      expect(on(11, 26).payDate, DateTime.utc(2026, 11, 27));
      expect(on(11, 26).daysToPayday, 1);
    });

    test('Nov 27: shows Payday (0 days)', () {
      expect(on(11, 27).payDate, DateTime.utc(2026, 11, 27));
      expect(on(11, 27).daysToPayday, 0);
    });

    test('Nov 28: moves to next payday Dec 15, 17 days', () {
      expect(on(11, 28).payDate, DateTime.utc(2026, 12, 15));
      expect(on(11, 28).daysToPayday, 17);
    });

    test('Dec 15 is Payday, Dec 16 moves to Dec 29 (Rizal Day on Dec 30)', () {
      expect(on(12, 15).daysToPayday, 0);
      expect(on(12, 16).payDate, DateTime.utc(2026, 12, 29));
      expect(on(12, 16).daysToPayday, 13);
    });

    test('Nov 14 (day after early Nov 13 payday): moves to Nov 27', () {
      expect(on(11, 13).payDate, DateTime.utc(2026, 11, 13));
      expect(on(11, 13).daysToPayday, 0);
      expect(on(11, 14).payDate, DateTime.utc(2026, 11, 27));
      expect(on(11, 14).daysToPayday, 13);
    });

    test('keeps the server period details when it matches', () {
      final r = PayCalendarNext.resolve(
        server: server,
        computed: computed,
        today: DateTime(2026, 11, 20),
      )!.next;
      expect(r.payPeriod, 'P');
      expect(r.cutoffTo, DateTime.utc(2026, 11, 30));
      expect(r.daysToPayday, 7);
    });

    test('no calendar configured → null', () {
      expect(PayCalendarNext.resolve(today: DateTime(2026, 11, 28)), isNull);
    });
  });
}
