import 'package:flutter/material.dart';
import '../models/editor_project.dart';
import 'editor_palette.dart'; // to reuse iconForWidget

class EditorCanvas extends StatelessWidget {
  const EditorCanvas({
    super.key,
    required this.widgets,
    required this.selectedWidgetId,
    required this.onSelect,
    required this.onAddWidget,
    required this.onMoveWidget,
    required this.onEditProperties,
    required this.scale,
    required this.accentColor,
    required this.canvasWidth,
    required this.canvasHeight,
  });

  final List<EditorWidgetNode> widgets;
  final String? selectedWidgetId;
  final ValueChanged<String?> onSelect;
  final Function(EditorWidgetType type, String parentId, int index) onAddWidget;
  final Function(String id, String newParentId, int newIndex) onMoveWidget;
  final VoidCallback onEditProperties;
  final double scale;
  final Color accentColor;
  final double canvasWidth;
  final double canvasHeight;

  // Find root widgets (direct children of canvas)
  List<EditorWidgetNode> get _rootWidgets {
    final root = widgets.where((w) => w.parentId == 'root' || !_exists(w.parentId)).toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    return root;
  }

  bool _exists(String id) {
    if (id == 'root') return true;
    return widgets.any((w) => w.id == id);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: canvasWidth * scale,
        height: canvasHeight * scale,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E3E8), width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x16000000),
              blurRadius: 18,
              offset: Offset(0, 7),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Grid background
            Positioned.fill(
              child: CustomPaint(painter: _GridPainter(scale)),
            ),

            // Base Canvas Drop Target & Nested Renderer
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelect(null),
                child: _buildLayoutList(
                  parentId: 'root',
                  children: _rootWidgets,
                  orientation: 'vertical',
                  isRoot: true,
                ),
              ),
            ),

            if (widgets.isEmpty)
              const IgnorePointer(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.touch_app_outlined,
                        size: 42,
                        color: Color(0xFFB1B2BA),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Drag a view here',
                        style: TextStyle(color: Color(0xFF8E8E93)),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Recursive Layout List with drop zones between children
  Widget _buildLayoutList({
    required String parentId,
    required List<EditorWidgetNode> children,
    required String orientation,
    bool isRoot = false,
  }) {
    final isVertical = orientation == 'vertical';

    List<Widget> listItems = [];

    // Add initial drop target
    listItems.add(
      _buildInsertionTarget(parentId: parentId, index: 0, isVertical: isVertical),
    );

    for (int i = 0; i < children.length; i++) {
      final child = children[i];
      listItems.add(
        _buildWidgetNode(child),
      );
      listItems.add(
        _buildInsertionTarget(parentId: parentId, index: i + 1, isVertical: isVertical),
      );
    }

    if (isRoot) {
      return Scrollbar(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: listItems,
          ),
        ),
      );
    }

    if (isVertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: listItems,
      );
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: listItems,
      );
    }
  }

  // Built drop insertion target (horizontal line or vertical line placeholder)
  Widget _buildInsertionTarget({
    required String parentId,
    required int index,
    required bool isVertical,
  }) {
    return DragTarget<Object>(
      onWillAcceptWithDetails: (details) {
        // Prevent dropping a widget inside itself or its descendants
        final data = details.data;
        if (data is String) {
          if (data == parentId || _isDescendantOf(parentId, data)) {
            return false;
          }
        }
        return true;
      },
      onAcceptWithDetails: (details) {
        final data = details.data;
        if (data is EditorWidgetType) {
          onAddWidget(data, parentId, index);
        } else if (data is String) {
          onMoveWidget(data, parentId, index);
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;
        final size = isHovered ? 8.0 : 4.0;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: isVertical ? double.infinity : (isHovered ? 12.0 : 4.0),
          height: isVertical ? (isHovered ? 12.0 : 4.0) : double.infinity,
          margin: EdgeInsets.symmetric(
            horizontal: isVertical ? 0.0 : 2.0,
            vertical: isVertical ? 2.0 : 0.0,
          ),
          decoration: BoxDecoration(
            color: isHovered ? accentColor : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      },
    );
  }

  bool _isDescendantOf(String candidateId, String ancestorId) {
    var current = widgets.where((item) => item.id == candidateId).firstOrNull;
    final visited = <String>{};
    while (current != null && current.parentId != 'root' && visited.add(current.id)) {
      if (current.parentId == ancestorId) return true;
      final pId = current.parentId;
      current = widgets.where((item) => item.id == pId).firstOrNull;
    }
    return false;
  }

  // Individual node widget with selection, double tap, drag & drop
  Widget _buildWidgetNode(EditorWidgetNode node) {
    final selected = node.id == selectedWidgetId;
    final isContainer = _isLayoutNode(node);

    // Filter children of this container
    final children = widgets.where((w) => w.parentId == node.id).toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    // Custom dimensions or wrap content/match parent mapping
    double? widthVal;
    if (node.width == -1) {
      widthVal = double.infinity;
    } else if (node.width == -2) {
      widthVal = null; // Wrap content
    } else {
      widthVal = node.width * scale;
    }

    double? heightVal;
    if (node.height == -1) {
      heightVal = double.infinity;
    } else if (node.height == -2) {
      heightVal = null; // Wrap content
    } else {
      heightVal = node.height * scale;
    }

    Widget content = _EditorNodePreview(
      node: node,
      scale: scale,
      childrenWidget: isContainer
          ? _buildLayoutList(
              parentId: node.id,
              children: children,
              orientation: node.orientation,
            )
          : null,
    );

    // Apply Margins
    content = Padding(
      padding: EdgeInsets.only(
        left: node.marginLeft * scale,
        top: node.marginTop * scale,
        right: node.marginRight * scale,
        bottom: node.marginBottom * scale,
      ),
      child: content,
    );

    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: LongPressDraggable<String>(
        data: node.id,
        delay: const Duration(milliseconds: 120),
        feedback: Material(
          color: Colors.transparent,
          child: Opacity(
            opacity: 0.6,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                border: Border.all(color: accentColor, width: 2),
                borderRadius: BorderRadius.circular(node.borderRadius),
              ),
              child: Text(node.id, style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
        childWhenDragging: const SizedBox.shrink(),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onSelect(node.id),
          onDoubleTap: () {
            onSelect(node.id);
            onEditProperties();
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                width: widthVal,
                height: heightVal,
                child: content,
              ),
              if (selected)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      margin: EdgeInsets.only(
                        left: node.marginLeft * scale,
                        top: node.marginTop * scale,
                        right: node.marginRight * scale,
                        bottom: node.marginBottom * scale,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        border: Border.all(color: accentColor, width: 2),
                        borderRadius: BorderRadius.circular(node.borderRadius * scale),
                      ),
                    ),
                  ),
                ),
              if (selected)
                Positioned(
                  right: (node.marginRight - 4) * scale,
                  top: (node.marginTop - 4) * scale,
                  child: const _SelectionHandle(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isLayoutNode(EditorWidgetNode node) => switch (node.type) {
    EditorWidgetType.linearLayout ||
    EditorWidgetType.relativeLayout ||
    EditorWidgetType.horizontalScroll ||
    EditorWidgetType.scrollView ||
    EditorWidgetType.cardView ||
    EditorWidgetType.textInputLayout ||
    EditorWidgetType.swipeRefresh ||
    EditorWidgetType.collapsingToolbar => true,
    _ => false,
  };
}

class _SelectionHandle extends StatelessWidget {
  const _SelectionHandle();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(color: Color(0xFF6B5CE7), shape: BoxShape.circle),
      child: SizedBox.square(dimension: 10),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter(this.scale);

  final double scale;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x0C000000)
      ..strokeWidth = 1;
    final step = 16 * scale;
    for (double x = step; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) =>
      oldDelegate.scale != scale;
}

class _EditorNodePreview extends StatelessWidget {
  const _EditorNodePreview({
    required this.node,
    required this.scale,
    this.childrenWidget,
  });

  final EditorWidgetNode node;
  final double scale;
  final Widget? childrenWidget;

  @override
  Widget build(BuildContext context) {
    final background = Color(node.backgroundColor & 0xFFFFFFFF);
    final foreground = Color(node.textColor & 0xFFFFFFFF);
    final radius = BorderRadius.circular(node.borderRadius * scale);
    final textStyle = TextStyle(
      color: foreground,
      fontSize: node.fontSize * scale,
    );

    // Apply Padding
    Widget innerContent = Padding(
      padding: EdgeInsets.only(
        left: node.paddingLeft * scale,
        top: node.paddingTop * scale,
        right: node.paddingRight * scale,
        bottom: node.paddingBottom * scale,
      ),
      child: childrenWidget ?? _buildBasicWidgetContent(textStyle),
    );

    return Material(
      color: background,
      elevation: node.elevation,
      shadowColor: Colors.black54,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: childrenWidget != null ? const Color(0xFF9EA6C7) : const Color(0x22000000),
          ),
          borderRadius: radius,
        ),
        child: innerContent,
      ),
    );
  }

  Widget _buildBasicWidgetContent(TextStyle textStyle) {
    final foreground = Color(node.textColor & 0xFFFFFFFF);
    return switch (node.type) {
      EditorWidgetType.button => Center(
        child: Text(node.text, style: textStyle),
      ),
      EditorWidgetType.textView => Align(
        alignment: Alignment.centerLeft,
        child: Text(node.text, style: textStyle),
      ),
      EditorWidgetType.editText => Align(
        alignment: Alignment.centerLeft,
        child: Text(
          node.text.isEmpty ? node.hint : node.text,
          style: textStyle.copyWith(
            color: node.text.isEmpty
                ? foreground.withValues(alpha: 0.45)
                : foreground,
          ),
        ),
      ),
      EditorWidgetType.imageView => Center(
        child: Icon(
          Icons.image_outlined,
          color: foreground.withValues(alpha: 0.55),
          size: 36 * scale,
        ),
      ),
      EditorWidgetType.checkBox => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_box_outline_blank,
            size: 22 * scale,
            color: foreground,
          ),
          SizedBox(width: 6 * scale),
          Text(node.text, style: textStyle),
        ],
      ),
      EditorWidgetType.switchView => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(node.text, style: textStyle),
          SizedBox(width: 8 * scale),
          Icon(Icons.toggle_on, size: 32 * scale, color: const Color(0xFF6B5CE7)),
        ],
      ),
      EditorWidgetType.progressBar => Center(
        child: Padding(
          padding: EdgeInsets.all(10 * scale),
          child: const LinearProgressIndicator(value: 0.55),
        ),
      ),
      EditorWidgetType.listView => Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          3,
          (_) => Divider(height: 1, indent: 10 * scale, endIndent: 10 * scale),
        ),
      ),
      EditorWidgetType.floatingButton => Center(
        child: Text(node.text, style: textStyle.copyWith(fontSize: 26 * scale)),
      ),
      _ => Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              iconForWidget(node.type),
              size: 20 * scale,
              color: foreground,
            ),
            SizedBox(width: 5 * scale),
            Flexible(
              child: Text(
                node.text,
                style: textStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    };
  }
}
