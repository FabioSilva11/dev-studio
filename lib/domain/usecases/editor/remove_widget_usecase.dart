import 'package:dev_studio/core/result/result.dart';
import 'package:dev_studio/data/repositories/editor/editor_project_repository.dart';
import 'package:dev_studio/domain/common/project/dev_studio_project.dart';

class RemoveWidgetUseCase {
  final EditorProjectRepository repository;

  RemoveWidgetUseCase(this.repository);

  Future<Result<DevStudioProject>> call({
    required DevStudioProject project,
    required String screenId,
    required String widgetId,
  }) async {
    return await repository.removeWidget(
      project: project,
      screenId: screenId,
      widgetId: widgetId,
    );
  }
}
