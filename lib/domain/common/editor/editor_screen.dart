import 'package:dev_studio/domain/common/editor/widget_node.dart';

class DevStudioScreen {
  const DevStudioScreen({
    required this.id,
    required this.name,
    required this.root,
  });

  final String id;
  final String name;
  final WidgetNode root;

  DevStudioScreen copyWith({
    String? id,
    String? name,
    WidgetNode? root,
  }) {
    return DevStudioScreen(
      id: id ?? this.id,
      name: name ?? this.name,
      root: root ?? this.root,
    );
  }
}
