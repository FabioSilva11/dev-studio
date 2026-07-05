import 'package:dev_studio/data/services/serialization/project_json_service.dart';
import 'package:dev_studio/data/services/storage/project_storage_service.dart';
import 'package:dev_studio/data/repositories/project/project_repository.dart';
import 'package:dev_studio/data/repositories/project/project_repository_impl.dart';
import 'package:dev_studio/data/repositories/editor/editor_project_repository.dart';
import 'package:dev_studio/data/repositories/editor/editor_project_repository_impl.dart';
import 'package:dev_studio/domain/usecases/projects/list_projects_usecase.dart';
import 'package:dev_studio/domain/usecases/projects/create_project_usecase.dart';
import 'package:dev_studio/domain/usecases/projects/open_project_usecase.dart';
import 'package:dev_studio/domain/usecases/projects/save_project_usecase.dart';
import 'package:dev_studio/domain/usecases/projects/has_storage_access_usecase.dart';
import 'package:dev_studio/domain/usecases/projects/request_storage_access_usecase.dart';
import 'package:dev_studio/domain/usecases/editor/load_editor_project_usecase.dart';
import 'package:dev_studio/domain/usecases/editor/save_editor_project_usecase.dart';
import 'package:dev_studio/domain/usecases/editor/add_widget_usecase.dart';
import 'package:dev_studio/domain/usecases/editor/remove_widget_usecase.dart';
import 'package:dev_studio/domain/usecases/editor/update_widget_props_usecase.dart';
import 'package:dev_studio/ui/pages/editor/viewmodel/editor_viewmodel.dart';
import 'package:dev_studio/ui/pages/projects/viewmodel/project_list_viewmodel.dart';
import 'package:dev_studio/ui/pages/projects/viewmodel/project_create_viewmodel.dart';
import 'package:dev_studio/ui/pages/splash/viewmodel/splash_viewmodel.dart';

class Dependencies {
  const Dependencies._();

  static ProjectJsonService projectJsonService() {
    return const ProjectJsonService();
  }

  static ProjectStorageService projectStorageService() {
    return ProjectStorageService(
      jsonService: projectJsonService(),
    );
  }

  static ProjectRepository projectRepository() {
    return ProjectRepositoryImpl(
      storageService: projectStorageService(),
    );
  }

  static EditorProjectRepository editorProjectRepository() {
    return EditorProjectRepositoryImpl(
      storageService: projectStorageService(),
    );
  }

  static ProjectListViewModel projectListViewModel() {
    return ProjectListViewModel(
      hasStorageAccessUseCase: HasStorageAccessUseCase(projectRepository()),
      listProjectsUseCase: ListProjectsUseCase(projectRepository()),
      requestStorageAccessUseCase: RequestStorageAccessUseCase(projectRepository()),
      openProjectUseCase: OpenProjectUseCase(projectRepository()),
    );
  }

  static ProjectCreateViewModel projectCreateViewModel() {
    return ProjectCreateViewModel(
      createProjectUseCase: CreateProjectUseCase(projectRepository()),
    );
  }

  static EditorViewModel editorViewModel() {
    return EditorViewModel(
      loadEditorProjectUseCase: LoadEditorProjectUseCase(editorProjectRepository()),
      saveEditorProjectUseCase: SaveEditorProjectUseCase(editorProjectRepository()),
      addWidgetUseCase: AddWidgetUseCase(editorProjectRepository()),
      removeWidgetUseCase: RemoveWidgetUseCase(editorProjectRepository()),
      updateWidgetPropsUseCase: UpdateWidgetPropsUseCase(editorProjectRepository()),
    );
  }

  static SplashViewModel splashViewModel() {
    return SplashViewModel();
  }
}
