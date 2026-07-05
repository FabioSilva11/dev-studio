import 'package:dev_studio/core/result/result.dart';
import 'package:dev_studio/data/repositories/project/project_repository.dart';
import 'package:dev_studio/domain/common/project/dev_studio_project.dart';

class OpenProjectUseCase {
  final ProjectRepository repository;

  OpenProjectUseCase(this.repository);

  Future<Result<DevStudioProject>> call(String projectId) async {
    return await repository.loadProject(projectId);
  }
}
