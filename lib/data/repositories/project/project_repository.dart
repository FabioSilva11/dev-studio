import 'package:dev_studio/core/result/result.dart';
import 'package:dev_studio/domain/common/project/dev_studio_project.dart';
import 'package:dev_studio/domain/common/project/project_summary.dart';

abstract class ProjectRepository {
  Future<Result<List<ProjectSummary>>> listProjects();
  Future<Result<DevStudioProject>> loadProject(String projectId);
  Future<Result<DevStudioProject>> createProject({
    required String name,
    required String packageName,
  });
  Future<Result<bool>> saveProject(DevStudioProject project);
  Future<Result<bool>> deleteProject(String projectId);
  Future<Result<bool>> hasStorageAccess();
  Future<Result<bool>> requestStorageAccess();
}
