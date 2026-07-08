import 'package:auto_injector/auto_injector.dart';

import '/data/repositories/auth/auth_repository.dart';
import '/data/repositories/auth/auth_repository_impl.dart';

class Repositories {
  static void add(AutoInjector injector) {
    injector.addSingleton<AuthRepository>(AuthRepositoryImpl.new);
  }
}
