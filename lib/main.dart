import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme/app_theme.dart';
import 'screens/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const HrisApp());
}

class HrisApp extends StatelessWidget {
  const HrisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ardent HR',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const LoginScreen(),
    );
  }
}
