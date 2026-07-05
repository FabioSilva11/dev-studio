import 'package:flutter/foundation.dart';

import 'package:dev_studio/core/result/errors/app_error.dart';
import 'package:dev_studio/domain/common/project/project_summary.dart';
import 'package:dev_studio/domain/usecases/projects/has_storage_access_usecase.dart';
import 'package:dev_studio/domain/usecases/projects/list_projects_usecase.dart';
import 'package:dev_studio/domain/usecases/projects/request_storage_access_usecase.dart';
import 'package:dev_studio/domain/usecases/projects/open_project_usecase.dart';
import 'package:dev_studio/domain/common/project/dev_studio_project.dart';

class ProjectListViewModel extends ChangeNotifier {
  ProjectListViewModel({
    required HasStorageAccessUseCase hasStorageAccessUseCase,
    required ListProjectsUseCase listProjectsUseCase,
    required RequestStorageAccessUseCase requestStorageAccessUseCase,
    required OpenProjectUseCase openProjectUseCase,
  }) : _hasStorageAccessUseCase = hasStorageAccessUseCase,
       _listProjectsUseCase = listProjectsUseCase,
       _requestStorageAccessUseCase = requestStorageAccessUseCase,
       _openProjectUseCase = openProjectUseCase;

  final HasStorageAccessUseCase _hasStorageAccessUseCase;
  final ListProjectsUseCase _listProjectsUseCase;
  final RequestStorageAccessUseCase _requestStorageAccessUseCase;
  final OpenProjectUseCase _openProjectUseCase;

  Future<ProjectListLoadState> loadProjects() async {
    final accessResult = await _hasStorageAccessUseCase();
    return accessResult.when(
      success: (hasAccess) async {
        if (!hasAccess) {
          return const ProjectListLoadState(
            projects: <ProjectSummary>[],
            needsStorageAccess: true,
          );
        }

        final projectResult = await _listProjectsUseCase();
        return projectResult.when(
          success: (projects) => ProjectListLoadState(
            projects: projects,
            needsStorageAccess: false,
          ),
          failure: (error) => ProjectListLoadState(
            projects: const <ProjectSummary>[],
            error: error,
          ),
        );
      },
      failure: (error) async => ProjectListLoadState(
        projects: const <ProjectSummary>[],
        error: error,
        needsStorageAccess: true,
      ),
    );
  }

  Future<AppError?> requestStorageAccess() async {
    final result = await _requestStorageAccessUseCase();
    return result.when(
      success: (_) => null,
      failure: (error) => error,
    );
  }

  Future<({DevStudioProject? project, AppError? error})> openProject(String projectId) async {
    final result = await _openProjectUseCase(projectId);
    return result.when(
      success: (project) => (project: project, error: null),
      failure: (error) => (project: null, error: error),
    );
  }
}

class ProjectListLoadState {
  const ProjectListLoadState({
    required this.projects,
    this.error,
    this.needsStorageAccess = false,
  });

  final List<ProjectSummary> projects;
  final AppError? error;
  final bool needsStorageAccess;
}
