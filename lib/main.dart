import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

import 'core/config/dependencies.dart';
import 'ui/app_widget.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  setupDependencies();

  runApp(const AppWidget());
}
