import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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

  /// Backend base URL from a compile-time --dart-define (optional; overrides
  /// even the .env when set), e.g.
  ///   flutter build --dart-define=API_BASE_URL=https://.../api/v1
  static const String _defineBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  /// Backend base URL from the bundled `.env` (API_BASE_URL). Read at runtime
  /// after dotenv.load() in main(); empty if the file/key is absent.
  static String get _dotenvBaseUrl => dotenv.maybeGet('API_BASE_URL') ?? '';

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

  /// Base URL including the API version prefix. Resolution order:
  ///   1. --dart-define=API_BASE_URL (compile-time override)
  ///   2. API_BASE_URL from the bundled .env
  ///   3. the local per-platform dev host (no config = local dev)
  static String get baseUrl {
    if (_defineBaseUrl.isNotEmpty) return _defineBaseUrl;
    if (_dotenvBaseUrl.isNotEmpty) return _dotenvBaseUrl;
    return 'http://$_host:$_port/api/v1';
  }
}
