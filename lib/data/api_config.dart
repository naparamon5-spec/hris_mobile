import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Where the Flutter app finds the HRIS backend (the `hris-server` Express API).
///
/// The tricky part is that "localhost" means different things per platform:
///   * Android emulator  -> the host machine is reachable at 10.0.2.2
///   * iOS simulator     -> localhost works, it shares the Mac's network
///   * Web / desktop      -> localhost works
///   * Physical device   -> must use the Mac's LAN IP (set [lanHostOverride])
///
/// Change [_port] if you run the server on a different port.
class ApiConfig {
  ApiConfig._();

  /// Flip to `false` to point the app at a local dev server instead of the
  /// deployed backend (useful when developing against `hris-server` on your
  /// Mac). Ships as `true` so release builds always hit production.
  static const bool useProduction = true;

  /// The deployed HRIS backend.
  static const String _productionBaseUrl =
      'https://hris-api.ardentnetworks.com.ph/api/v1';

  static const int _port = 3000;

  /// Set this to your Mac's LAN IP (e.g. '192.168.1.20') when testing on a
  /// real phone on the same Wi-Fi. Leave null for emulators/simulators.
  static const String? lanHostOverride = null;

  /// Host portion of the local backend URL, resolved for the current platform.
  static String get _host {
    if (lanHostOverride != null) return lanHostOverride!;
    if (kIsWeb) return 'localhost';
    if (Platform.isAndroid) return '10.0.2.2';
    return 'localhost';
  }

  /// Base URL including the API version prefix. Production by default; the
  /// local per-platform host when [useProduction] is false.
  static String get baseUrl =>
      useProduction ? _productionBaseUrl : 'http://$_host:$_port/api/v1';
}
