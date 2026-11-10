import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/widgets/verify_identity.dart';

void main() {
  const channel = MethodChannel('plugins.flutter.io/local_auth');
  const passwordTitle = "We'll verify it's you";
  var authCalls = 0;
  late Object authResult;
  late bool supported;
  late List<String> enrolled;
  Map<dynamic, dynamic>? lastAuthArgs;

  setUp(() {
    authCalls = 0;
    authResult = true;
    supported = true;
    enrolled = <String>['fingerprint'];
    lastAuthArgs = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'isDeviceSupported':
          return supported;
        case 'getAvailableBiometrics':
          return enrolled;
        case 'authenticate':
          authCalls++;
          lastAuthArgs = call.arguments as Map<dynamic, dynamic>?;
          if (authResult is PlatformException) throw authResult;
          return authResult;
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Future<void Function()> pumpGate(
    WidgetTester tester, {
    required bool allowBiometrics,
    required void Function(bool) onResult,
  }) async {
    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (c) {
        ctx = c;
        return const Scaffold();
      }),
    ));
    return () {
      verifyIdentity(ctx, allowBiometrics: allowBiometrics).then(onResult);
    };
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('a verified biometric skips the password', (tester) async {
    bool? result;
    final run = await pumpGate(tester,
        allowBiometrics: true, onResult: (v) => result = v);
    run();
    await settle(tester);
    expect(authCalls, 1);
    expect(result, isTrue);
    expect(find.text(passwordTitle), findsNothing);
  });

  testWidgets('the prompt accepts biometrics only, not the phone PIN',
      (tester) async {
    final run = await pumpGate(tester, allowBiometrics: true, onResult: (_) {});
    run();
    await settle(tester);
    expect(lastAuthArgs?['biometricOnly'], isTrue);
  });

  testWidgets('a phone with only a PIN (no biometrics) asks for the password',
      (tester) async {
    enrolled = <String>[];
    final run = await pumpGate(tester, allowBiometrics: true, onResult: (_) {});
    run();
    await settle(tester);
    expect(authCalls, 0);
    expect(find.text(passwordTitle), findsOneWidget);
  });

  testWidgets('a failed biometric falls back to the password', (tester) async {
    authResult = false;
    final run = await pumpGate(tester, allowBiometrics: true, onResult: (_) {});
    run();
    await settle(tester);
    expect(authCalls, 1);
    expect(find.text(passwordTitle), findsOneWidget);
  });

  testWidgets('a biometric error falls back to the password', (tester) async {
    authResult = PlatformException(code: 'LockedOut');
    final run = await pumpGate(tester, allowBiometrics: true, onResult: (_) {});
    run();
    await settle(tester);
    expect(find.text(passwordTitle), findsOneWidget);
  });

  testWidgets('biometrics off goes straight to the password', (tester) async {
    final run =
        await pumpGate(tester, allowBiometrics: false, onResult: (_) {});
    run();
    await settle(tester);
    expect(authCalls, 0);
    expect(find.text(passwordTitle), findsOneWidget);
  });

  testWidgets('an unsupported device goes to the password', (tester) async {
    supported = false;
    final run = await pumpGate(tester, allowBiometrics: true, onResult: (_) {});
    run();
    await settle(tester);
    expect(authCalls, 0);
    expect(find.text(passwordTitle), findsOneWidget);
  });
}
