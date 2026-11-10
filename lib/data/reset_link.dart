/// A password-reset link from the email, in either form it can arrive as:
///   - App / Universal Link: https://hris-api.ardentnetworks.com.ph/reset-password?token=x&tenant=y
///   - Custom scheme:        anihris://reset-password?token=x&tenant=y
class ResetLink {
  const ResetLink({required this.token, this.tenantId});

  final String token;
  final String? tenantId;

  /// Returns null when [uri] is not a usable reset link.
  static ResetLink? parse(Uri uri) {
    final segments = uri.pathSegments.where((s) => s.isNotEmpty);
    final isReset = uri.host == 'reset-password' ||
        (segments.isNotEmpty && segments.last == 'reset-password');
    final token = uri.queryParameters['token'];
    if (!isReset || token == null || token.isEmpty) return null;
    final tenantId = uri.queryParameters['tenant'];
    return ResetLink(
      token: token,
      tenantId: (tenantId == null || tenantId.isEmpty) ? null : tenantId,
    );
  }
}
