import 'package:dev_studio/core/result/result.dart';
import 'package:dev_studio/data/repositories/editor/editor_project_repository.dart';
import 'package:dev_studio/domain/common/project/dev_studio_project.dart';

class LoadEditorProjectUseCase {
  final EditorProjectRepository repository;

  LoadEditorProjectUseCase(this.repository);

  Future<Result<DevStudioProject>> call(String projectId) async {
    return await repository.loadProject(projectId);
  }
}
