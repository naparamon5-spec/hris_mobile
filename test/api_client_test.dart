// When the API client renews the session, and what users see when a call fails.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/data/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: 'API_BASE_URL=https://api.test/api/v1');
  });

  /// A client whose server answers with [first] until a refresh happened,
  /// then with [after]. Records every path it was asked for.
  ({ApiClient client, List<String> calls, int Function() refreshes}) setup(
    http.Response Function() first, {
    http.Response Function()? after,
    bool refreshOk = true,
  }) {
    final calls = <String>[];
    var refreshed = 0;
    final mock = MockClient((req) async {
      calls.add(req.url.path);
      return refreshed > 0 && after != null ? after() : first();
    });
    final client = ApiClient(httpClient: mock)
      ..accessToken = 'old-token'
      ..onUnauthorized = () async {
        refreshed++;
        return refreshOk;
      };
    return (client: client, calls: calls, refreshes: () => refreshed);
  }

  http.Response json(int status, Object body) =>
      http.Response(jsonEncode(body), status,
          headers: {'content-type': 'application/json'});

  test('401 on a signed-in call refreshes once and retries', () async {
    final s = setup(() => json(401, {'message': 'Session expired'}),
        after: () => json(200, {'ok': true}));
    final res = await s.client.get('/auth/payslips');
    expect(res, {'ok': true});
    expect(s.refreshes(), 1);
    expect(s.calls, ['/api/v1/auth/payslips', '/api/v1/auth/payslips']);
  });

  test('a real 403 ("not allowed") is shown, with no refresh', () async {
    final s = setup(() => json(403, {'message': 'Insufficient privileges'}));
    await expectLater(
      s.client.post('/auth/requests/loa/1/approve'),
      throwsA(isA<ApiException>()
          .having((e) => e.statusCode, 'status', 403)
          .having((e) => e.message, 'message', 'Insufficient privileges')),
    );
    expect(s.refreshes(), 0);
    expect(s.calls.length, 1);
  });

  test('a bare 403 from an older server still refreshes', () async {
    final s = setup(() => http.Response('', 403),
        after: () => json(200, {'ok': true}));
    expect(await s.client.get('/auth/profile'), {'ok': true});
    expect(s.refreshes(), 1);
  });

  test('a 401 from /public/* (wrong password) never refreshes', () async {
    final s = setup(
        () => json(401, {'message': 'Invalid Employee ID or password'}));
    await expectLater(
      s.client.post('/public/login', body: {'user_id': 'x'}),
      throwsA(isA<ApiException>().having(
          (e) => e.message, 'message', 'Invalid Employee ID or password')),
    );
    expect(s.refreshes(), 0);
  });

  test('a failed refresh surfaces the original error, without looping',
      () async {
    final s = setup(() => json(401, {'message': 'Session expired'}),
        refreshOk: false);
    await expectLater(s.client.get('/auth/payslips'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 's', 401)));
    expect(s.refreshes(), 1);
    expect(s.calls.length, 1);
  });

  test('network failures show a plain message, never the raw exception',
      () async {
    final noNet = ApiClient(
        httpClient: MockClient((_) async => throw const SocketException('x')));
    await expectLater(
        noNet.get('/auth/payslips'),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'status', 0)
            .having((e) => e.message, 'message',
                startsWith('Cannot reach the server'))));

    final weird = ApiClient(
        httpClient: MockClient(
            (_) async => throw http.ClientException('boom at 10.0.0.5')));
    await expectLater(
        weird.get('/auth/payslips'),
        throwsA(isA<ApiException>().having(
            (e) => e.message, 'message', isNot(contains('10.0.0.5')))));
  });
}
