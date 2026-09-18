import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../theme/app_colors.dart';
import 'ui.dart';

/// Renders the three states of a network load — pending, error, data — with a
/// consistent spinner and a retry button, so screens don't each reimplement it.
///
/// Use [controller] to trigger reloads (e.g. from pull-to-refresh) by calling
/// `controller.reload()`.
class AsyncView<T> extends StatefulWidget {
  const AsyncView({
    super.key,
    required this.load,
    required this.builder,
    this.controller,
    this.onSettled,
    this.useGlobalLoader = false,
  });

  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data) builder;
  final AsyncViewController? controller;

  /// Called once after the first load finishes (data or error). Handy for
  /// dismissing a global loading overlay when the screen's content is ready.
  final VoidCallback? onSettled;

  /// When true, show the global blur loader while loading (only if it's slow,
  /// thanks to the overlay's show-delay) instead of the inline circular spinner.
  final bool useGlobalLoader;

  @override
  State<AsyncView<T>> createState() => _AsyncViewState<T>();
}

class AsyncViewController extends ChangeNotifier {
  void reload() => notifyListeners();
}

class _AsyncViewState<T> extends State<AsyncView<T>> {
  late Future<T> _future;
  bool _settledNotified = false;
  // Whether we've shown the global loader for the current load (kept balanced
  // with exactly one hide, so the overlay's ref-count stays correct).
  bool _globalLoaderShown = false;

  @override
  void initState() {
    super.initState();
    _future = widget.load();
    widget.controller?.addListener(_reload);
  }

  void _showGlobalLoaderOnce() {
    if (_globalLoaderShown) return;
    _globalLoaderShown = true;
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => showLoadingOverlay(context, immediate: true));
  }

  void _notifySettled() {
    if (_settledNotified) return;
    if (widget.onSettled == null && !widget.useGlobalLoader) return;
    _settledNotified = true;
    final wasLoaderShown = _globalLoaderShown;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (wasLoaderShown) hideLoadingOverlay(context);
      widget.onSettled?.call();
    });
  }

  void _reload() {
    _settledNotified = false;
    _globalLoaderShown = false;
    setState(() => _future = widget.load());
  }

  @override
  void dispose() {
    // Balance the ref-count if we're torn down mid-load.
    if (_globalLoaderShown && !_settledNotified) {
      hideLoadingOverlay(context);
    }
    widget.controller?.removeListener(_reload);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          if (widget.useGlobalLoader) {
            // Cover the whole screen with the blur loader while loading, and
            // render nothing inline. Shown once per load (balanced with hide).
            _showGlobalLoaderOnce();
            return const SizedBox.shrink();
          }
          // Inline loader shown immediately: the centered horizontal line
          // (matches the global/splash loader) so the user always sees it.
          return Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: SizedBox(
                width: 130,
                height: 4,
                child: ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(99)),
                  child: LinearProgressIndicator(
                    backgroundColor: Color(0xFFF3D3D9),
                    valueColor: AlwaysStoppedAnimation(AppColors.brandRed),
                  ),
                ),
              ),
            ),
          );
        }
        _notifySettled();
        if (snap.hasError) {
          return _ErrorState(
            message: snap.error is ApiException
                ? (snap.error as ApiException).message
                : 'Something went wrong.',
            onRetry: _reload,
          );
        }
        return widget.builder(context, snap.data as T);
      },
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 52, color: AppColors.inkFaint),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.inkSoft,
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
