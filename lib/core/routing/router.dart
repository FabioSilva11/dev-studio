import 'package:flutter/material.dart';
import 'package:dev_studio/core/routing/routes.dart';
import 'package:dev_studio/ui/pages/splash/splash_page.dart';
import 'package:dev_studio/ui/pages/projects/project_list_page.dart';
import 'package:dev_studio/ui/pages/projects/project_create_page.dart';
import 'package:dev_studio/ui/pages/editor/editor_page.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.splash:
        return MaterialPageRoute(builder: (_) => const SplashPage());
      case Routes.projectList:
        return MaterialPageRoute(builder: (_) => const ProjectListPage());
      case Routes.projectCreate:
        return MaterialPageRoute(builder: (_) => const ProjectCreatePage());
      case Routes.editor:
        final args = settings.arguments as Map<String, dynamic>?;
        final projectId = args?['projectId'] as String?;
        return MaterialPageRoute(
          builder: (_) => EditorPage(projectId: projectId),
        );
      default:
        return MaterialPageRoute(builder: (_) => const SplashPage());
    }
  }
}
