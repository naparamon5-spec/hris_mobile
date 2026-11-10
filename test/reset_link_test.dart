import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/data/reset_link.dart';

void main() {
  ResetLink? parse(String url) => ResetLink.parse(Uri.parse(url));

  test('reads token and tenant from an App / Universal Link', () {
    final link = parse(
      'https://hris-api.ardentnetworks.com.ph/reset-password?token=abc&tenant=ardent',
    );
    expect(link?.token, 'abc');
    expect(link?.tenantId, 'ardent');
  });

  test('accepts a trailing slash and a custom-scheme link', () {
    expect(parse('https://x.test/reset-password/?token=abc')?.token, 'abc');
    expect(parse('anihris://reset-password?token=abc')?.token, 'abc');
  });

  test('treats a missing tenant as null', () {
    expect(parse('https://x.test/reset-password?token=abc')?.tenantId, isNull);
    expect(
      parse('https://x.test/reset-password?token=abc&tenant=')?.tenantId,
      isNull,
    );
  });

  test('ignores other links and links without a token', () {
    expect(parse('https://x.test/reset-password'), isNull);
    expect(parse('https://x.test/reset-password?token='), isNull);
    expect(parse('https://x.test/privacy-policy?token=abc'), isNull);
  });
}
