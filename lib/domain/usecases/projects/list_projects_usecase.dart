import 'package:dev_studio/core/result/result.dart';
import 'package:dev_studio/data/repositories/project/project_repository.dart';
import 'package:dev_studio/domain/common/project/project_summary.dart';

class ListProjectsUseCase {
  final ProjectRepository repository;

  ListProjectsUseCase(this.repository);

  Future<Result<List<ProjectSummary>>> call() async {
    return await repository.listProjects();
  }
}
