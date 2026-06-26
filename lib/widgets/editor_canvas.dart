import 'package:flutter/material.dart';

import '../models/editor_project.dart';
import 'editor_palette.dart';

class EditorCanvas extends StatefulWidget {
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

  @override
  State<EditorCanvas> createState() => _EditorCanvasState();
}

class _EditorCanvasState extends State<EditorCanvas> {
  final GlobalKey _canvasKey = GlobalKey();
  final Map<String, Rect> _nodeRects = <String, Rect>{};
  _DropTargetInfo? _hoverTarget;
  bool _dragging = false;

  List<EditorWidgetNode> get _rootWidgets {
    final root = widget.widgets
        .where((w) => w.parentId == 'root' || !_exists(w.parentId))
        .toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    return root;
  }

  bool _exists(String id) {
    if (id == 'root') return true;
    return widget.widgets.any((w) => w.id == id);
  }

  Rect get _canvasRect => Rect.fromLTWH(
        0,
        0,
        widget.canvasWidth * widget.scale,
        widget.canvasHeight * widget.scale,
      );

  @override
  void didUpdateWidget(covariant EditorCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.widgets != widget.widgets) {
      _nodeRects.clear();
      _hoverTarget = null;
      _dragging = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        key: _canvasKey,
        width: widget.canvasWidth * widget.scale,
        height: widget.canvasHeight * widget.scale,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE2E3E8), width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: DragTarget<Object>(
          onWillAcceptWithDetails: (details) => _canAcceptDrag(details.data),
          onMove: _handleDragMove,
          onLeave: (_) => _clearHover(),
          onAcceptWithDetails: _handleDrop,
          builder: (context, candidateData, rejectedData) {
            return Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _GridPainter(widget.scale))),
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => widget.onSelect(null),
                    child: Padding(
                      padding: EdgeInsets.all(8 * widget.scale),
                      child: _buildLayoutList(
                        parentId: 'root',
                        children: _rootWidgets,
                        orientation: 'vertical',
                        isRoot: true,
                      ),
                    ),
                  ),
                ),
                if (widget.widgets.isEmpty && !_dragging)
                  const IgnorePointer(
                    child: Center(
                      child: Text(
                        'Drag a view here',
                        style: TextStyle(color: Color(0xFF8E8E93)),
                      ),
                    ),
                  ),
                if (_hoverTarget != null) _buildDropHighlight(_hoverTarget!),
              ],
            );
          },
        ),
      ),
    );
  }

  bool _canAcceptDrag(Object data) {
    return data is PaletteDragData ||
        data is EditorWidgetType ||
        (data is String && widget.widgets.any((item) => item.id == data));
  }

  void _handleDragMove(DragTargetDetails<Object> details) {
    final local = _globalToCanvas(details.offset);
    if (local == null) return;
    final target = _findDropTarget(local, details.data);
    if (target != _hoverTarget || !_dragging) {
      setState(() {
        _dragging = true;
        _hoverTarget = target;
      });
    }
  }

  void _handleDrop(DragTargetDetails<Object> details) {
    final local = _globalToCanvas(details.offset);
    final target = _hoverTarget ??
        (local == null ? null : _findDropTarget(local, details.data)) ??
        _DropTargetInfo(
          parentId: 'root',
          index: _rootWidgets.length,
          depth: 0,
          parentRect: _canvasRect,
          orientation: 'vertical',
        );

    final data = details.data;
    if (data is PaletteDragData) {
      widget.onAddWidget(data.type, target.parentId, target.index);
    } else if (data is EditorWidgetType) {
      widget.onAddWidget(data, target.parentId, target.index);
    } else if (data is String) {
      widget.onMoveWidget(data, target.parentId, target.index);
    }

    _clearHover();
  }

  Offset? _globalToCanvas(Offset global) {
    final canvasContext = _canvasKey.currentContext;
    final renderObject = canvasContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;
    return renderObject.globalToLocal(global);
  }

  void _clearHover() {
    if (!_dragging && _hoverTarget == null) return;
    if (!mounted) return;
    setState(() {
      _dragging = false;
      _hoverTarget = null;
    });
  }

  _DropTargetInfo? _findDropTarget(Offset point, Object data) {
    if (!_canvasRect.contains(point)) return null;

    var best = _DropTargetInfo(
      parentId: 'root',
      index: _indexForParent('root', point, data),
      depth: 0,
      parentRect: _canvasRect,
      orientation: 'vertical',
    );

    for (final node in widget.widgets) {
      if (!_isLayoutNode(node)) continue;
      if (data is String && (node.id == data || _isDescendantOf(node.id, data))) continue;
      final rect = _nodeRects[node.id];
      if (rect == null || !rect.contains(point)) continue;
      final depth = _depthOf(node.id);
      if (depth >= best.depth) {
        best = _DropTargetInfo(
          parentId: node.id,
          index: _indexForParent(node.id, point, data),
          depth: depth,
          parentRect: rect,
          orientation: _orientationForParent(node.id),
        );
      }
    }

    return best;
  }

  int _indexForParent(String parentId, Offset point, Object dragData) {
    final children = _childrenOf(parentId)
        .where((child) => dragData is! String || (child.id != dragData && !_isDescendantOf(child.id, dragData)))
        .toList();
    if (children.isEmpty) return 0;

    final orientation = _orientationForParent(parentId);
    if (orientation == 'free') return children.length;

    for (var i = 0; i < children.length; i++) {
      final rect = _nodeRects[children[i].id];
      if (rect == null) continue;
      final beforeCenter = orientation == 'horizontal'
          ? point.dx < rect.center.dx
          : point.dy < rect.center.dy;
      if (beforeCenter) return i;
    }
    return children.length;
  }

  Widget _buildDropHighlight(_DropTargetInfo target) {
    final rect = _highlightRectFor(target).intersect(_canvasRect);
    final isInsertionLine = target.orientation != 'free' &&
        (rect.height <= 8 || rect.width <= 8) &&
        _childrenOf(target.parentId).isNotEmpty;

    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: IgnorePointer(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          decoration: BoxDecoration(
            color: isInsertionLine
                ? widget.accentColor
                : widget.accentColor.withValues(alpha: 0.10),
            border: isInsertionLine
                ? null
                : Border.all(color: widget.accentColor, width: 1.5),
            borderRadius: BorderRadius.circular(isInsertionLine ? 3 : 8),
          ),
        ),
      ),
    );
  }

  Rect _highlightRectFor(_DropTargetInfo target) {
    final parentRect = target.parentRect.deflate(4 * widget.scale);
    final children = _childrenOf(target.parentId)
        .where((child) => _nodeRects.containsKey(child.id))
        .toList();

    if (target.orientation == 'free' || children.isEmpty) {
      return parentRect;
    }

    if (target.orientation == 'horizontal') {
      double x;
      if (target.index <= 0) {
        x = _nodeRects[children.first.id]?.left ?? parentRect.left;
      } else if (target.index >= children.length) {
        x = _nodeRects[children.last.id]?.right ?? parentRect.right;
      } else {
        final prev = _nodeRects[children[target.index - 1].id];
        final next = _nodeRects[children[target.index].id];
        x = prev != null && next != null ? (prev.right + next.left) / 2 : parentRect.left;
      }
      return Rect.fromLTWH(x - 2, parentRect.top, 4, parentRect.height);
    }

    double y;
    if (target.index <= 0) {
      y = _nodeRects[children.first.id]?.top ?? parentRect.top;
    } else if (target.index >= children.length) {
      y = _nodeRects[children.last.id]?.bottom ?? parentRect.bottom;
    } else {
      final prev = _nodeRects[children[target.index - 1].id];
      final next = _nodeRects[children[target.index].id];
      y = prev != null && next != null ? (prev.bottom + next.top) / 2 : parentRect.top;
    }
    return Rect.fromLTWH(parentRect.left, y - 2, parentRect.width, 4);
  }

  List<EditorWidgetNode> _childrenOf(String parentId) {
    final list = parentId == 'root'
        ? _rootWidgets
        : widget.widgets.where((w) => w.parentId == parentId).toList();
    list.sort((a, b) => a.index.compareTo(b.index));
    return list;
  }

  String _orientationForParent(String parentId) {
    if (parentId == 'root') return 'vertical';
    final parent = widget.widgets.where((item) => item.id == parentId).firstOrNull;
    if (parent == null) return 'vertical';
    if (parent.type == EditorWidgetType.relativeLayout) return 'free';
    if (parent.type == EditorWidgetType.horizontalScroll) return 'horizontal';
    return parent.orientation == 'horizontal' ? 'horizontal' : 'vertical';
  }

  int _depthOf(String id) {
    var depth = 0;
    var current = widget.widgets.where((item) => item.id == id).firstOrNull;
    final visited = <String>{};
    while (current != null && current.parentId != 'root' && visited.add(current.id)) {
      depth++;
      current = widget.widgets.where((item) => item.id == current!.parentId).firstOrNull;
    }
    return depth + 1;
  }

  bool _isDescendantOf(String candidateId, String ancestorId) {
    var current = widget.widgets.where((item) => item.id == candidateId).firstOrNull;
    final visited = <String>{};
    while (current != null && current.parentId != 'root' && visited.add(current.id)) {
      if (current.parentId == ancestorId) return true;
      current = widget.widgets.where((item) => item.id == current!.parentId).firstOrNull;
    }
    return false;
  }

  Widget _buildLayoutList({
    required String parentId,
    required List<EditorWidgetNode> children,
    required String orientation,
    bool isRoot = false,
  }) {
    if (orientation == 'horizontal') {
      // If any child uses match_parent width, Expanded needs MainAxisSize.max so the Row
      // has a finite width to allocate. Otherwise Expanded + unbounded incoming width → error.
      final hasMatchParentWidth = children.any((child) => child.width == -1);
      return Row(
        mainAxisSize: (isRoot || hasMatchParentWidth) ? MainAxisSize.max : MainAxisSize.min,
        // stretch propagates the Row's own height to cross-axis match_parent children (height==-1).
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children.map((child) {
          Widget w = _buildWidgetNode(child);
          // Expanded bounds the double.infinity width from _resolveWidth to the Row's finite width.
          if (child.width == -1) w = Expanded(child: w);
          return w;
        }).toList(),
      );
    }

    if (orientation == 'free') {
      return Stack(
        clipBehavior: Clip.none,
        children: children.map((child) {
          return Positioned(
            left: child.x * widget.scale,
            top: child.y * widget.scale,
            child: _buildWidgetNode(child),
          );
        }).toList(),
      );
    }

    // Vertical Column
    final hasMatchParentHeight = children.any((child) => child.height == -1);
    return Column(
      mainAxisSize: (isRoot || hasMatchParentHeight) ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children.map((child) {
        Widget w = _buildWidgetNode(child);
        // Expanded bounds the double.infinity height from _resolveHeight to the Column's finite height.
        if (child.height == -1) w = Expanded(child: w);
        return w;
      }).toList(),
    );
  }

  Widget _buildWidgetNode(EditorWidgetNode node) {
    final selected = node.id == widget.selectedWidgetId;
    final isContainer = _isLayoutNode(node);
    final parentOrientation = _orientationForParent(node.parentId);
    final children = _childrenOf(node.id);

    final widthVal = _resolveWidth(node.width, parentOrientation);
    final heightVal = _resolveHeight(node.height, parentOrientation);

    Widget content = _EditorNodePreview(
      node: node,
      scale: widget.scale,
      accentColor: widget.accentColor,
      childrenWidget: isContainer
          ? _buildLayoutList(
              parentId: node.id,
              children: children,
              orientation: _orientationForParent(node.id),
            )
          : null,
    );

    content = ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: isContainer ? 72 * widget.scale : 24 * widget.scale,
        minHeight: isContainer ? 48 * widget.scale : 24 * widget.scale,
      ),
      child: content,
    );

    content = Padding(
      padding: EdgeInsets.only(
        left: node.marginLeft * widget.scale,
        top: node.marginTop * widget.scale,
        right: node.marginRight * widget.scale,
        bottom: node.marginBottom * widget.scale,
      ),
      child: content,
    );

    final nodeWidget = _measureNode(
      node.id,
      SizedBox(width: widthVal, height: heightVal, child: content),
    );

    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: LongPressDraggable<String>(
        data: node.id,
        delay: const Duration(milliseconds: 120),
        feedback: Material(
          color: Colors.transparent,
          child: Opacity(
            opacity: 0.65,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: widget.accentColor.withValues(alpha: 0.16),
                border: Border.all(color: widget.accentColor, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                node.id,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.22, child: nodeWidget),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => widget.onSelect(node.id),
          onDoubleTap: () {
            widget.onSelect(node.id);
            widget.onEditProperties();
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              nodeWidget,
              if (selected)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        color: widget.accentColor.withValues(alpha: 0.10),
                        border: Border.all(color: widget.accentColor, width: 2),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _measureNode(String id, Widget child) {
    return Builder(
      builder: (context) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final canvasObject = _canvasKey.currentContext?.findRenderObject();
          final nodeObject = context.findRenderObject();
          if (canvasObject is! RenderBox || nodeObject is! RenderBox) return;
          if (!canvasObject.hasSize || !nodeObject.hasSize) return;
          final offset = nodeObject.localToGlobal(Offset.zero, ancestor: canvasObject);
          _nodeRects[id] = offset & nodeObject.size;
        });
        return child;
      },
    );
  }

  double? _resolveWidth(double value, String parentOrientation) {
    // -1 = match_parent.
    // In Row (horizontal main-axis): Expanded in _buildLayoutList bounds it to a finite width,
    //   then SizedBox(double.infinity) clamps to that finite value via BoxConstraints.enforce.
    // In Column cross-axis: CrossAxisAlignment.stretch provides a finite tight width; same clamp applies.
    // Never left unguarded — always wrapped by Expanded or by Column.stretch.
    if (value == -1) return double.infinity;
    if (value == -2) return null; // wrap_content
    return value * widget.scale;
  }

  double? _resolveHeight(double value, String parentOrientation) {
    // -1 = match_parent.
    // In Column (vertical main-axis): Expanded in _buildLayoutList bounds it to a finite height.
    // In Row cross-axis: Row does NOT bound height unless CrossAxisAlignment.stretch is used
    //   AND the Row itself has a finite height constraint. Using double.infinity here crashes
    //   whenever the Row has no bounded height parent. Return null (wrap_content) for safety;
    //   Row.crossAxisAlignment.stretch (set in _buildLayoutList) will propagate a real height
    //   when available.
    if (value == -1) {
      if (parentOrientation == 'vertical') return double.infinity; // Expanded makes it finite
      return null; // Row cross-axis: null prevents infinite-constraint crash
    }
    if (value == -2) return null; // wrap_content
    return value * widget.scale;
  }

  bool _isLayoutNode(EditorWidgetNode node) => switch (node.type) {
        EditorWidgetType.linearLayout ||
        EditorWidgetType.relativeLayout ||
        EditorWidgetType.horizontalScroll ||
        EditorWidgetType.scrollView ||
        EditorWidgetType.cardView ||
        EditorWidgetType.textInputLayout ||
        EditorWidgetType.swipeRefresh ||
        EditorWidgetType.collapsingToolbar ||
        EditorWidgetType.radioGroup => true,
        _ => false,
      };
}

class _DropTargetInfo {
  const _DropTargetInfo({
    required this.parentId,
    required this.index,
    required this.depth,
    required this.parentRect,
    required this.orientation,
  });

  final String parentId;
  final int index;
  final int depth;
  final Rect parentRect;
  final String orientation;

  @override
  bool operator ==(Object other) {
    return other is _DropTargetInfo &&
        other.parentId == parentId &&
        other.index == index &&
        other.depth == depth &&
        other.parentRect == parentRect &&
        other.orientation == orientation;
  }

  @override
  int get hashCode => Object.hash(parentId, index, depth, parentRect, orientation);
}

class _GridPainter extends CustomPainter {
  const _GridPainter(this.scale);

  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x09000000)
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
  bool shouldRepaint(covariant _GridPainter oldDelegate) => oldDelegate.scale != scale;
}

class _EditorNodePreview extends StatelessWidget {
  const _EditorNodePreview({
    required this.node,
    required this.scale,
    required this.accentColor,
    this.childrenWidget,
  });

  final EditorWidgetNode node;
  final double scale;
  final Color accentColor;
  final Widget? childrenWidget;

  @override
  Widget build(BuildContext context) {
    final background = Color(node.backgroundColor & 0xFFFFFFFF);
    final foreground = Color(node.textColor & 0xFFFFFFFF);
    final radius = BorderRadius.circular(node.borderRadius * scale);
    final textStyle = TextStyle(color: foreground, fontSize: node.fontSize * scale);

    final innerContent = Padding(
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
            color: childrenWidget != null ? const Color(0xFFD6D8E5) : const Color(0x22000000),
          ),
          borderRadius: radius,
        ),
        child: childrenWidget == null
            ? innerContent
            : Stack(
                children: [
                  Positioned.fill(child: innerContent),
                  Positioned(
                    left: 4 * scale,
                    top: 2 * scale,
                    child: Text(
                      node.id.isEmpty ? node.type.label : node.id,
                      style: TextStyle(
                        color: accentColor.withValues(alpha: 0.75),
                        fontSize: 10 * scale,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildBasicWidgetContent(TextStyle textStyle) {
    final foreground = Color(node.textColor & 0xFFFFFFFF);
    return switch (node.type) {
      EditorWidgetType.button || EditorWidgetType.materialButton => Center(
          child: Text(node.text.isEmpty ? node.type.label : node.text, style: textStyle),
        ),
      EditorWidgetType.textView => Align(
          alignment: Alignment.centerLeft,
          child: Text(node.text.isEmpty ? 'TextView' : node.text, style: textStyle),
        ),
      EditorWidgetType.editText => Align(
          alignment: Alignment.centerLeft,
          child: Text(
            node.text.isEmpty ? (node.hint.isEmpty ? 'EditText' : node.hint) : node.text,
            style: textStyle.copyWith(
              color: node.text.isEmpty ? foreground.withValues(alpha: 0.45) : foreground,
            ),
          ),
        ),
      EditorWidgetType.imageView || EditorWidgetType.circleImageView => Center(
          child: Icon(
            node.type == EditorWidgetType.circleImageView ? Icons.account_circle_outlined : Icons.image_outlined,
            color: foreground.withValues(alpha: 0.55),
            size: 36 * scale,
          ),
        ),
      EditorWidgetType.checkBox => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_box_outline_blank, size: 22 * scale, color: foreground),
            SizedBox(width: 6 * scale),
            Text(node.text.isEmpty ? 'CheckBox' : node.text, style: textStyle),
          ],
        ),
      EditorWidgetType.radioButton => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.radio_button_unchecked, size: 22 * scale, color: foreground),
            SizedBox(width: 6 * scale),
            Text(node.text.isEmpty ? 'RadioButton' : node.text, style: textStyle),
          ],
        ),
      EditorWidgetType.switchView => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(node.text.isEmpty ? 'Switch' : node.text, style: textStyle),
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
      EditorWidgetType.listView || EditorWidgetType.recyclerView || EditorWidgetType.gridView => Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            3,
            (_) => Divider(height: 1, indent: 10 * scale, endIndent: 10 * scale),
          ),
        ),
      EditorWidgetType.floatingButton => Center(
          child: Text(node.text.isEmpty ? '+' : node.text, style: textStyle.copyWith(fontSize: 26 * scale)),
        ),
      _ => Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(iconForWidget(node.type), size: 20 * scale, color: foreground),
              SizedBox(width: 5 * scale),
              Flexible(
                child: Text(
                  node.text.isEmpty ? node.type.label : node.text,
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
