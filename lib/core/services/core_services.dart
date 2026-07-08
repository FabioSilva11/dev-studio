import 'package:auto_injector/auto_injector.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'installation_identity/installation_identity.dart';
import 'secure_storage/flutter_secure_storage_local_storage.dart';
import 'secure_storage/local_secure_storage.dart';

class CoreServices {
  static void add(AutoInjector injector) {
    injector
      // 1. Secure Storage
      ..add<FlutterSecureStorage>(FlutterSecureStorage.new)
      // 2. Local Secure Storage (wrapper around FlutterSecureStorage)
      ..add<LocalSecureStorage>(
        () => FlutterSecureStorageLocalStorage(
          storage: injector.get<FlutterSecureStorage>(),
        ),
      )
      // 3. Installation identity
      ..add<InstallationMarkerStore>(FileInstallationMarkerStore.new)
      ..add<InstallationIdentityService>(
        () => InstallationIdentityService(
          secureStorage: injector.get<LocalSecureStorage>(),
          markerStore: injector.get<InstallationMarkerStore>(),
        ),
      );
  }
}
