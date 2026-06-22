import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'main_screen.dart';

const _surfaceColor = Color(0xFFF8F9FA);
const _primaryColor = Color(0xFF6B5CE7);
const _secondaryTextColor = Color(0xFF8E8E93);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: _surfaceColor,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: _surfaceColor,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const DevStudioApp());
}

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
        scaffoldBackgroundColor: _surfaceColor,
        textTheme: GoogleFonts.interTextTheme(),
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryColor,
          surface: _surfaceColor,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _navigationTimer;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _isVisible = true);
      }
    });
    _navigationTimer = Timer(const Duration(seconds: 1), _openMainScreen);
  }

  void _openMainScreen() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => const MainScreen(),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AnimatedOpacity(
          opacity: _isVisible ? 1 : 0,
          duration: const Duration(milliseconds: 800),
          curve: Curves.decelerate,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/sketchware_icon.webp',
                width: 96,
                height: 96,
              ),
              const SizedBox(height: 24),
              const Text(
                'Dev Studio',
                style: TextStyle(
                  color: _primaryColor,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Entre no incrível mundo Dev!',
                style: TextStyle(color: _secondaryTextColor, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
