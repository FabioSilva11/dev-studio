import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dev_studio/ui/app_widget.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: appSurfaceColor,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: appSurfaceColor,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const DevStudioApp());
}
