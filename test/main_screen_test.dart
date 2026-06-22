import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dev_studio/main_screen.dart';
import 'package:dev_studio/models/project_item.dart';
import 'package:dev_studio/project_creation_screen.dart';
import 'package:dev_studio/project_editor_screen.dart';
import 'package:dev_studio/services/sketchware_project_service.dart';

class FakeProjectService extends SketchwareProjectService {
  const FakeProjectService();

  @override
  Future<ProjectCreationDefaults> getProjectCreationDefaults() async {
    return const ProjectCreationDefaults(
      id: '604',
      projectName: 'NewProject',
      packageName: 'com.my.newproject',
      versionCode: '1',
      versionName: '1.0',
      colors: [0xFF2196F3, 0xFF2196F3, 0xFF1976D2, 0x202196F3, 0xFF2196F3],
    );
  }

  @override
  Future<ProjectItem> createProject({
    required ProjectCreationDefaults defaults,
    required String appName,
    required String projectName,
    required String packageName,
    required String versionCode,
    required String versionName,
    required List<int> colors,
    Uint8List? iconBytes,
  }) async {
    return ProjectItem(
      id: defaults.id,
      appName: appName,
      workspaceName: projectName,
      packageName: packageName,
      versionName: versionName,
      versionCode: versionCode,
      kind: ProjectKind.native,
    );
  }

  @override
  Future<Map<String, Object?>> loadEditorProject(String projectId) async {
    return const {};
  }

  @override
  Future<void> saveEditorProject(
    String projectId,
    Map<String, Object?> data,
  ) async {}
}

Future<void> pumpMainScreen(WidgetTester tester) async {
  await tester.pumpWidget(
    const MaterialApp(
      restorationScopeId: 'test_app',
      home: MainScreen(
        initialProjects: sampleProjects,
        projectService: FakeProjectService(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('keeps the three main tabs and removes Store', (tester) async {
    await pumpMainScreen(tester);

    expect(find.text('Projects'), findsOneWidget);
    expect(find.text('Web Service'), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Store'), findsNothing);
    expect(find.byKey(const Key('new-project-fab')), findsOneWidget);
  });

  testWidgets('drawer recreates the Sketchware menu without navigation', (
    tester,
  ) async {
    await pumpMainScreen(tester);

    await tester.tap(find.byKey(const Key('open-drawer')));
    await tester.pumpAndSettle();

    expect(find.text('About the team'), findsOneWidget);
    expect(find.text('Changelog'), findsOneWidget);
    expect(find.text('App information'), findsOneWidget);
    expect(find.text('Create keystore'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.text('About the team'));
    await tester.pumpAndSettle();
    expect(find.byType(MainScreen), findsOneWidget);
  });

  testWidgets('search filters the project list', (tester) async {
    await pumpMainScreen(tester);

    await tester.tap(find.byKey(const Key('open-project-search')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('project-search-field')),
      '603',
    );
    await tester.pump();

    expect(find.text('Weather'), findsOneWidget);
    expect(find.text('Calculator'), findsNothing);
  });

  testWidgets('web-service item clicks stay in the main screen', (
    tester,
  ) async {
    await pumpMainScreen(tester);

    await tester.tap(find.byKey(const Key('nav-web-service')));
    await tester.pumpAndSettle();

    expect(find.text('APIs and resources'), findsOneWidget);
    expect(find.text('JSONPlaceholder'), findsOneWidget);
    expect(find.text('DummyJSON'), findsOneWidget);
    expect(find.text('REST Countries'), findsOneWidget);

    await tester.tap(find.text('JSONPlaceholder'));
    await tester.pumpAndSettle();
    expect(find.text('APIs and resources'), findsOneWidget);

    await tester.drag(
      find.byKey(const PageStorageKey('web-services-list')),
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();
    expect(find.text('GitHub API'), findsOneWidget);
  });

  testWidgets('new project opens the Flutter form and returns after saving', (
    tester,
  ) async {
    await pumpMainScreen(tester);

    await tester.tap(find.byKey(const Key('new-project-fab')));
    await tester.pumpAndSettle();
    expect(find.byType(ProjectCreationScreen), findsOneWidget);
    expect(find.text('New Project'), findsOneWidget);
    expect(find.text('Android Studio'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('application-name')),
      'Test App',
    );
    await tester.tap(find.byKey(const Key('save-project')));
    await tester.pumpAndSettle();
    expect(find.byType(MainScreen), findsOneWidget);
    expect(find.text('Test App'), findsOneWidget);
  });

  testWidgets('project opens the four-tab editor and right menu', (
    tester,
  ) async {
    await pumpMainScreen(tester);

    await tester.tap(find.text('Dev Studio'));
    await tester.pumpAndSettle();

    expect(find.byType(ProjectEditorScreen), findsOneWidget);
    expect(find.text('View'), findsOneWidget);
    expect(find.text('Event'), findsOneWidget);
    expect(find.text('Component'), findsOneWidget);
    expect(find.text('Strings'), findsOneWidget);
    expect(find.text('Linear Layout'), findsWidgets);

    await tester.tap(find.byKey(const Key('open-editor-menu')));
    await tester.pumpAndSettle();
    expect(find.text('Library manager'), findsOneWidget);
    expect(find.text('AndroidManifest'), findsOneWidget);
  });

  testWidgets('layout editor accepts drag and opens full properties', (
    tester,
  ) async {
    await pumpMainScreen(tester);
    await tester.tap(find.text('Dev Studio'));
    await tester.pumpAndSettle();

    final paletteItem = find.text('Linear Layout');
    final canvas = find.byKey(const Key('editor-canvas'));
    final gesture = await tester.startGesture(tester.getCenter(paletteItem));
    await tester.pump(const Duration(milliseconds: 180));
    await gesture.moveTo(tester.getCenter(canvas));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('linearlayout1'), findsOneWidget);
    await tester.tap(find.text('See All'));
    await tester.pumpAndSettle();
    expect(find.text('View properties'), findsOneWidget);
    expect(find.text('Shadow / elevation'), findsOneWidget);
  });
}
