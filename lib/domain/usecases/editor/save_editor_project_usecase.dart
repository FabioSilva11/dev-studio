import 'package:dev_studio/core/result/result.dart';
import 'package:dev_studio/data/repositories/editor/editor_project_repository.dart';
import 'package:dev_studio/domain/common/project/dev_studio_project.dart';

class SaveEditorProjectUseCase {
  final EditorProjectRepository repository;

  SaveEditorProjectUseCase(this.repository);

  Future<Result<bool>> call(DevStudioProject project) async {
    return await repository.saveProject(project);
  }
}
