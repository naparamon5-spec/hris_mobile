import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_config.dart';

/// Thrown for any failed API call. [statusCode] is 0 for network/timeout
/// failures (no HTTP response). [message] is safe to show to the user.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode = 0});

  final String message;
  final int statusCode;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Minimal REST client for the HRIS backend. Handles JSON encoding, the
/// `Authorization: Bearer` header, timeouts, and error mapping so callers get
/// either a decoded body or a thrown [ApiException].
class ApiClient {
  ApiClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;

  /// Access token attached to every request once the user is signed in.
  String? accessToken;

  /// Called once when a request returns 401, to try renewing the access token.
  /// Returns true if a new token was obtained (the request is then retried).
  Future<bool> Function()? onUnauthorized;

  static const Duration _timeout = Duration(seconds: 15);

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      };

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Future<dynamic> get(String path) => _send(() => _http
      .get(_uri(path), headers: _headers)
      .timeout(_timeout));

  Future<dynamic> post(String path, {Object? body}) => _send(() => _http
      .post(_uri(path),
          headers: _headers, body: body == null ? null : jsonEncode(body))
      .timeout(_timeout));

  Future<dynamic> put(String path, {Object? body}) => _send(() => _http
      .put(_uri(path),
          headers: _headers, body: body == null ? null : jsonEncode(body))
      .timeout(_timeout));

  Future<dynamic> delete(String path, {Object? body}) => _send(() => _http
      .delete(_uri(path),
          headers: _headers, body: body == null ? null : jsonEncode(body))
      .timeout(_timeout));

  /// Runs [request], decodes JSON on success, and maps every failure mode to a
  /// user-friendly [ApiException]. On a first 401 it tries [onUnauthorized]
  /// (token refresh) once and retries.
  Future<dynamic> _send(
    Future<http.Response> Function() request, {
    bool allowRetry = true,
  }) async {
    http.Response res;
    try {
      res = await request();
    } on SocketException {
      throw ApiException(
        'Cannot reach the server. Make sure the backend is running and the '
        'API address is correct for this device.',
      );
    } on TimeoutException {
      throw ApiException('The server took too long to respond. Try again.');
    } catch (e) {
      throw ApiException('Network error: $e');
    }

    // Access token likely expired — try a one-time refresh, then retry.
    if (res.statusCode == 401 && allowRetry && onUnauthorized != null) {
      bool refreshed = false;
      try {
        refreshed = await onUnauthorized!();
      } catch (_) {
        refreshed = false;
      }
      if (refreshed) {
        return _send(request, allowRetry: false);
      }
    }

    final body = res.body.isEmpty ? null : _tryDecode(res.body);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body;
    }

    throw ApiException(
      _messageFrom(body) ?? 'Request failed (${res.statusCode}).',
      statusCode: res.statusCode,
    );
  }

  dynamic _tryDecode(String raw) {
    try {
      return jsonDecode(raw);
    } catch (_) {
      return raw;
    }
  }

  /// Pulls a human-readable message out of the backend's error shapes:
  /// `{ message }` or `{ errors: [...] }`.
  String? _messageFrom(dynamic body) {
    if (body is Map) {
      if (body['message'] is String) return body['message'] as String;
      if (body['errors'] is List && (body['errors'] as List).isNotEmpty) {
        return (body['errors'] as List).join('\n');
      }
    }
    return null;
  }
}
