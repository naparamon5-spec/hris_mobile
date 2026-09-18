import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The ANI HRIS app icon: crisp white squircle with a bold red 'H' centered,
/// matching the app icon.
class AniHrisIcon extends StatelessWidget {
  const AniHrisIcon({
    super.key,
    this.size = 64,
    this.hasShadow = true,
  });

  final double size;
  final bool hasShadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.22),
        border: Border.all(
          color: AppColors.line,
          width: 1,
        ),
        boxShadow: hasShadow
            ? [
                BoxShadow(
                  color: const Color(0x14101828),
                  blurRadius: size * 0.16,
                  offset: Offset(0, size * 0.06),
                ),
                BoxShadow(
                  color: AppColors.defaultBrand.withValues(alpha: 0.08),
                  blurRadius: size * 0.08,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        'H',
        style: TextStyle(
          // The 'H' logo mark stays the brand red for every company.
          color: AppColors.defaultBrand,
          fontSize: size * 0.58,
          fontWeight: FontWeight.w900,
          fontFamily: 'Roboto',
          height: 1.0,
        ),
      ),
    );
  }
}

/// Clean branded header with the ANI HRIS icon and title.
class AniHrisWordmark extends StatelessWidget {
  const AniHrisWordmark({
    super.key,
    this.iconSize = 40,
    this.showSubtitle = true,
  });

  final double iconSize;
  final bool showSubtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AniHrisIcon(size: iconSize),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'ANI HRIS',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
                color: AppColors.ink,
                height: 1.1,
              ),
            ),
            if (showSubtitle) ...[
              const SizedBox(height: 2),
              const Text(
                'Ardent Networks, Inc.',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkSoft,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// The Ardent Networks wordmark — red ball + black swoosh sweeping over
/// "ARDENT", with "NETWORKS, INC" beneath. Drawn with a painter (no asset
/// dependency) so it stays crisp at any size. Swap for the official SVG/PNG
/// asset when one is available.
class ArdentLogo extends StatelessWidget {
  const ArdentLogo({super.key, this.height = 40});

  /// Logical height in px; width follows the mark's 210:56 aspect ratio.
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: height * (210 / 56),
      height: height,
      child: CustomPaint(painter: _ArdentLogoPainter()),
    );
  }
}

class _ArdentLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.height / 56.0);

    // Black swoosh (crescent sweeping up to the right).
    final swoosh = Path()
      ..moveTo(24, 44)
      ..cubicTo(64, 4, 148, 3, 206, 20)
      ..cubicTo(150, 12, 74, 18, 32, 48)
      ..close();
    canvas.drawPath(
      swoosh,
      Paint()
        ..color = AppColors.ink
        ..isAntiAlias = true,
    );

    // Red ball at the base of the mark.
    canvas.drawCircle(
      const Offset(19, 42),
      15,
      Paint()
        ..color = AppColors.brandRed
        ..isAntiAlias = true,
    );

    _text(canvas, 'ARDENT', 30, FontWeight.w800, AppColors.ink, 0.5, 52, 38);
    final sub = _layout(
      'NETWORKS, INC',
      8.5,
      FontWeight.w700,
      AppColors.brandRed,
      3,
    );
    sub.paint(
      canvas,
      Offset(
        206 - sub.width,
        52 - sub.computeDistanceToActualBaseline(TextBaseline.alphabetic),
      ),
    );

    canvas.restore();
  }

  void _text(
    Canvas canvas,
    String text,
    double size,
    FontWeight weight,
    Color color,
    double spacing,
    double x,
    double baseline,
  ) {
    final tp = _layout(text, size, weight, color, spacing);
    tp.paint(
      canvas,
      Offset(
        x,
        baseline - tp.computeDistanceToActualBaseline(TextBaseline.alphabetic),
      ),
    );
  }

  TextPainter _layout(
    String text,
    double size,
    FontWeight weight,
    Color color,
    double spacing,
  ) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: size,
          fontWeight: weight,
          color: color,
          letterSpacing: spacing,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  @override
  bool shouldRepaint(covariant _ArdentLogoPainter oldDelegate) => false;
}

/// Two-tone shield carrying a green check — the app's security motif, echoing
/// the illustration on the HRIS website. [progress] (0–1) reveals the check so
/// the splash can draw it on; leave at 1 for a static mark.
class ShieldMark extends StatelessWidget {
  const ShieldMark({super.key, this.size = 84, this.progress = 1});

  final double size;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * (150 / 172),
      height: size,
      child: CustomPaint(painter: _ShieldPainter(progress)),
    );
  }
}

class _ShieldPainter extends CustomPainter {
  _ShieldPainter(this.progress);

  final double progress;

  static const _stroke = Color(0xFFF1CDD4);
  static const _tint = Color(0xFFFDEAEE);
  static const _check = Color(0xFF2FCB7E);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.height / 172.0);

    final body = Path()
      ..moveTo(75, 6)
      ..lineTo(135, 28)
      ..lineTo(135, 74)
      ..cubicTo(135, 114, 109, 140, 75, 160)
      ..cubicTo(41, 140, 15, 114, 15, 74)
      ..lineTo(15, 28)
      ..close();

    final rightHalf = Path()
      ..moveTo(75, 6)
      ..lineTo(135, 28)
      ..lineTo(135, 74)
      ..cubicTo(135, 114, 109, 140, 75, 160)
      ..lineTo(75, 6)
      ..close();

    canvas.drawPath(body, Paint()..color = Colors.white);
    canvas.drawPath(rightHalf, Paint()..color = _tint);
    canvas.drawPath(
      body,
      Paint()
        ..color = _stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..isAntiAlias = true,
    );

    // Check mark, revealed by [progress].
    final check = Path()
      ..moveTo(50, 88)
      ..lineTo(67, 105)
      ..lineTo(104, 66);
    final drawn = Path();
    for (final metric in check.computeMetrics()) {
      drawn.addPath(
        metric.extractPath(0, metric.length * progress.clamp(0, 1)),
        Offset.zero,
      );
    }
    canvas.drawPath(
      drawn,
      Paint()
        ..color = _check
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ShieldPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
