import 'package:dev_studio/core/result/result.dart';
import 'package:dev_studio/domain/common/project/dev_studio_project.dart';
import 'package:dev_studio/domain/common/editor/editor_screen.dart';
import 'package:dev_studio/domain/common/editor/widget_node.dart';

abstract class EditorProjectRepository {
  Future<Result<DevStudioProject>> loadProject(String projectId);
  Future<Result<bool>> saveProject(DevStudioProject project);
  Future<Result<DevStudioProject>> addWidget({
    required DevStudioProject project,
    required String screenId,
    required String parentId,
    required WidgetNode widget,
  });
  Future<Result<DevStudioProject>> removeWidget({
    required DevStudioProject project,
    required String screenId,
    required String widgetId,
  });
  Future<Result<DevStudioProject>> updateWidgetProps({
    required DevStudioProject project,
    required String screenId,
    required String widgetId,
    required Map<String, Object?> props,
  });
}
