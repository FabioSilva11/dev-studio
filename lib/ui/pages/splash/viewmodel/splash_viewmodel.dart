import 'package:flutter/foundation.dart';

class SplashViewModel extends ChangeNotifier {
  SplashViewModel({this.duration = const Duration(seconds: 1)});

  final Duration duration;

  Future<void> waitForLaunch() {
    return Future<void>.delayed(duration);
  }
}
