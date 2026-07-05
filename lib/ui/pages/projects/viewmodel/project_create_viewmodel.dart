import 'package:flutter/foundation.dart';

import 'package:dev_studio/core/result/errors/app_error.dart';
import 'package:dev_studio/domain/common/project/dev_studio_project.dart';
import 'package:dev_studio/domain/usecases/projects/create_project_usecase.dart';

class ProjectCreateViewModel extends ChangeNotifier {
  ProjectCreateViewModel({
    required CreateProjectUseCase createProjectUseCase,
  }) : _createProjectUseCase = createProjectUseCase;

  final CreateProjectUseCase _createProjectUseCase;

  Future<({DevStudioProject? project, AppError? error})> createProject({
    required String name,
    required String packageName,
  }) async {
    final result = await _createProjectUseCase(
      name: name,
      packageName: packageName,
    );
    return result.when(
      success: (project) => (project: project, error: null),
      failure: (error) => (project: null, error: error),
    );
  }
}
