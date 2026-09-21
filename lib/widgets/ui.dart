import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import 'dart:math' as math;
import '../data/profile_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Global key for managing loading overlay
final GlobalKey<_LoadingOverlayState> loadingOverlayKey =
    GlobalKey<_LoadingOverlayState>();

/// Show full-screen loading overlay with blur effect. Pass [immediate] to skip
/// the show-delay (used when a whole screen must show the blur while it loads).
void showLoadingOverlay(BuildContext context, {bool immediate = false}) {
  loadingOverlayKey.currentState?.show(immediate: immediate);
}

/// Hide full-screen loading overlay
void hideLoadingOverlay(BuildContext context) {
  loadingOverlayKey.currentState?.hide();
}

/// Runs [action] while the global blur loader is shown, hiding it afterwards
/// (even on error). Use for any button-triggered network call so the user
/// always sees loading feedback.
Future<T> runWithLoading<T>(
  BuildContext context,
  Future<T> Function() action,
) async {
  showLoadingOverlay(context);
  try {
    return await action();
  } finally {
    hideLoadingOverlay(context);
  }
}

/// A squared toggle: a rounded-rectangle track (grey off / accent on) with a
/// sliding square thumb and an ON/OFF label. A boxier alternative to the stock
/// Material [Switch]. Disabled when [onChanged] is null.
class AppSwitch extends StatelessWidget {
  const AppSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.accent,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final accent = this.accent ?? AppColors.brandRed;
    final enabled = onChanged != null;
    final label = Text(
      value ? 'ON' : 'OFF',
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.5,
        color: value ? Colors.white : const Color(0xFF9A9DA6),
      ),
    );
    return Semantics(
      toggled: value,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => onChanged!(!value) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          width: 62,
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: value
                ? accent.withValues(alpha: enabled ? 1 : 0.4)
                : const Color(0xFFE4E6EB),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: value
                ? [label, _thumb()]
                : [_thumb(), label],
          ),
        ),
      ),
    );
  }

  // Square thumb with slightly rounded corners.
  Widget _thumb() => Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      );
}

/// A white rounded card with clean subtle border and soft shadow.
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color = AppColors.card,
    this.radius = 16,
    this.border,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color color;
  final double radius;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Ink(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(radius),
            boxShadow: kSoftShadow,
            border: border ?? Border.all(color: AppColors.line, width: 1),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Small rounded icon tile (used in quick actions, list leadings).
class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    required this.icon,
    this.color,
    this.bg,
    this.size = 44,
    this.iconSize = 22,
  });

  final IconData icon;
  final Color? color;
  final Color? bg;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? AppColors.brandRed;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg ?? color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}

/// Pill-shaped status / category chip.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.bg,
    this.icon,
  });

  final String label;
  final Color color;
  final Color? bg;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg ?? color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section header row with title and optional trailing action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
        ),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Row(
              children: [
                Text(
                  actionLabel!,
                  style: TextStyle(
                    color: AppColors.brandRed,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    size: 18, color: AppColors.brandRed),
              ],
            ),
          ),
      ],
    );
  }
}

/// Circular avatar with initials fallback and a soft brand background.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    super.key,
    required this.name,
    this.size = 44,
    this.color,
  });

  final String name;
  final double size;
  final Color? color;

  String get _initials {
    // Drop any "( nickname )" part and keep only real name words, so
    // "Ramon Napa ( Mon )" yields "RN" (first + last name), not "R)".
    final cleaned = name.replaceAll(RegExp(r'\(.*?\)'), ' ');
    final parts = cleaned
        .split(RegExp(r'\s+'))
        .where((p) => RegExp(r'[A-Za-z]').hasMatch(p))
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.brandRed;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.withValues(alpha: 0.9), c.withValues(alpha: 0.65)],
        ),
      ),
      child: Text(
        _initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.36,
        ),
      ),
    );
  }
}

/// The current user's avatar: shows the uploaded profile photo when one is set
/// (via [ProfileState]), otherwise falls back to initials. Rebuilds everywhere
/// the moment a new photo is uploaded.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.size = 44,
    this.color,
  });

  final String name;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ProfileState.instance,
      builder: (context, _) {
        final photo = ProfileState.instance.photo;
        if (photo != null) {
          return ClipOval(
            child: Image.memory(
              photo,
              width: size,
              height: size,
              fit: BoxFit.cover,
              gaplessPlayback: true,
            ),
          );
        }
        return InitialsAvatar(name: name, size: size, color: color);
      },
    );
  }
}

/// Small-caps group label, matching the website sidebar's section headers
/// (e.g. "RECORD / REQUEST", "APPS").
class SmallCapsHeader extends StatelessWidget {
  const SmallCapsHeader(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.3,
          color: AppColors.inkFaint,
        ),
      ),
    );
  }
}

/// A tappable navigation row: coloured icon tile, label, optional red dot, and
/// a chevron. Used by the Requests and Apps hubs to mirror the web menu.
class NavListTile extends StatelessWidget {
  const NavListTile({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.badge = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          IconBadge(icon: icon, color: color, size: 44, iconSize: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
          if (badge)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: AppColors.brandRed,
                shape: BoxShape.circle,
              ),
            ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.inkFaint),
        ],
      ),
    );
  }
}

/// Premium bottom sheet helper - applies MAYA APP styling to all bottom sheets
/// Ensures consistent padding, rounded corners, and typography across the app
Future<T?> showPremiumBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isDismissible = true,
  bool enableDrag = true,
  bool isScrollControlled = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    isScrollControlled: isScrollControlled,
    builder: builder,
  );
}

/// A polished "confirm your password" bottom sheet used to gate sensitive
/// screens (payslip, timesheet) and re-authenticate before actions. Returns the
/// entered password, or null if cancelled/dismissed. Pure UI — the caller is
/// responsible for verifying the password against the backend.
Future<String?> promptPassword(
  BuildContext context, {
  String title = "We'll verify it's you",
  String message =
      'For your privacy, please confirm your password to view this information.',
  String buttonLabel = 'Verify',
  Color? accent,
}) {
  final Color resolvedAccent = accent ?? AppColors.brandRed;
  final controller = TextEditingController();
  var obscure = true;
  return showPremiumBottomSheet<String>(
    context,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 32),
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SecurityIllustration(size: 132, accent: resolvedAccent),
            const SizedBox(height: 28),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.inkSoft, height: 1.5),
            ),
            const SizedBox(height: 28),
            TextField(
              controller: controller,
              autofocus: true,
              obscureText: obscure,
              onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.fieldFill,
                hintText: 'Enter your password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  icon: EyeToggleIcon(obscured: obscure),
                  onPressed: () => setSheet(() => obscure = !obscure),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: resolvedAccent, width: 1.6),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.ink,
                      side: const BorderSide(color: AppColors.line),
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Cancel',
                          maxLines: 1,
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: resolvedAccent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(52),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(buttonLabel,
                          maxLines: 1,
                          softWrap: false,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/// The visual state of a result modal / toast.
enum ResultKind { success, error, warning }

/// Shows a polished result modal (success / error / warning) with a 2D vector
/// illustration, title, message, and button. Slides up as a bottom sheet.
///
/// Back-compatible: existing callers pass [isSuccess]; pass [warning] (or
/// [kind]) for the amber warning state.
/// Returns a Future that completes when the sheet is dismissed, so callers can
/// `await showToast(...)` before navigating away (otherwise a following
/// Navigator.pop would dismiss this sheet instead of the screen).
Future<void> showToast(
  BuildContext context,
  String message, {
  bool isSuccess = true,
  bool warning = false,
  ResultKind? kind,
  String? title,
  Widget? illustration,
}) {
  final resolved = kind ??
      (warning
          ? ResultKind.warning
          : (isSuccess ? ResultKind.success : ResultKind.error));
  const defaults = {
    ResultKind.success: 'Success',
    ResultKind.error: 'Error',
    ResultKind.warning: 'Warning',
  };
  return showPremiumBottomSheet<void>(
    context,
    builder: (ctx) => _ResultModal(
      title: title ?? defaults[resolved]!,
      message: message,
      kind: resolved,
      illustration: illustration,
    ),
  );
}

/// Custom result modal (success/error) with icon, title, message, and button.
/// Appears as a bottom sheet with premium styling.
class _ResultModal extends StatelessWidget {
  const _ResultModal({
    required this.title,
    required this.message,
    required this.kind,
    this.illustration,
  });

  final String title;
  final String message;
  final ResultKind kind;

  /// Optional context-specific artwork (e.g. a fingerprint for biometric
  /// actions). Falls back to the generic [ResultIllustration] for [kind].
  final Widget? illustration;

  Color get _accent => switch (kind) {
        ResultKind.success => AppColors.success,
        ResultKind.error => AppColors.defaultBrand,
        ResultKind.warning => AppColors.warning,
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Grabber
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 28),
            decoration: BoxDecoration(
              color: AppColors.line,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Context-specific artwork if given, else the generic state art.
          illustration ?? ResultIllustration(kind: kind, size: 150),
          const SizedBox(height: 28),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14.5,
              color: AppColors.inkSoft,
              height: 1.55,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Done',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A polished, self-contained 2D vector illustration for a result state
/// (success / error / warning). Drawn with a [CustomPainter] — a soft halo, a
/// gradient badge with a highlight, a bold white glyph, and floating accent
/// dots — so no image assets are needed.
class ResultIllustration extends StatelessWidget {
  const ResultIllustration({super.key, required this.kind, this.size = 132});

  final ResultKind kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _ResultPainter(kind)),
    );
  }
}

/// Show/hide password eye: a clean filled eye when hidden (tap to reveal) and
/// a filled slashed eye when the password is visible.
class EyeToggleIcon extends StatelessWidget {
  const EyeToggleIcon({
    super.key,
    required this.obscured,
    this.size = 22,
    this.color = AppColors.inkSoft,
  });

  final bool obscured;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Icon(
      obscured ? Icons.visibility : Icons.visibility_off,
      size: size,
      color: color,
    );
  }
}

/// A polished 2D vector "security" illustration (gradient badge + lock glyph +
/// floating accent dots), styled to match [ResultIllustration]. Use [accent] to
/// tint it (e.g. brand red for a disable action).
class SecurityIllustration extends StatelessWidget {
  const SecurityIllustration({super.key, this.size = 104, this.accent});

  final double size;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LockPainter(accent ?? AppColors.brandRed),
      ),
    );
  }
}

/// A 2D vector fingerprint illustration for biometric actions — a tinted disc
/// with concentric fingerprint ridges and floating accent dots. When
/// [enabled] is false it renders muted with a "disabled" slash.
class FingerprintIllustration extends StatelessWidget {
  const FingerprintIllustration(
      {super.key, this.size = 150, this.enabled = true, this.accent});

  final double size;
  final bool enabled;

  /// Tint for the enabled state (defaults to the light brand red).
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _FingerprintPainter(
          enabled,
          accent ?? AppColors.brandRedSoft,
        ),
      ),
    );
  }
}

class _FingerprintPainter extends CustomPainter {
  _FingerprintPainter(this.enabled, this.enabledColor);

  final bool enabled;
  final Color enabledColor;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final base = enabled ? enabledColor : const Color(0xFF94A3B8);
    final dark = Color.lerp(base, Colors.black, 0.20)!;
    final light = Color.lerp(base, Colors.white, 0.40)!;
    final R = size.width * 0.34;

    void dot(double angleDeg, double dist, double radius, double alpha) {
      final a = angleDeg * math.pi / 180;
      canvas.drawCircle(
        Offset(c.dx + dist * math.cos(a), c.dy + dist * math.sin(a)),
        radius,
        Paint()..color = base.withValues(alpha: alpha),
      );
    }

    dot(-58, R * 1.34, size.width * 0.026, 0.9);
    dot(30, R * 1.42, size.width * 0.016, 0.5);
    dot(160, R * 1.36, size.width * 0.020, 0.35);
    dot(212, R * 1.30, size.width * 0.014, 0.6);

    canvas.drawCircle(c, R * 1.16, Paint()..color = base.withValues(alpha: 0.12));
    canvas.drawCircle(
      c + Offset(0, R * 0.14),
      R,
      Paint()
        ..color = base.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawCircle(
      c,
      R,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [light, base, dark],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: R)),
    );
    canvas.drawCircle(
      c - Offset(R * 0.28, R * 0.34),
      R * 0.42,
      Paint()..color = Colors.white.withValues(alpha: 0.16),
    );

    // Fingerprint ridges (concentric arcs with a gap), clipped to the disc.
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: R)));
    final ridge = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = R * 0.085
      ..strokeCap = StrokeCap.round;
    final fc = c + Offset(0, R * 0.06);
    for (int k = 1; k <= 4; k++) {
      canvas.drawArc(
        Rect.fromCircle(center: fc, radius: R * 0.16 * k),
        math.pi * 1.12,
        math.pi * 1.46,
        false,
        ridge,
      );
    }
    // Central ridge tick.
    canvas.drawLine(
        fc + Offset(0, -R * 0.06), fc + Offset(0, R * 0.16), ridge);
    canvas.restore();

    // Disabled slash across the print.
    if (!enabled) {
      final p1 = c + Offset(-R * 0.62, -R * 0.62);
      final p2 = c + Offset(R * 0.62, R * 0.62);
      canvas.drawLine(
          p1, p2, Paint()
            ..color = base
            ..style = PaintingStyle.stroke
            ..strokeWidth = R * 0.26
            ..strokeCap = StrokeCap.round);
      canvas.drawLine(
          p1, p2, Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = R * 0.12
            ..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(covariant _FingerprintPainter oldDelegate) =>
      oldDelegate.enabled != enabled ||
      oldDelegate.enabledColor != enabledColor;
}

class _LockPainter extends CustomPainter {
  _LockPainter(this.base);

  final Color base;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final dark = Color.lerp(base, Colors.black, 0.22)!;
    final light = Color.lerp(base, Colors.white, 0.35)!;
    final r = size.width * 0.30;

    void dot(double angleDeg, double dist, double radius, double alpha) {
      final a = angleDeg * math.pi / 180;
      canvas.drawCircle(
        Offset(c.dx + dist * math.cos(a), c.dy + dist * math.sin(a)),
        radius,
        Paint()..color = base.withValues(alpha: alpha),
      );
    }

    dot(-50, r * 1.45, size.width * 0.026, 0.85);
    dot(40, r * 1.5, size.width * 0.016, 0.45);
    dot(160, r * 1.45, size.width * 0.02, 0.35);

    canvas.drawCircle(c, r * 1.28, Paint()..color = base.withValues(alpha: 0.12));
    canvas.drawCircle(
      c + Offset(0, r * 0.16),
      r,
      Paint()
        ..color = base.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [light, base, dark],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawCircle(
      c - Offset(r * 0.28, r * 0.34),
      r * 0.42,
      Paint()..color = Colors.white.withValues(alpha: 0.16),
    );

    // Lock glyph (white): shackle arc + body + keyhole.
    final white = Paint()..color = Colors.white;
    final bodyW = r * 0.86, bodyH = r * 0.66;
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: c + Offset(0, r * 0.16), width: bodyW, height: bodyH),
      Radius.circular(r * 0.16),
    );
    // Shackle.
    final shackle = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.14
      ..strokeCap = StrokeCap.round;
    final shRect = Rect.fromCenter(
        center: c + Offset(0, -r * 0.22), width: bodyW * 0.62, height: r * 0.7);
    canvas.drawArc(shRect, math.pi, math.pi, false, shackle);
    canvas.drawRRect(body, white);
    // Keyhole.
    canvas.drawCircle(c + Offset(0, r * 0.06), r * 0.11,
        Paint()..color = base.withValues(alpha: 0.95));
    canvas.drawRect(
      Rect.fromCenter(
          center: c + Offset(0, r * 0.24), width: r * 0.08, height: r * 0.22),
      Paint()..color = base.withValues(alpha: 0.95),
    );
  }

  @override
  bool shouldRepaint(covariant _LockPainter oldDelegate) =>
      oldDelegate.base != base;
}

/// Draws a small white glyph (check / cross / exclamation) centered at [c].
void _paintGlyph(Canvas canvas, Offset c, double r, ResultKind kind,
    {Color color = Colors.white}) {
  final stroke = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = r * 0.34
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  switch (kind) {
    case ResultKind.success:
      canvas.drawPath(
        Path()
          ..moveTo(c.dx - r * 0.42, c.dy + r * 0.02)
          ..lineTo(c.dx - r * 0.10, c.dy + r * 0.34)
          ..lineTo(c.dx + r * 0.46, c.dy - r * 0.34),
        stroke,
      );
      break;
    case ResultKind.error:
      canvas.drawLine(c + Offset(-r * 0.32, -r * 0.32),
          c + Offset(r * 0.32, r * 0.32), stroke);
      canvas.drawLine(c + Offset(r * 0.32, -r * 0.32),
          c + Offset(-r * 0.32, r * 0.32), stroke);
      break;
    case ResultKind.warning:
      canvas.drawLine(
          c + Offset(0, -r * 0.38), c + Offset(0, r * 0.14), stroke);
      canvas.drawCircle(
          c + Offset(0, r * 0.40), r * 0.14, Paint()..color = color);
      break;
  }
}

/// A richer document-scene illustration: a soft tinted disc, a stack of paper
/// documents with text lines and a status ribbon, and a coloured seal carrying
/// the state glyph — plus floating accent dots. Purely vector (no assets).
class _ResultPainter extends CustomPainter {
  _ResultPainter(this.kind);

  final ResultKind kind;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final base = switch (kind) {
      ResultKind.success => AppColors.success,
      ResultKind.error => AppColors.defaultBrand,
      ResultKind.warning => AppColors.warning,
    };
    final dark = Color.lerp(base, Colors.black, 0.20)!;
    final light = Color.lerp(base, Colors.white, 0.40)!;
    final R = size.width * 0.34; // backdrop disc radius

    // Floating accent dots for an illustrative feel.
    void dot(double angleDeg, double dist, double radius, double alpha) {
      final a = angleDeg * math.pi / 180;
      canvas.drawCircle(
        Offset(c.dx + dist * math.cos(a), c.dy + dist * math.sin(a)),
        radius,
        Paint()..color = base.withValues(alpha: alpha),
      );
    }

    dot(-58, R * 1.34, size.width * 0.026, 0.9);
    dot(28, R * 1.42, size.width * 0.016, 0.5);
    dot(158, R * 1.36, size.width * 0.020, 0.35);
    dot(210, R * 1.30, size.width * 0.014, 0.6);

    // Soft outer halo + solid gradient disc backdrop.
    canvas.drawCircle(
        c, R * 1.16, Paint()..color = base.withValues(alpha: 0.12));
    canvas.drawCircle(
      c,
      R,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [light, base],
        ).createShader(Rect.fromCircle(center: c, radius: R)),
    );

    // Clip documents to the disc so they sit nicely inside it.
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: R)));

    final docW = R * 0.92;
    final docH = R * 1.12;
    final line = AppColors.line;

    void paper(double dx, double dy, double angle, {bool front = false}) {
      canvas.save();
      canvas.translate(c.dx + dx, c.dy + dy);
      canvas.rotate(angle);
      final rect = Rect.fromCenter(
          center: Offset.zero, width: docW, height: docH);
      final rrect = RRect.fromRectAndRadius(rect, Radius.circular(R * 0.10));
      // Shadow.
      canvas.drawRRect(
        rrect.shift(const Offset(0, 3)),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.14)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawRRect(rrect, Paint()..color = Colors.white);
      if (front) {
        // Text lines.
        final bar = Paint()..color = line;
        for (int i = 0; i < 3; i++) {
          final y = -docH * 0.24 + i * (docH * 0.15);
          final w = i == 2 ? docW * 0.4 : docW * 0.62;
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(-docW * 0.28, y, w, docH * 0.055),
              Radius.circular(docH * 0.03),
            ),
            bar,
          );
        }
        // Status ribbon pill near the bottom.
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(0, docH * 0.28),
                width: docW * 0.62,
                height: docH * 0.16),
            Radius.circular(docH * 0.08),
          ),
          Paint()..color = base.withValues(alpha: 0.16),
        );
      }
      canvas.restore();
    }

    // Back document (tilted), then front document.
    paper(R * 0.16, -R * 0.04, 0.14);
    paper(-R * 0.05, R * 0.05, -0.06, front: true);

    canvas.restore();

    // Seal badge overlapping the top-right of the documents.
    final sealCenter = c + Offset(R * 0.40, -R * 0.42);
    final sealR = R * 0.34;
    canvas.drawCircle(
      sealCenter + const Offset(0, 2),
      sealR,
      Paint()
        ..color = dark.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(sealCenter, sealR, Paint()..color = Colors.white);
    canvas.drawCircle(sealCenter, sealR * 0.82,
        Paint()..color = dark);
    _paintGlyph(canvas, sealCenter, sealR * 0.82, kind);
  }

  @override
  bool shouldRepaint(covariant _ResultPainter oldDelegate) =>
      oldDelegate.kind != kind;
}

/// Full-screen loading overlay with blur effect and spinner icon.
class LoadingOverlay extends StatefulWidget {
  const LoadingOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<LoadingOverlay> {
  bool _isLoading = false;
  DateTime? _shownAt;
  Timer? _showTimer;
  // How many loaders currently want the overlay. It stays visible until every
  // one has called hide() — so a page with several loading sections shows one
  // whole-page blur until all of them finish.
  int _refCount = 0;

  // Only show the loader if the work outlasts this delay — quick actions/pages
  // never flash it. Once shown, keep it up at least [_minVisible] so it never
  // flickers.
  static const _showDelay = Duration(milliseconds: 300);
  static const _minVisible = Duration(milliseconds: 400);

  void _showNow() {
    _showTimer = null;
    if (!mounted) return;
    _shownAt = DateTime.now();
    setState(() => _isLoading = true);
  }

  void show({bool immediate = false}) {
    if (!mounted) return;
    _refCount++;
    if (_isLoading) return;
    if (immediate) {
      _showTimer?.cancel();
      _showNow();
      return;
    }
    _showTimer ??= Timer(_showDelay, _showNow);
  }

  void hide() {
    if (!mounted) return;
    if (_refCount > 0) _refCount--;
    if (_refCount > 0) return; // other loaders still active
    // Still within the pre-show delay — the work was fast, never show it.
    if (_showTimer != null) {
      _showTimer!.cancel();
      _showTimer = null;
      return;
    }
    if (!_isLoading) return;
    final shownFor =
        _shownAt == null ? _minVisible : DateTime.now().difference(_shownAt!);
    final remaining = _minVisible - shownFor;
    if (remaining > Duration.zero) {
      Future.delayed(remaining, () {
        if (mounted && _refCount == 0) setState(() => _isLoading = false);
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _showTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isLoading)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: Colors.black.withValues(alpha: 0.18),
                alignment: Alignment.center,
                // A slim horizontal line loader, centered (matches the splash).
                child: SizedBox(
                  width: 130,
                  height: 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      backgroundColor: Color(0xFFF3D3D9),
                      valueColor: AlwaysStoppedAnimation(AppColors.brandRed),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
