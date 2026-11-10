// The 3-minute background sign-out is measured on the phone's uptime clock,
// so changing the wall clock can't skip it.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/data/uptime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.ardentnetworks.hris/clock');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  int? nowUptime;

  setUp(() {
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (nowUptime == null) throw MissingPluginException();
      return nowUptime;
    });
  });
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('uses uptime even when the wall clock was set back', () async {
    nowUptime = 1000000 + 5 * 60 * 1000; // 5 minutes of uptime later
    // Wall clock says the app left "in the future" (clock set back).
    final wall = DateTime.now().add(const Duration(hours: 1));
    final away = await Uptime.awaySince(wall, 1000000);
    expect(away, const Duration(minutes: 5));
  });

  test('a short absence on the uptime clock stays short', () async {
    nowUptime = 1000000 + 20 * 1000;
    final away = await Uptime.awaySince(
        DateTime.now().subtract(const Duration(hours: 3)), 1000000);
    expect(away, const Duration(seconds: 20));
  });

  test('a reboot since leaving counts as away for good', () async {
    nowUptime = 5000; // uptime restarted
    final away = await Uptime.awaySince(DateTime.now(), 1000000);
    expect(away >= const Duration(minutes: 3), isTrue);
  });

  test('no uptime clock: wall clock, and a clock set back counts as away',
      () async {
    nowUptime = null;
    expect(
        await Uptime.awaySince(
            DateTime.now().subtract(const Duration(minutes: 1)), null),
        lessThan(const Duration(minutes: 2)));
    expect(
        await Uptime.awaySince(
            DateTime.now().add(const Duration(minutes: 10)), null),
        greaterThanOrEqualTo(const Duration(minutes: 3)));
  });
}
