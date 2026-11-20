import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hris_mobile/data/app_session.dart';
import 'package:hris_mobile/data/email_action_link.dart';
import 'package:hris_mobile/screens/approvals_center_screen.dart';

// What the app does after an Approve / Disapprove email link opens it, against
// a fake server. The Decided lists hold records that share a number across
// types (CA#9, OT#9, MAD#9) so a wrong match would show the wrong employee.

Map<String, dynamic> task(String type, int id, String app, String no,
        String employee, String status) =>
    {
      'type': type,
      'id': id,
      'app': app,
      'no': no,
      'employee': employee,
      'status': status,
      'category': app,
      'detail': '$app • November 20, 2026',
      'date_applied': 'November 20, 2026',
      'date_sent': 'November 20, 2026 09:44 AM',
      'txn_date': 'November 20, 2026',
      'applied_hours': '8:00',
      'approved_date': 'November 20, 2026',
      'reason': 'Test',
    };

final recordsHistory = [
  task('call-approval', 9, 'CA', '9', 'Cruz, Ana', 'Approved'),
  task('overtime', 9, 'OT', '9', 'Reyes, Ben', 'Approved'),
  task('manual-ad', 9, 'MAD', '9', 'Santos, Carl', 'Approved'),
  task('loa', 24934, 'LOA', 'H24934', 'Canal, Mark', 'Approved'),
  task('call-approval', 7, 'CA', '7', 'Lim, Dana', 'Disapproved'),
  task('overtime', 55, 'OT', '55', 'Tan, Eli', 'Approved'),
  task('manual-ad', 12, 'MAD', '12', 'Uy, Faye', 'Disapproved'),
];
final requestsHistory = [
  task('other', 9, 'COE', '9', 'Go, Gina', 'Approved'),
  task('other', 3, 'COE', '3', 'Ho, Hal', 'Disapproved'),
];

/// Fake server: [decision] is what POST /public/email-action answers.
MockClientHandler fakeServer(int code, Map<String, dynamic> decision,
    {List<String>? calls}) {
  return (req) async {
    calls?.add('${req.method} ${req.url.path}?${req.url.query}');
    final path = req.url.path;
    if (path.endsWith('/public/email-action')) {
      return http.Response(jsonEncode(decision), code,
          headers: {'content-type': 'application/json'});
    }
    if (path.endsWith('/auth/approvals')) {
      final module = req.url.queryParameters['module'];
      final rows = module == 'requests' ? requestsHistory : recordsHistory;
      return http.Response(jsonEncode({'data': rows, 'total': rows.length}), 200,
          headers: {'content-type': 'application/json'});
    }
    return http.Response(jsonEncode({'data': []}), 200,
        headers: {'content-type': 'application/json'});
  };
}

final nav = GlobalKey<NavigatorState>();

// The app's ApiClient is created once (AppSession singleton), so it is built
// inside runWithClient with a client that forwards to each test's server.
MockClientHandler? currentServer;
final forwarding = MockClient((req) => currentServer!(req));

Future<void> runLink(WidgetTester t, MockClientHandler server) async {
  currentServer = server;
  t.view.physicalSize = const Size(1179, 2556); // iPhone-sized
  t.view.devicePixelRatio = 3.0;
  addTearDown(t.view.reset);
  AppSession.instance.api.accessToken = 'signed-in';
  await t.pumpWidget(MaterialApp(
    navigatorKey: nav,
    home: const Scaffold(body: Text('HOME')),
  ));
  EmailActionLinks.attachHome();
  // Don't await: the witness dialog stays open until OK is tapped.
  EmailActionLinks.handle('token', nav);
  for (var i = 0; i < 20; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
  await t.pumpAndSettle();
}

/// The open detail sheet's text (the request the app opened).
String openedDetails(WidgetTester t) => find
    .byType(BottomSheet)
    .evaluate()
    .expand((e) => find
        .descendant(of: find.byWidget(e.widget), matching: find.byType(Text))
        .evaluate())
    .map((e) => (e.widget as Text).data ?? '')
    .join(' | ');

void expectOpened(WidgetTester t, String no, String employee, String status,
    {required String title}) {
  expect(find.byType(ApprovalsCenterScreen), findsOneWidget,
      reason: 'should open the Decided list');
  expect(find.text(title), findsWidgets);
  final details = openedDetails(t);
  // ignore: avoid_print
  print('  opened: $details');
  expect(details, contains(employee), reason: 'opened the wrong request');
  expect(details, contains(no));
  expect(details, contains(status));
  expect(find.text('Request approved'), findsNothing, reason: 'no extra popup');
  expect(find.text('Request disapproved'), findsNothing, reason: 'no extra popup');
}

void main() {
  http.runWithClient(() => AppSession.instance, () => forwarding);

  testWidgets('MAD witness approves: confirmation popup, nothing opens', (t) async {
    final calls = <String>[];
    await runLink(
        t,
        fakeServer(200, {
          'ok': true,
          'message': 'MAD#9 has been approved by witness.',
          'type': 'manual-ad',
          'id': '9',
          'action': 'approve',
          'witness': true,
        }, calls: calls));
    expect(find.text('Approved as witness'), findsOneWidget);
    expect(find.text('MAD#9 has been approved by witness.'), findsOneWidget);
    await t.tap(find.text('OK'));
    await t.pumpAndSettle();
    expect(find.byType(ApprovalsCenterScreen), findsNothing);
    expect(find.text('HOME'), findsOneWidget);
    expect(calls.where((c) => c.contains('/auth/approvals')), isEmpty);
  });

  testWidgets('MAD witness disapproves: confirmation popup', (t) async {
    await runLink(
        t,
        fakeServer(200, {
          'ok': true,
          'message': 'MAD#9 has been disapproved.',
          'type': 'manual-ad',
          'id': '9',
          'action': 'disapprove',
          'witness': true,
        }));
    expect(find.text('Disapproved as witness'), findsOneWidget);
    expect(find.text('MAD#9 has been disapproved.'), findsOneWidget);
  });

  // The server now sends the email's own details; the app must show all of
  // them (same as the email / website result page).
  testWidgets('LOA approved by the head: shows the same details as the email', (t) async {
    await runLink(
        t,
        fakeServer(200, {
          'ok': true,
          'message': 'LOA#24934 has been approved.',
          'type': 'loa',
          'id': '24934',
          'action': 'approve',
          'witness': false,
          'status': 'Approved',
          'details': {
            'heading': 'LOA#24934 - SL Paid',
            'name': 'Mark Anthony Canal',
            'position': 'MIS SUPERVISOR',
            'department': 'MIS SW',
            'applied': 'November 20, 2026 09:44 AM',
            'sent': 'November 20, 2026 09:44 AM',
            'resent': 'November 20, 2026 12:47 PM',
            'isCa': false,
            'isOther': false,
            'rows': [
              {'from': 'November 21, 2026 08:00 AM', 'to': 'November 21, 2026 05:00 PM', 'reason': 'Fever', 'hours': '8:00'}
            ],
            'totalHours': '8:00',
          },
        }));
    final shown = openedDetails(t);
    // ignore: avoid_print
    print('  shown: $shown');
    for (final want in [
      'LOA#24934 - SL Paid', 'Approved', 'REQUESTED BY', 'Mark Anthony Canal', 'MIS SUPERVISOR', 'MIS SW',
      'RECORD DETAILS', 'Date Applied', 'Date Sent', 'Date Resent', 'November 20, 2026 12:47 PM',
      'Date From', 'November 21, 2026 08:00 AM', 'Date To', 'November 21, 2026 05:00 PM',
      'Reason', 'Fever', 'Applied Hours', 'Total Hours', '8:00',
    ]) {
      expect(shown, contains(want), reason: 'missing "$want"');
    }
    expect(find.text('Approved Records'), findsWidgets);
  });

  for (final c in [
    ['loa', '24934', 'H24934', 'Canal, Mark', 'Approved', 'approve'],
    ['call-approval', '9', '9', 'Cruz, Ana', 'Approved', 'approve'],
    ['overtime', '9', '9', 'Reyes, Ben', 'Approved', 'approve'],
    ['manual-ad', '9', '9', 'Santos, Carl', 'Approved', 'approve'],
    ['call-approval', '7', '7', 'Lim, Dana', 'Disapproved', 'disapprove'],
    ['manual-ad', '12', '12', 'Uy, Faye', 'Disapproved', 'disapprove'],
  ]) {
    testWidgets('${c[0]}#${c[1]} ${c[5]}d by the head: opens its details', (t) async {
      await runLink(
          t,
          fakeServer(200, {
            'ok': true,
            'message': 'done',
            'type': c[0],
            'id': c[1],
            'action': c[5],
            'witness': false,
          }));
      expectOpened(t, c[2], c[3], c[4], title: 'Approved Records');
    });
  }

  testWidgets('Other Request disapproved by HR: opens its details', (t) async {
    await runLink(
        t,
        fakeServer(200, {
          'ok': true,
          'message': 'REQUEST#3 has been disapproved.',
          'type': 'other',
          'id': '3',
          'action': 'disapprove',
          'witness': false,
        }));
    expectOpened(t, '3', 'Ho, Hal', 'Disapproved', title: 'Approved Requests');
  });

  testWidgets('Already decided: shows the website message, opens nothing', (t) async {
    await runLink(
        t,
        fakeServer(409, {
          'ok': false,
          'message': 'Record not found or already approved/disapproved',
        }));
    expect(find.text('Record not found or already approved/disapproved'),
        findsOneWidget);
    expect(find.byType(ApprovalsCenterScreen), findsNothing);
  });
}
