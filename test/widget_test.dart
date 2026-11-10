// Start-up smoke test: a fresh install with no saved session plays the splash
// and lands on the company picker, without a device or a backend.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/main.dart';
import 'package:hris_mobile/screens/company_select_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  late Directory tmp;

  setUpAll(() {
    dotenv.testLoad(fileInput: 'API_BASE_URL=https://api.test/api/v1');
    tmp = Directory.systemTemp.createTempSync('hris_test');
  });

  tearDownAll(() => tmp.deleteSync(recursive: true));

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'ANI HRIS',
      packageName: 'com.ardentnetworks.hris',
      version: '1.3.49',
      buildNumber: '54',
      buildSignature: '',
    );
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    // path_provider (tenant cache) → a temp folder; any other plugin → no-op.
    messenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (_) async => tmp.path);
    // Deep links (password-reset emails): no link waiting at launch.
    messenger.setMockStreamHandler(
        const EventChannel('com.llfbandit.app_links/events'),
        MockStreamHandler.inline(onListen: (_, _) {}));
    messenger.setMockMethodCallHandler(
        const MethodChannel('com.llfbandit.app_links/messages'),
        (_) async => null);
  });

  testWidgets('fresh launch goes from the splash to the company picker',
      (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const HrisApp());
    expect(find.byType(MaterialApp), findsOneWidget);

    // Splash animation (1.4 s) + restore + version check. pumpAndSettle can't
    // be used: the splash and picker have looping animations.
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.byType(CompanySelectScreen), findsOneWidget);
  });
}
