import 'package:dev_studio/core/result/result.dart';
import 'package:dev_studio/data/repositories/editor/editor_project_repository.dart';
import 'package:dev_studio/data/services/storage/project_storage_service.dart';
import 'package:dev_studio/domain/common/project/dev_studio_project.dart';
import 'package:dev_studio/domain/common/editor/editor_screen.dart';
import 'package:dev_studio/domain/common/editor/widget_node.dart';
import 'package:dev_studio/domain/common/editor/widget_props.dart';

class EditorProjectRepositoryImpl implements EditorProjectRepository {
  final ProjectStorageService storageService;

  EditorProjectRepositoryImpl({
    required this.storageService,
  });

  @override
  Future<Result<DevStudioProject>> loadProject(String projectId) async {
    try {
      final project = await storageService.loadProject(projectId);
      if (project == null) {
        return Result.failure(AppError(message: 'Projeto não encontrado'));
      }
      return Result.success(project);
    } catch (e) {
      return Result.failure(AppError(message: 'Erro ao carregar projeto'));
    }
  }

  @override
  Future<Result<bool>> saveProject(DevStudioProject project) async {
    try {
      final updatedProject = project.copyWith(updatedAt: DateTime.now());
      final saved = await storageService.saveProject(updatedProject);
      return Result.success(saved);
    } catch (e) {
      return Result.failure(AppError(message: 'Erro ao salvar projeto'));
    }
  }

  @override
  Future<Result<DevStudioProject>> addWidget({
    required DevStudioProject project,
    required String screenId,
    required String parentId,
    required WidgetNode widget,
  }) async {
    try {
      final updatedScreens = project.screens.map((screen) {
        if (screen.id != screenId) return screen;
        
        final updatedRoot = screen.root.updateNode(parentId, (node) {
          return node.addChild(widget);
        });
        
        return screen.copyWith(root: updatedRoot);
      }).toList();

      final updatedProject = project.copyWith(
        screens: updatedScreens,
        updatedAt: DateTime.now(),
      );

      return Result.success(updatedProject);
    } catch (e) {
      return Result.failure(AppError(message: 'Erro ao adicionar widget'));
    }
  }

  @override
  Future<Result<DevStudioProject>> removeWidget({
    required DevStudioProject project,
    required String screenId,
    required String widgetId,
  }) async {
    try {
      final updatedScreens = project.screens.map((screen) {
        if (screen.id != screenId) return screen;
        
        WidgetNode removeFromNode(WidgetNode node) {
          if (node.id == widgetId) return node;
          return node.copyWith(
            children: node.children
                .where((child) => child.id != widgetId)
                .map(removeFromNode)
                .toList(),
          );
        }
        
        final updatedRoot = removeFromNode(screen.root);
        return screen.copyWith(root: updatedRoot);
      }).toList();

      final updatedProject = project.copyWith(
        screens: updatedScreens,
        updatedAt: DateTime.now(),
      );

      return Result.success(updatedProject);
    } catch (e) {
      return Result.failure(AppError(message: 'Erro ao remover widget'));
    }
  }

  @override
  Future<Result<DevStudioProject>> updateWidgetProps({
    required DevStudioProject project,
    required String screenId,
    required String widgetId,
    required Map<String, Object?> props,
  }) async {
    try {
      final updatedScreens = project.screens.map((screen) {
        if (screen.id != screenId) return screen;
        
        final updatedRoot = screen.root.updateNode(widgetId, (node) {
          final newProps = WidgetProps.fromJson({
            ...node.props.toJson(),
            ...props,
          });
          return node.copyWith(props: newProps);
        });
        
        return screen.copyWith(root: updatedRoot);
      }).toList();

      final updatedProject = project.copyWith(
        screens: updatedScreens,
        updatedAt: DateTime.now(),
      );

      return Result.success(updatedProject);
    } catch (e) {
      return Result.failure(AppError(message: 'Erro ao atualizar propriedades'));
    }
  }
}
