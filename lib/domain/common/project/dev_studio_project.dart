import 'package:dev_studio/domain/common/project/project_summary.dart';
import 'package:dev_studio/domain/common/editor/editor_screen.dart';
import 'package:dev_studio/domain/common/editor/dev_studio_logic.dart';

class DevStudioProject {
  const DevStudioProject({
    required this.id,
    required this.name,
    required this.packageName,
    required this.version,
    required this.theme,
    required this.screens,
    required this.logic,
    required this.assets,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String packageName;
  final DevStudioVersion version;
  final DevStudioTheme theme;
  final List<DevStudioScreen> screens;
  final DevStudioLogic logic;
  final List<DevStudioAsset> assets;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProjectSummary toSummary() {
    return ProjectSummary(
      id: id,
      name: name,
      packageName: packageName,
      versionName: version.name,
      versionCode: version.code,
      screenCount: screens.length,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  DevStudioProject copyWith({
    String? id,
    String? name,
    String? packageName,
    DevStudioVersion? version,
    DevStudioTheme? theme,
    List<DevStudioScreen>? screens,
    DevStudioLogic? logic,
    List<DevStudioAsset>? assets,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DevStudioProject(
      id: id ?? this.id,
      name: name ?? this.name,
      packageName: packageName ?? this.packageName,
      version: version ?? this.version,
      theme: theme ?? this.theme,
      screens: screens ?? this.screens,
      logic: logic ?? this.logic,
      assets: assets ?? this.assets,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class DevStudioVersion {
  const DevStudioVersion({
    required this.name,
    required this.code,
  });

  final String name;
  final int code;

  DevStudioVersion copyWith({
    String? name,
    int? code,
  }) {
    return DevStudioVersion(
      name: name ?? this.name,
      code: code ?? this.code,
    );
  }
}

class DevStudioTheme {
  const DevStudioTheme({
    required this.primaryColor,
    required this.backgroundColor,
  });

  final String primaryColor;
  final String backgroundColor;

  DevStudioTheme copyWith({
    String? primaryColor,
    String? backgroundColor,
  }) {
    return DevStudioTheme(
      primaryColor: primaryColor ?? this.primaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
    );
  }
}

class DevStudioAsset {
  const DevStudioAsset({
    required this.id,
    required this.name,
    required this.type,
    required this.path,
  });

  final String id;
  final String name;
  final String type;
  final String path;

  DevStudioAsset copyWith({
    String? id,
    String? name,
    String? type,
    String? path,
  }) {
    return DevStudioAsset(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      path: path ?? this.path,
    );
  }
}
