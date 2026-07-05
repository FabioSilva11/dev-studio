import 'package:dev_studio/core/result/result.dart';
import 'package:dev_studio/data/repositories/project/project_repository.dart';
import 'package:dev_studio/domain/common/project/dev_studio_project.dart';

class CreateProjectUseCase {
  final ProjectRepository repository;

  CreateProjectUseCase(this.repository);

  Future<Result<DevStudioProject>> call({
    required String name,
    required String packageName,
  }) async {
    return await repository.createProject(
      name: name,
      packageName: packageName,
    );
  }
}
