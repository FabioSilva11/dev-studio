import 'package:auto_injector/auto_injector.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'auth/auth_service.dart';

class Services {
  static void add(AutoInjector injector) {
    injector
      ..addSingleton<FirebaseAuth>(() => FirebaseAuth.instance)
      ..addSingleton<AuthService>(
        () => AuthService(firebaseAuth: injector.get<FirebaseAuth>()),
      );
  }
}
