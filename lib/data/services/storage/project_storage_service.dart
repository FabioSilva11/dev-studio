import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:dev_studio/domain/common/project/dev_studio_project.dart';
import 'package:dev_studio/domain/common/project/project_summary.dart';
import 'package:dev_studio/data/services/serialization/project_json_service.dart';
import 'package:dev_studio/core/resources/storage_keys.dart';

class ProjectStorageService {
  static const platform = MethodChannel('dev_studio/storage');
  final ProjectJsonService jsonService;

  const ProjectStorageService({
    required this.jsonService,
  });

  Future<List<ProjectSummary>> listProjects() async {
    try {
      final result = await platform.invokeMethod<List<Object?>>('listProjects');
      if (result == null) return [];
      return result.map((item) {
        final map = item as Map<Object?, Object?>;
        return ProjectSummary(
          id: map['id']?.toString() ?? '',
          name: map['name']?.toString() ?? '',
          packageName: map['packageName']?.toString() ?? '',
          versionName: map['versionName']?.toString() ?? '1.0.0',
          versionCode: (map['versionCode'] as num?)?.toInt() ?? 1,
          screenCount: (map['screenCount'] as num?)?.toInt() ?? 0,
          createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
          updatedAt: DateTime.tryParse(map['updatedAt']?.toString() ?? '') ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<DevStudioProject?> loadProject(String projectId) async {
    try {
      final jsonString = await platform.invokeMethod<String>('loadProject', {'projectId': projectId});
      if (jsonString == null || jsonString.isEmpty) return null;
      return jsonService.decode(jsonString);
    } catch (e) {
      return null;
    }
  }

  Future<bool> saveProject(DevStudioProject project) async {
    try {
      final jsonString = jsonService.encode(project);
      await platform.invokeMethod('saveProject', {
        'projectId': project.id,
        'projectJson': jsonString,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteProject(String projectId) async {
    try {
      await platform.invokeMethod('deleteProject', {'projectId': projectId});
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> hasStorageAccess() async {
    try {
      final result = await platform.invokeMethod<bool>('hasStorageAccess');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> requestStorageAccess() async {
    try {
      final result = await platform.invokeMethod<bool>('requestStorageAccess');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }
}
