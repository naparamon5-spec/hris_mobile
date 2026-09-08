import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// A white rounded card with the standard soft shadow.
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.color = AppColors.card,
    this.radius = 22,
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
            border: border,
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
    this.color = AppColors.brandRed,
    this.bg,
    this.size = 44,
    this.iconSize = 22,
  });

  final IconData icon;
  final Color color;
  final Color? bg;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
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
                  style: const TextStyle(
                    color: AppColors.brandRed,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
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
    final parts = name.trim().split(RegExp(r'\s+'));
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

/// Simple snackbar helper used for the static demo interactions.
void showToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Text(message,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        duration: const Duration(seconds: 2),
      ),
    );
}
