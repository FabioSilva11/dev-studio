import 'dart:convert';
import 'package:dev_studio/domain/common/project/dev_studio_project.dart';
import 'package:dev_studio/domain/common/editor/editor_screen.dart';
import 'package:dev_studio/domain/common/editor/widget_node.dart';
import 'package:dev_studio/domain/common/editor/widget_type.dart';
import 'package:dev_studio/domain/common/editor/widget_props.dart';
import 'package:dev_studio/domain/common/editor/dev_studio_logic.dart';

class ProjectJsonService {
  const ProjectJsonService();

  Map<String, Object?> toJson(DevStudioProject project) {
    return {
      'schemaVersion': 1,
      'id': project.id,
      'name': project.name,
      'packageName': project.packageName,
      'version': {
        'name': project.version.name,
        'code': project.version.code,
      },
      'theme': {
        'primaryColor': project.theme.primaryColor,
        'backgroundColor': project.theme.backgroundColor,
      },
      'screens': project.screens.map(_screenToJson).toList(),
      'logic': _logicToJson(project.logic),
      'assets': project.assets.map(_assetToJson).toList(),
      'createdAt': project.createdAt.toIso8601String(),
      'updatedAt': project.updatedAt.toIso8601String(),
    };
  }

  String encode(DevStudioProject project) {
    return jsonEncode(toJson(project));
  }

  DevStudioProject fromJson(Map<String, Object?> json) {
    final versionJson = json['version'] as Map<String, Object?>?;
    final themeJson = json['theme'] as Map<String, Object?>?;
    final screensJson = json['screens'] as List? ?? [];
    final logicJson = json['logic'] as Map<String, Object?>?;
    final assetsJson = json['assets'] as List? ?? [];

    return DevStudioProject(
      id: json['id']?.toString() ?? _generateId(),
      name: json['name']?.toString() ?? 'My App',
      packageName: json['packageName']?.toString() ?? 'com.example.myapp',
      version: DevStudioVersion(
        name: versionJson?['name']?.toString() ?? '1.0.0',
        code: (versionJson?['code'] as num?)?.toInt() ?? 1,
      ),
      theme: DevStudioTheme(
        primaryColor: themeJson?['primaryColor']?.toString() ?? '#6750A4',
        backgroundColor: themeJson?['backgroundColor']?.toString() ?? '#FFFFFF',
      ),
      screens: screensJson
          .map((item) => _screenFromJson(item as Map<String, Object?>?))
          .toList(),
      logic: logicJson != null ? _logicFromJson(logicJson) : const DevStudioLogic(events: []),
      assets: assetsJson
          .map((item) => _assetFromJson(item as Map<String, Object?>?))
          .toList(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  DevStudioProject decode(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, Object?>;
    return fromJson(json);
  }

  Map<String, Object?> _screenToJson(DevStudioScreen screen) {
    return {
      'id': screen.id,
      'name': screen.name,
      'root': _widgetToJson(screen.root),
    };
  }

  DevStudioScreen _screenFromJson(Map<String, Object?>? json) {
    if (json == null) {
      return DevStudioScreen(
        id: _generateId(),
        name: 'Home',
        root: _createDefaultRootWidget(),
      );
    }
    final rootJson = json['root'] as Map<String, Object?>?;
    return DevStudioScreen(
      id: json['id']?.toString() ?? _generateId(),
      name: json['name']?.toString() ?? 'Home',
      root: rootJson != null ? _widgetFromJson(rootJson) : _createDefaultRootWidget(),
    );
  }

  Map<String, Object?> _widgetToJson(WidgetNode widget) {
    return {
      'id': widget.id,
      'type': widget.type.type,
      'props': widget.props.toJson(),
      'children': widget.children.map(_widgetToJson).toList(),
    };
  }

  WidgetNode _widgetFromJson(Map<String, Object?> json) {
    final childrenJson = json['children'] as List? ?? [];
    final propsJson = json['props'] as Map<String, Object?>?;
    return WidgetNode(
      id: json['id']?.toString() ?? _generateId(),
      type: WidgetType.fromString(json['type']?.toString() ?? 'container'),
      props: propsJson != null ? WidgetProps.fromJson(propsJson) : const WidgetProps(),
      children: childrenJson
          .map((item) => _widgetFromJson(item as Map<String, Object?>))
          .toList(),
    );
  }

  Map<String, Object?> _logicToJson(DevStudioLogic logic) {
    return {
      'events': logic.events.map(_eventToJson).toList(),
    };
  }

  DevStudioLogic _logicFromJson(Map<String, Object?> json) {
    final eventsJson = json['events'] as List? ?? [];
    return DevStudioLogic(
      events: eventsJson
          .map((item) => _eventFromJson(item as Map<String, Object?>?))
          .toList(),
    );
  }

  Map<String, Object?> _eventToJson(DevStudioEvent event) {
    return {
      'id': event.id,
      'target': event.target,
      'trigger': event.trigger,
      'blocks': event.blocks.map(_blockToJson).toList(),
    };
  }

  DevStudioEvent _eventFromJson(Map<String, Object?>? json) {
    if (json == null) {
      return DevStudioEvent(
        id: _generateId(),
        target: 'Activity',
        trigger: 'onCreate',
        blocks: [],
      );
    }
    final blocksJson = json['blocks'] as List? ?? [];
    return DevStudioEvent(
      id: json['id']?.toString() ?? _generateId(),
      target: json['target']?.toString() ?? 'Activity',
      trigger: json['trigger']?.toString() ?? 'onCreate',
      blocks: blocksJson
          .map((item) => _blockFromJson(item as Map<String, Object?>?))
          .toList(),
    );
  }

  Map<String, Object?> _blockToJson(DevStudioBlock block) {
    return {
      'id': block.id,
      'type': block.type,
      'props': block.props,
      'inputs': block.inputs,
      'children': block.children.map(_blockToJson).toList(),
    };
  }

  DevStudioBlock _blockFromJson(Map<String, Object?>? json) {
    if (json == null) {
      return DevStudioBlock(
        id: _generateId(),
        type: 'showMessage',
        props: const {},
        inputs: const {},
        children: [],
      );
    }
    final childrenJson = json['children'] as List? ?? [];
    return DevStudioBlock(
      id: json['id']?.toString() ?? _generateId(),
      type: json['type']?.toString() ?? 'showMessage',
      props: (json['props'] as Map<String, Object?>?) ?? const {},
      inputs: (json['inputs'] as Map<String, Object?>?) ?? const {},
      children: childrenJson
          .map((item) => _blockFromJson(item as Map<String, Object?>?))
          .toList(),
    );
  }

  Map<String, Object?> _assetToJson(DevStudioAsset asset) {
    return {
      'id': asset.id,
      'name': asset.name,
      'type': asset.type,
      'path': asset.path,
    };
  }

  DevStudioAsset _assetFromJson(Map<String, Object?>? json) {
    if (json == null) {
      return DevStudioAsset(
        id: _generateId(),
        name: '',
        type: '',
        path: '',
      );
    }
    return DevStudioAsset(
      id: json['id']?.toString() ?? _generateId(),
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      path: json['path']?.toString() ?? '',
    );
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  WidgetNode _createDefaultRootWidget() {
    return WidgetNode(
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
    );
  }
}
