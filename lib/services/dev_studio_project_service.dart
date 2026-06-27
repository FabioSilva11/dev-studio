import 'dart:typed_data';

import 'package:flutter/services.dart';

import '../models/project_item.dart';

class DevStudioProjectService {
  const DevStudioProjectService();

  static const MethodChannel _channel = MethodChannel('dev_studio/projects');

  Future<bool> hasStorageAccess() async {
    return await _channel.invokeMethod<bool>('hasStorageAccess') ?? false;
  }

  Future<void> requestStorageAccess() async {
    await _channel.invokeMethod<void>('requestStorageAccess');
  }

  Future<List<ProjectItem>> loadProjects() async {
    final rawProjects = await _channel.invokeListMethod<Object?>(
      'loadProjects',
    );
    if (rawProjects == null) return const [];

    return rawProjects
        .whereType<Map<Object?, Object?>>()
        .map(ProjectItem.fromPlatformMap)
        .where((project) => project.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<ProjectCreationDefaults> getProjectCreationDefaults() async {
    final raw = await _channel.invokeMapMethod<Object?, Object?>(
      'getProjectCreationDefaults',
    );
    return ProjectCreationDefaults.fromPlatformMap(raw ?? const {});
  }

  Future<Uint8List?> pickProjectIcon() {
    return _channel.invokeMethod<Uint8List>('pickProjectIcon');
  }

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
    final raw = await _channel
        .invokeMapMethod<Object?, Object?>('createProject', <String, Object?>{
          'id': defaults.id,
          'appName': appName,
          'projectName': projectName,
          'packageName': packageName,
          'versionCode': versionCode,
          'versionName': versionName,
          'colors': colors,
          'iconBytes': iconBytes,
        });
    if (raw == null) {
      throw PlatformException(
        code: 'project_create_failed',
        message: 'The project was not returned after it was created.',
      );
    }
    return ProjectItem.fromPlatformMap(raw);
  }

  Future<Map<String, Object?>> loadEditorProject(String projectId) async {
    final raw = await _channel.invokeMapMethod<Object?, Object?>(
      'loadEditorProject',
      <String, Object?>{'projectId': projectId},
    );
    return _normalizeMap(raw ?? const {});
  }

  Future<void> saveEditorProject(String projectId, Map<String, Object?> data) {
    return _channel.invokeMethod<void>('saveEditorProject', <String, Object?>{
      'projectId': projectId,
      'data': data,
    });
  }

  static Map<String, Object?> _normalizeMap(Map<Object?, Object?> raw) {
    Object? normalize(Object? value) {
      if (value is Map) {
        return value.map(
          (key, item) => MapEntry(key.toString(), normalize(item)),
        );
      }
      if (value is List) return value.map(normalize).toList();
      return value;
    }

    return raw.map((key, value) => MapEntry(key.toString(), normalize(value)));
  }
}

class ProjectCreationDefaults {
  const ProjectCreationDefaults({
    required this.id,
    required this.projectName,
    required this.packageName,
    required this.versionCode,
    required this.versionName,
    required this.colors,
  });

  final String id;
  final String projectName;
  final String packageName;
  final String versionCode;
  final String versionName;
  final List<int> colors;

  factory ProjectCreationDefaults.fromPlatformMap(Map<Object?, Object?> map) {
    String readString(String key, String fallback) {
      final value = map[key]?.toString().trim() ?? '';
      return value.isEmpty ? fallback : value;
    }

    const fallbackColors = <int>[
      0xFF6B5CE7,
      0xFF6B5CE7,
      0xFF4B3EC4,
      0x206B5CE7,
      0xFF6B5CE7,
    ];
    final rawColors = map['colors'];
    final colors = rawColors is List
        ? rawColors.whereType<int>().toList(growable: false)
        : const <int>[];

    return ProjectCreationDefaults(
      id: readString('id', '1'),
      projectName: readString('projectName', 'NewProject'),
      packageName: readString('packageName', 'com.my.newproject'),
      versionCode: readString('versionCode', '1'),
      versionName: readString('versionName', '1.0'),
      colors: colors.length == 5 ? colors : fallbackColors,
    );
  }
}
