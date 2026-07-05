import 'package:dev_studio/core/result/result.dart';
import 'package:dev_studio/data/repositories/editor/editor_project_repository.dart';
import 'package:dev_studio/domain/common/project/dev_studio_project.dart';
import 'package:dev_studio/domain/common/editor/widget_node.dart';

class AddWidgetUseCase {
  final EditorProjectRepository repository;

  AddWidgetUseCase(this.repository);

  Future<Result<DevStudioProject>> call({
    required DevStudioProject project,
    required String screenId,
    required String parentId,
    required WidgetNode widget,
  }) async {
    return await repository.addWidget(
      project: project,
      screenId: screenId,
      parentId: parentId,
      widget: widget,
    );
  }
}
