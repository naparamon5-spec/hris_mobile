import 'package:flutter/services.dart';

/// Time since the phone booted (milliseconds, including sleep), from the
/// native side. The user can't change it the way they can change the wall
/// clock. Null if unavailable (tests, platforms without the channel).
class Uptime {
  Uptime._();
  static const _channel = MethodChannel('com.ardentnetworks.hris/clock');

  static Future<int?> elapsedMs() async {
    try {
      return await _channel.invokeMethod<int>('elapsedRealtime');
    } catch (_) {
      return null;
    }
  }

  /// How long the app was away, given when it left by the wall clock [wall]
  /// and by the uptime clock [elapsed]. Prefers the uptime clock; a phone that
  /// rebooted since (uptime went backwards) counts as away for good. With only
  /// the wall clock, a clock set back counts as away for good too.
  static Future<Duration> awaySince(DateTime wall, int? elapsed) async {
    final now = await elapsedMs();
    if (elapsed != null && now != null) {
      if (now < elapsed) return const Duration(days: 365); // rebooted
      return Duration(milliseconds: now - elapsed);
    }
    final d = DateTime.now().difference(wall);
    return d.isNegative ? const Duration(days: 365) : d;
  }
}
