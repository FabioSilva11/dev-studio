import 'package:dev_studio/domain/common/editor/widget_type.dart';
import 'package:dev_studio/domain/common/editor/widget_props.dart';

class WidgetNode {
  const WidgetNode({
    required this.id,
    required this.type,
    required this.props,
    required this.children,
  });

  final String id;
  final WidgetType type;
  final WidgetProps props;
  final List<WidgetNode> children;

  WidgetNode copyWith({
    String? id,
    WidgetType? type,
    WidgetProps? props,
    List<WidgetNode>? children,
  }) {
    return WidgetNode(
      id: id ?? this.id,
      type: type ?? this.type,
      props: props ?? this.props,
      children: children ?? this.children,
    );
  }

  WidgetNode? findNode(String nodeId) {
    if (id == nodeId) return this;
    for (final child in children) {
      final found = child.findNode(nodeId);
      if (found != null) return found;
    }
    return null;
  }

  WidgetNode removeChild(String childId) {
    return copyWith(
      children: children.where((child) => child.id != childId).toList(),
    );
  }

  WidgetNode addChild(WidgetNode child) {
    return copyWith(
      children: [...children, child],
    );
  }

  WidgetNode insertChildAt(int index, WidgetNode child) {
    final newChildren = List<WidgetNode>.from(children);
    newChildren.insert(index, child);
    return copyWith(children: newChildren);
  }

  WidgetNode updateNode(String nodeId, WidgetNode Function(WidgetNode) updater) {
    if (id == nodeId) {
      return updater(this);
    }
    return copyWith(
      children: children.map((child) => child.updateNode(nodeId, updater)).toList(),
    );
  }
}
