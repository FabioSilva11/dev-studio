import 'package:go_router/go_router.dart';

import '/core/config/dependencies.dart';
import '/core/routing/routes.dart';
import '/ui/pages/home/home_page.dart';
import '../../../ui/pages/home/home_viewmodel.dart';
import '../../../ui/pages/splash/splash_page.dart';
import '../../../ui/pages/splash/splash_viewmodel.dart';

List<RouteBase> baseRoutes() => [
  GoRoute(
    path: BaseRoutes.home.routePath,
    name: BaseRoutes.home.routeName,
    builder: (context, state) => HomePage(
      viewmodel: injector.get<HomeViewmodel>(),
    ),
  ),

  GoRoute(
    path: BaseRoutes.splash.routePath,
    name: BaseRoutes.splash.routeName,
    builder: (context, state) => SplashPage(
      viewmodel: injector.get<SplashViewmodel>(),
    ),
  ),
];
