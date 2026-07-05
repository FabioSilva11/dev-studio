import 'dart:async';

import 'package:flutter/material.dart';

import 'package:dev_studio/core/config/dependencies.dart';
import 'package:dev_studio/ui/app_widget.dart';
import 'package:dev_studio/ui/pages/projects/project_list_page.dart';
import 'package:dev_studio/ui/pages/splash/viewmodel/splash_viewmodel.dart';

const _secondaryTextColor = Color(0xFF8E8E93);

class SplashPage extends StatefulWidget {
  const SplashPage({
    super.key,
    this.viewModel,
  });

  final SplashViewModel? viewModel;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  Timer? _navigationTimer;
  bool _isVisible = false;

  SplashViewModel get _viewModel =>
      widget.viewModel ?? Dependencies.splashViewModel();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _isVisible = true);
      }
    });
    _navigationTimer = Timer(_viewModel.duration, _openMainScreen);
  }

  void _openMainScreen() {
    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => const ProjectListPage(),
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
                'assets/images/devstudio_icon.webp',
                width: 96,
                height: 96,
              ),
              const SizedBox(height: 24),
              const Text(
                'Dev Studio',
                style: TextStyle(
                  color: appPrimaryColor,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Entre no incrivel mundo Dev!',
                style: TextStyle(
                  color: _secondaryTextColor,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

