import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:dev_studio/ui/pages/splash/splash_page.dart';

const appSurfaceColor = Color(0xFFF8F9FA);
const appPrimaryColor = Color(0xFF6B5CE7);

class DevStudioApp extends StatelessWidget {
  const DevStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dev Studio',
      debugShowCheckedModeBanner: false,
      restorationScopeId: 'dev_studio_app',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: appSurfaceColor,
        textTheme: GoogleFonts.interTextTheme(),
        colorScheme: ColorScheme.fromSeed(
          seedColor: appPrimaryColor,
          surface: appSurfaceColor,
        ),
      ),
      home: const SplashPage(),
    );
  }
}
