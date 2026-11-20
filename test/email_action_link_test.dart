import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/data/email_action_link.dart';

void main() {
  test('reads the token from an approval email link', () {
    expect(
      EmailActionLinks.tokenFrom(Uri.parse(
          'https://hris-api.ardentnetworks.com.ph/email-action?token=abc.def')),
      'abc.def',
    );
    expect(EmailActionLinks.tokenFrom(Uri.parse('anihris://email-action?token=t1')), 't1');
  });

  test('ignores other links', () {
    expect(
      EmailActionLinks.tokenFrom(Uri.parse(
          'https://hris-api.ardentnetworks.com.ph/reset-password?token=abc')),
      isNull,
    );
    expect(
      EmailActionLinks.tokenFrom(
          Uri.parse('https://hris-api.ardentnetworks.com.ph/email-action')),
      isNull,
    );
  });
}
