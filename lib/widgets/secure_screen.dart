import 'package:flutter/widgets.dart';
import 'package:no_screenshot/no_screenshot.dart';

/// Blocks screenshots and screen recording while [child] is on screen (Android
/// FLAG_SECURE; iOS hides the content in captures). Use on screens showing
/// sensitive data such as payslips. Ref-counted, so nested or stacked secure
/// screens only re-allow capture once the last one is gone.
class SecureScreen extends StatefulWidget {
  const SecureScreen({super.key, required this.child});

  final Widget child;

  @override
  State<SecureScreen> createState() => _SecureScreenState();
}

class _SecureScreenState extends State<SecureScreen> {
  static int _active = 0;

  @override
  void initState() {
    super.initState();
    if (_active++ == 0) {
      NoScreenshot.instance.screenshotOff().catchError((_) => false);
    }
  }

  @override
  void dispose() {
    if (--_active == 0) {
      NoScreenshot.instance.screenshotOn().catchError((_) => false);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
