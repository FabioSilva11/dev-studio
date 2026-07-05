import 'package:flutter/foundation.dart';

import 'package:dev_studio/core/result/errors/app_error.dart';
import 'package:dev_studio/domain/common/project/dev_studio_project.dart';
import 'package:dev_studio/domain/common/editor/widget_node.dart';
import 'package:dev_studio/domain/usecases/editor/load_editor_project_usecase.dart';
import 'package:dev_studio/domain/usecases/editor/save_editor_project_usecase.dart';
import 'package:dev_studio/domain/usecases/editor/add_widget_usecase.dart';
import 'package:dev_studio/domain/usecases/editor/remove_widget_usecase.dart';
import 'package:dev_studio/domain/usecases/editor/update_widget_props_usecase.dart';

class EditorViewModel extends ChangeNotifier {
  EditorViewModel({
    required LoadEditorProjectUseCase loadEditorProjectUseCase,
    required SaveEditorProjectUseCase saveEditorProjectUseCase,
    required AddWidgetUseCase addWidgetUseCase,
    required RemoveWidgetUseCase removeWidgetUseCase,
    required UpdateWidgetPropsUseCase updateWidgetPropsUseCase,
  }) : _loadEditorProjectUseCase = loadEditorProjectUseCase,
       _saveEditorProjectUseCase = saveEditorProjectUseCase,
       _addWidgetUseCase = addWidgetUseCase,
       _removeWidgetUseCase = removeWidgetUseCase,
       _updateWidgetPropsUseCase = updateWidgetPropsUseCase;

  final LoadEditorProjectUseCase _loadEditorProjectUseCase;
  final SaveEditorProjectUseCase _saveEditorProjectUseCase;
  final AddWidgetUseCase _addWidgetUseCase;
  final RemoveWidgetUseCase _removeWidgetUseCase;
  final UpdateWidgetPropsUseCase _updateWidgetPropsUseCase;

  DevStudioProject? _project;
  DevStudioProject? get project => _project;

  String? _selectedScreenId;
  String? get selectedScreenId => _selectedScreenId;

  String? _selectedWidgetId;
  String? get selectedWidgetId => _selectedWidgetId;

  Future<({DevStudioProject? project, AppError? error})> loadProject(String projectId) async {
    final result = await _loadEditorProjectUseCase(projectId);
    return result.when(
      success: (project) {
        _project = project;
        if (project.screens.isNotEmpty) {
          _selectedScreenId = project.screens.first.id;
        }
        notifyListeners();
        return (project: project, error: null);
      },
      failure: (error) => (project: null, error: error),
    );
  }

  Future<AppError?> saveProject() async {
    if (_project == null) {
      return AppError(message: 'Nenhum projeto carregado');
    }
    final result = await _saveEditorProjectUseCase(_project!);
    return result.when(
      success: (_) => null,
      failure: (error) => error,
    );
  }

  Future<AppError?> addWidget({
    required String parentId,
    required WidgetNode widget,
  }) async {
    if (_project == null || _selectedScreenId == null) {
      return AppError(message: 'Nenhum projeto ou tela selecionada');
    }
    final result = await _addWidgetUseCase(
      project: _project!,
      screenId: _selectedScreenId!,
      parentId: parentId,
      widget: widget,
    );
    return result.when(
      success: (updatedProject) {
        _project = updatedProject;
        notifyListeners();
        return null;
      },
      failure: (error) => error,
    );
  }

  Future<AppError?> removeWidget(String widgetId) async {
    if (_project == null || _selectedScreenId == null) {
      return AppError(message: 'Nenhum projeto ou tela selecionada');
    }
    final result = await _removeWidgetUseCase(
      project: _project!,
      screenId: _selectedScreenId!,
      widgetId: widgetId,
    );
    return result.when(
      success: (updatedProject) {
        _project = updatedProject;
        if (_selectedWidgetId == widgetId) {
          _selectedWidgetId = null;
        }
        notifyListeners();
        return null;
      },
      failure: (error) => error,
    );
  }

  Future<AppError?> updateWidgetProps({
    required String widgetId,
    required Map<String, Object?> props,
  }) async {
    if (_project == null || _selectedScreenId == null) {
      return AppError(message: 'Nenhum projeto ou tela selecionada');
    }
    final result = await _updateWidgetPropsUseCase(
      project: _project!,
      screenId: _selectedScreenId!,
      widgetId: widgetId,
      props: props,
    );
    return result.when(
      success: (updatedProject) {
        _project = updatedProject;
        notifyListeners();
        return null;
      },
      failure: (error) => error,
    );
  }

  void selectScreen(String screenId) {
    _selectedScreenId = screenId;
    _selectedWidgetId = null;
    notifyListeners();
  }

  void selectWidget(String widgetId) {
    _selectedWidgetId = widgetId;
    notifyListeners();
  }
}
