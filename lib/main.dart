import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'core/theme/app_theme.dart';
import 'modules/main/view/main_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Lock orientation for a more "native" feel
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Set transparent status bar for modern look
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  runApp(const PremiumWebViewApp());
}

class PremiumWebViewApp extends StatelessWidget {
  const PremiumWebViewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'BetMakini',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: MainScreen(),
      defaultTransition: Transition.cupertino, // Smooth iOS transitions
    );
  }
}
