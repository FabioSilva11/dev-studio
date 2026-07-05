import 'package:dev_studio/core/result/result.dart';
import 'package:dev_studio/data/repositories/project/project_repository.dart';
import 'package:dev_studio/data/services/storage/project_storage_service.dart';
import 'package:dev_studio/domain/common/project/dev_studio_project.dart';
import 'package:dev_studio/domain/common/project/project_summary.dart';
import 'package:dev_studio/domain/common/editor/editor_screen.dart';
import 'package:dev_studio/domain/common/editor/widget_node.dart';
import 'package:dev_studio/domain/common/editor/widget_type.dart';
import 'package:dev_studio/domain/common/editor/widget_props.dart';
import 'package:dev_studio/domain/common/editor/dev_studio_logic.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  final ProjectStorageService storageService;

  ProjectRepositoryImpl({
    required this.storageService,
  });

  @override
  Future<Result<List<ProjectSummary>>> listProjects() async {
    try {
      final projects = await storageService.listProjects();
      return Result.success(projects);
    } catch (e) {
      return Result.failure(AppError(message: 'Erro ao listar projetos'));
    }
  }

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
  Future<Result<DevStudioProject>> createProject({
    required String name,
    required String packageName,
  }) async {
    try {
      final now = DateTime.now();
      final projectId = 'project_${now.millisecondsSinceEpoch}';
      
      final project = DevStudioProject(
        id: projectId,
        name: name,
        packageName: packageName,
        version: const DevStudioVersion(name: '1.0.0', code: 1),
        theme: const DevStudioTheme(
          primaryColor: '#6750A4',
          backgroundColor: '#FFFFFF',
        ),
        screens: [
          DevStudioScreen(
            id: 'screen_home',
            name: 'Home',
            root: WidgetNode(
              id: 'root',
              type: WidgetType.column,
              props: const WidgetProps(
                padding: 16.0,
                backgroundColor: '#FFFFFF',
              ),
              children: [
                WidgetNode(
                  id: 'text_1',
                  type: WidgetType.text,
                  props: const WidgetProps(
                    text: 'Olá, Dev Studio',
                    fontSize: 22.0,
                    color: '#1C1C1E',
                  ),
                  children: [],
                ),
              ],
            ),
          ),
        ],
        logic: const DevStudioLogic(events: []),
        assets: [],
        createdAt: now,
        updatedAt: now,
      );

      final saved = await storageService.saveProject(project);
      if (!saved) {
        return Result.failure(AppError(message: 'Erro ao salvar projeto'));
      }
      
      return Result.success(project);
    } catch (e) {
      return Result.failure(AppError(message: 'Erro ao criar projeto'));
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
  Future<Result<bool>> deleteProject(String projectId) async {
    try {
      final deleted = await storageService.deleteProject(projectId);
      return Result.success(deleted);
    } catch (e) {
      return Result.failure(AppError(message: 'Erro ao excluir projeto'));
    }
  }

  @override
  Future<Result<bool>> hasStorageAccess() async {
    try {
      final hasAccess = await storageService.hasStorageAccess();
      return Result.success(hasAccess);
    } catch (e) {
      return Result.failure(AppError(message: 'Erro ao verificar acesso'));
    }
  }

  @override
  Future<Result<bool>> requestStorageAccess() async {
    try {
      final granted = await storageService.requestStorageAccess();
      return Result.success(granted);
    } catch (e) {
      return Result.failure(AppError(message: 'Erro ao solicitar acesso'));
    }
  }
}
