import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/editor_project.dart';
import 'models/project_item.dart';
import 'services/sketchware_project_service.dart';

const _editorAccent = Color(0xFF6B5CE7);
const _editorBackground = Color(0xFFF5F6F8);
const _editorBorder = Color(0xFFE2E3E8);
const _canvasWidth = 360.0;
const _canvasHeight = 640.0;

class ProjectEditorScreen extends StatefulWidget {
  const ProjectEditorScreen({
    super.key,
    required this.project,
    this.projectService = const SketchwareProjectService(),
  });

  final ProjectItem project;
  final SketchwareProjectService projectService;

  @override
  State<ProjectEditorScreen> createState() => _ProjectEditorScreenState();
}

class _ProjectEditorScreenState extends State<ProjectEditorScreen>
    with SingleTickerProviderStateMixin {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _canvasKey = GlobalKey();
  late final TabController _tabController;

  EditorProjectData _projectData = const EditorProjectData();
  List<EditorWidgetNode> _widgets = [];
  List<EditorEventItem> _events = [];
  List<EditorComponentItem> _components = [];
  Map<String, String> _strings = {};
  final List<List<EditorWidgetNode>> _undoStack = [];
  final List<List<EditorWidgetNode>> _redoStack = [];

  String? _selectedWidgetId;
  String? _draggingWidgetId;
  bool _loading = true;
  bool _saving = false;
  bool _dirty = false;
  bool _deleteHover = false;
  bool _showFavoritePalette = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadProject();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProject() async {
    try {
      final raw = await widget.projectService.loadEditorProject(
        widget.project.id,
      );
      final loaded = raw.isEmpty
          ? EditorProjectData(strings: {'app_name': widget.project.appName})
          : EditorProjectData.fromJson(raw);
      final loadedStrings = Map<String, String>.of(loaded.strings)
        ..putIfAbsent('app_name', () => widget.project.appName);
      final loadedEvents = List<EditorEventItem>.of(loaded.events);
      if (loadedEvents.isEmpty) {
        loadedEvents.add(
          const EditorEventItem(target: 'Activity', name: 'onCreate'),
        );
      }
      if (!mounted) return;
      setState(() {
        _projectData = loaded;
        _widgets = List.of(loaded.widgets);
        _events = loadedEvents;
        _components = List.of(loaded.components);
        _strings = loadedStrings;
        _loading = false;
      });
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = error.message ?? 'Unable to open the project editor.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = error.toString();
      });
    }
  }

  EditorProjectData get _currentData => EditorProjectData(
    fileName: _projectData.fileName,
    widgets: _widgets,
    events: _events,
    components: _components,
    strings: _strings,
  );

  Future<void> _saveProject() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.projectService.saveEditorProject(
        widget.project.id,
        _currentData.toJson(),
      );
      if (!mounted) return;
      setState(() {
        _saving = false;
        _dirty = false;
        _projectData = _currentData;
      });
      _showMessage('Project saved');
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage(error.message ?? 'Unable to save the project.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage(error.toString());
    }
  }

  Future<void> _confirmExit() async {
    if (!_dirty) {
      Navigator.pop(context);
      return;
    }
    final action = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Unsaved changes'),
        content: const Text('Save the layout changes before leaving?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'discard'),
            child: const Text('Discard'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, 'save'),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (action == 'save') {
      await _saveProject();
      if (mounted && !_dirty) Navigator.pop(context);
    } else if (action == 'discard') {
      setState(() => _dirty = false);
      Navigator.pop(context);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _rememberWidgets() {
    _undoStack.add(List.of(_widgets));
    if (_undoStack.length > 30) _undoStack.removeAt(0);
    _redoStack.clear();
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    setState(() {
      _redoStack.add(List.of(_widgets));
      _widgets = _undoStack.removeLast();
      _selectedWidgetId = null;
      _dirty = true;
    });
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    setState(() {
      _undoStack.add(List.of(_widgets));
      _widgets = _redoStack.removeLast();
      _selectedWidgetId = null;
      _dirty = true;
    });
  }

  EditorWidgetNode? get _selectedWidget {
    for (final widgetNode in _widgets) {
      if (widgetNode.id == _selectedWidgetId) return widgetNode;
    }
    return null;
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

  Offset _absolutePosition(EditorWidgetNode node, [Set<String>? visited]) {
    final checked = visited ?? <String>{};
    if (!checked.add(node.id) || node.parentId == 'root') {
      return Offset(node.x, node.y);
    }
    final parent = _widgets
        .where((item) => item.id == node.parentId)
        .firstOrNull;
    if (parent == null) return Offset(node.x, node.y);
    return _absolutePosition(parent, checked) + Offset(node.x, node.y);
  }

  bool _isDescendantOf(String candidateId, String ancestorId) {
    var current = _widgets.where((item) => item.id == candidateId).firstOrNull;
    final visited = <String>{};
    while (current != null &&
        current.parentId != 'root' &&
        visited.add(current.id)) {
      if (current.parentId == ancestorId) return true;
      final parentId = current.parentId;
      current = _widgets.where((item) => item.id == parentId).firstOrNull;
    }
    return false;
  }

  EditorWidgetNode? _layoutAt(Offset position, {String? excluding}) {
    final candidates =
        _widgets.where((node) {
            if (!_isLayoutNode(node) || node.id == excluding) return false;
            if (excluding != null && _isDescendantOf(node.id, excluding)) {
              return false;
            }
            final origin = _absolutePosition(node);
            return Rect.fromLTWH(
              origin.dx,
              origin.dy,
              node.width,
              node.height,
            ).contains(position);
          }).toList()
          ..sort((a, b) => (a.width * a.height).compareTo(b.width * b.height));
    return candidates.firstOrNull;
  }

  void _addWidget(EditorWidgetType type, Offset canvasPosition) {
    final defaults = _widgetDefaults(type);
    final parent = _layoutAt(canvasPosition);
    final parentOrigin = parent == null
        ? Offset.zero
        : _absolutePosition(parent);
    final idBase = type.name.toLowerCase();
    var sequence = 1;
    var id = '$idBase$sequence';
    final ids = _widgets.map((item) => item.id).toSet();
    while (ids.contains(id)) {
      sequence++;
      id = '$idBase$sequence';
    }
    final node = defaults.copyWith(
      id: id,
      x: (canvasPosition.dx - defaults.width / 2).clamp(
        0,
        _canvasWidth - defaults.width,
      ),
      y: (canvasPosition.dy - defaults.height / 2).clamp(
        0,
        _canvasHeight - defaults.height,
      ),
      parentId: parent?.id ?? 'root',
      parentType: parent?.type.sketchwareType ?? -1,
      index: _widgets
          .where((item) => item.parentId == (parent?.id ?? 'root'))
          .length,
    );
    final positionedNode = parent == null
        ? node
        : node.copyWith(
            x: (node.x - parentOrigin.dx).clamp(
              0,
              math.max(0, parent.width - node.width),
            ),
            y: (node.y - parentOrigin.dy).clamp(
              0,
              math.max(0, parent.height - node.height),
            ),
          );
    _rememberWidgets();
    setState(() {
      _widgets = [..._widgets, positionedNode];
      _selectedWidgetId = positionedNode.id;
      _dirty = true;
    });
  }

  EditorWidgetNode _widgetDefaults(EditorWidgetType type) {
    return switch (type) {
      EditorWidgetType.linearLayout ||
      EditorWidgetType.relativeLayout => EditorWidgetNode(
        id: '',
        type: type,
        x: 40,
        y: 40,
        width: 280,
        height: 180,
        text: type.label,
        backgroundColor: 0xFFF1F4FF,
        borderRadius: 2,
      ),
      EditorWidgetType.button => const EditorWidgetNode(
        id: '',
        type: EditorWidgetType.button,
        x: 80,
        y: 80,
        width: 150,
        height: 50,
        text: 'Button',
        backgroundColor: 0xFF6B5CE7,
        textColor: 0xFFFFFFFF,
        elevation: 2,
        borderRadius: 8,
      ),
      EditorWidgetType.textView => const EditorWidgetNode(
        id: '',
        type: EditorWidgetType.textView,
        x: 80,
        y: 80,
        width: 150,
        height: 46,
        text: 'TextView',
        backgroundColor: 0x00FFFFFF,
      ),
      EditorWidgetType.editText => const EditorWidgetNode(
        id: '',
        type: EditorWidgetType.editText,
        x: 60,
        y: 80,
        width: 220,
        height: 54,
        text: '',
        hint: 'EditText',
        backgroundColor: 0xFFFFFFFF,
      ),
      EditorWidgetType.imageView => const EditorWidgetNode(
        id: '',
        type: EditorWidgetType.imageView,
        x: 110,
        y: 80,
        width: 120,
        height: 120,
        text: 'ImageView',
        backgroundColor: 0xFFF1F2F5,
      ),
      EditorWidgetType.floatingButton => const EditorWidgetNode(
        id: '',
        type: EditorWidgetType.floatingButton,
        x: 270,
        y: 540,
        width: 58,
        height: 58,
        text: '+',
        backgroundColor: 0xFF6B5CE7,
        textColor: 0xFFFFFFFF,
        elevation: 6,
        borderRadius: 29,
      ),
      _ => EditorWidgetNode(
        id: '',
        type: type,
        x: 70,
        y: 80,
        width: 200,
        height: 54,
        text: type.label,
        backgroundColor: 0xFFFFFFFF,
      ),
    };
  }

  void _deleteSelectedWidget() {
    final selected = _selectedWidget;
    if (selected == null) return;
    _deleteWidgetById(selected.id);
  }

  void _deleteWidgetById(String id, {bool rememberHistory = true}) {
    if (!_widgets.any((item) => item.id == id)) return;
    final idsToDelete = <String>{id};
    var changed = true;
    while (changed) {
      changed = false;
      for (final item in _widgets) {
        if (idsToDelete.contains(item.parentId) && idsToDelete.add(item.id)) {
          changed = true;
        }
      }
    }
    if (rememberHistory) _rememberWidgets();
    setState(() {
      _widgets = _widgets
          .where((item) => !idsToDelete.contains(item.id))
          .toList();
      _events = _events
          .where((item) => !idsToDelete.contains(item.target))
          .toList();
      _selectedWidgetId = null;
      _draggingWidgetId = null;
      _deleteHover = false;
      _dirty = true;
    });
  }

  void _finishWidgetDrag(
    EditorWidgetNode node,
    DraggableDetails details,
    double scale,
  ) {
    if (!mounted) return;
    if (!details.wasAccepted) {
      final box = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null) {
        final local = box.globalToLocal(details.offset) / scale;
        final index = _widgets.indexWhere((item) => item.id == node.id);
        if (index != -1) {
          final center = local + Offset(node.width / 2, node.height / 2);
          final parent = _layoutAt(center, excluding: node.id);
          final parentOrigin = parent == null
              ? Offset.zero
              : _absolutePosition(parent);
          final maxWidth = parent?.width ?? _canvasWidth;
          final maxHeight = parent?.height ?? _canvasHeight;
          final moved = _widgets[index].copyWith(
            parentId: parent?.id ?? 'root',
            parentType: parent?.type.sketchwareType ?? -1,
            index: _widgets
                .where(
                  (item) =>
                      item.id != node.id &&
                      item.parentId == (parent?.id ?? 'root'),
                )
                .length,
            x: (local.dx - parentOrigin.dx).clamp(
              0,
              math.max(0, maxWidth - node.width),
            ),
            y: (local.dy - parentOrigin.dy).clamp(
              0,
              math.max(0, maxHeight - node.height),
            ),
          );
          setState(() {
            _widgets = List.of(_widgets)..[index] = moved;
            _dirty = true;
          });
        }
      }
    }
    setState(() {
      _draggingWidgetId = null;
      _deleteHover = false;
    });
  }

  Future<void> _editSelectedProperties() async {
    final selected = _selectedWidget;
    if (selected == null) return;
    final result = await showModalBottomSheet<_PropertyResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      builder: (_) => _PropertyEditorSheet(node: selected),
    );
    if (!mounted || result == null) return;
    if (result.delete) {
      _deleteSelectedWidget();
      return;
    }
    final updated = result.node;
    if (updated == null) return;
    if (_widgets.any(
      (item) => item.id == updated.id && item.id != selected.id,
    )) {
      _showMessage('Another view already uses this ID.');
      return;
    }
    final index = _widgets.indexWhere((item) => item.id == selected.id);
    if (index == -1) return;
    _rememberWidgets();
    setState(() {
      _widgets = _widgets.map((item) {
        if (item.id == selected.id) return updated;
        if (item.parentId == selected.id) {
          return item.copyWith(parentId: updated.id);
        }
        return item;
      }).toList();
      if (updated.id != selected.id) {
        _events = _events
            .map(
              (event) => event.target == selected.id
                  ? EditorEventItem(target: updated.id, name: event.name)
                  : event,
            )
            .toList();
      }
      _selectedWidgetId = updated.id;
      _dirty = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit();
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: _editorBackground,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          leading: IconButton(
            onPressed: _confirmExit,
            icon: const Icon(Icons.arrow_back),
          ),
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.project.appName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _projectData.fileName,
                style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
              ),
            ],
          ),
          actions: [
            if (_tabController.index == 0) ...[
              IconButton(
                onPressed: _undoStack.isEmpty ? null : _undo,
                icon: const Icon(Icons.undo),
                tooltip: 'Undo',
              ),
              IconButton(
                onPressed: _redoStack.isEmpty ? null : _redo,
                icon: const Icon(Icons.redo),
                tooltip: 'Redo',
              ),
            ],
            IconButton(
              key: const Key('save-editor-project'),
              onPressed: _saving ? null : _saveProject,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              tooltip: 'Save',
            ),
            IconButton(
              key: const Key('open-editor-menu'),
              onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
              icon: const Icon(Icons.menu),
              tooltip: 'Project menu',
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            onTap: (_) => setState(() {}),
            labelColor: _editorAccent,
            unselectedLabelColor: const Color(0xFF707077),
            indicatorColor: _editorAccent,
            tabs: const [
              Tab(text: 'View'),
              Tab(text: 'Event'),
              Tab(text: 'Component'),
              Tab(text: 'Strings'),
            ],
          ),
        ),
        endDrawer: _EditorEndDrawer(project: widget.project),
        body: _buildBody(),
        bottomNavigationBar: _loading ? null : _buildEditorBottomBar(),
      ),
    );
  }

  Widget _buildEditorBottomBar() {
    return Material(
      color: Colors.white,
      elevation: 10,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              const SizedBox(width: 12),
              const Icon(Icons.stay_current_portrait, color: Color(0xFF6E6E76)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _tabController.index == 3
                      ? 'strings.xml'
                      : _projectData.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              FilledButton.icon(
                onPressed: null,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Run'),
              ),
              IconButton(
                onPressed: () =>
                    _showMessage('Compilation will be added later.'),
                icon: const Icon(Icons.more_vert),
                tooltip: 'Build options',
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 12),
              Text(_loadError!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loadProject,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }
    return TabBarView(
      controller: _tabController,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildViewTab(),
        _buildEventTab(),
        _buildComponentTab(),
        _buildStringsTab(),
      ],
    );
  }

  Widget _buildViewTab() {
    return Row(
      children: [
        _buildWidgetPalette(),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedWidgetId = null),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(10, 14, 10, 112),
                    child: _buildCanvas(),
                  ),
                ),
              ),
              if (_draggingWidgetId != null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: DragTarget<String>(
                    onWillAcceptWithDetails: (_) {
                      setState(() => _deleteHover = true);
                      return true;
                    },
                    onLeave: (_) => setState(() => _deleteHover = false),
                    onAcceptWithDetails: (details) {
                      setState(() {
                        _deleteHover = false;
                        _draggingWidgetId = null;
                      });
                      _deleteWidgetById(details.data, rememberHistory: false);
                    },
                    builder: (context, candidates, _) => AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      height: 66,
                      decoration: BoxDecoration(
                        color: _deleteHover
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF2F3037),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 14,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.delete_outline, color: Colors.white),
                          const SizedBox(width: 10),
                          Text(
                            _deleteHover
                                ? 'Release to delete'
                                : 'Drag here to delete',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (_selectedWidget != null)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Material(
                    color: Colors.white,
                    elevation: 8,
                    borderRadius: BorderRadius.circular(18),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0xFFEDE9FE),
                            foregroundColor: _editorAccent,
                            child: Icon(_iconForWidget(_selectedWidget!.type)),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedWidget!.id,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${_selectedWidget!.width.round()} × ${_selectedWidget!.height.round()}  •  shadow ${_selectedWidget!.elevation.round()}',
                                  style: const TextStyle(
                                    color: Color(0xFF8E8E93),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _deleteSelectedWidget,
                            color: Colors.redAccent,
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'Delete widget',
                          ),
                          FilledButton.icon(
                            onPressed: _editSelectedProperties,
                            icon: const Icon(Icons.tune, size: 18),
                            label: const Text('See All'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWidgetPalette() {
    return Material(
      color: Colors.white,
      elevation: 1,
      child: SizedBox(
        width: 118,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(7, 8, 7, 5),
              child: Row(
                children: [
                  Expanded(
                    child: IconButton.filledTonal(
                      onPressed: () {
                        setState(() => _showFavoritePalette = false);
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: !_showFavoritePalette
                            ? const Color(0xFFEDE9FE)
                            : const Color(0xFFF2F2F7),
                      ),
                      icon: const Icon(Icons.widgets_outlined, size: 20),
                      tooltip: 'Basic widgets',
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: IconButton.filledTonal(
                      onPressed: () {
                        setState(() => _showFavoritePalette = true);
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: _showFavoritePalette
                            ? const Color(0xFFEDE9FE)
                            : const Color(0xFFF2F2F7),
                      ),
                      icon: const Icon(Icons.bookmark_border, size: 20),
                      tooltip: 'Favorite widgets',
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              child: OutlinedButton.icon(
                onPressed: () =>
                    _showMessage('Custom widget creator is not available yet.'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: const Size.fromHeight(42),
                ),
                icon: const Icon(Icons.add, size: 17),
                label: const Flexible(
                  child: Text(
                    'New widget',
                    maxLines: 1,
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ),
            const Divider(height: 10),
            Expanded(
              child: _showFavoritePalette
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(10),
                        child: Text(
                          'No favorite widgets',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF8E8E93),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(7, 0, 7, 18),
                      children: [
                        _buildPaletteSection('Layouts', const [
                          EditorWidgetType.linearLayout,
                          EditorWidgetType.relativeLayout,
                          EditorWidgetType.horizontalScroll,
                          EditorWidgetType.scrollView,
                          EditorWidgetType.cardView,
                          EditorWidgetType.textInputLayout,
                          EditorWidgetType.swipeRefresh,
                        ]),
                        _buildPaletteSection('Widgets', const [
                          EditorWidgetType.textView,
                          EditorWidgetType.editText,
                          EditorWidgetType.button,
                          EditorWidgetType.materialButton,
                          EditorWidgetType.imageView,
                          EditorWidgetType.circleImageView,
                          EditorWidgetType.checkBox,
                          EditorWidgetType.radioButton,
                          EditorWidgetType.switchView,
                          EditorWidgetType.seekBar,
                          EditorWidgetType.progressBar,
                          EditorWidgetType.ratingBar,
                          EditorWidgetType.searchView,
                          EditorWidgetType.webView,
                        ]),
                        _buildPaletteSection('Lists', const [
                          EditorWidgetType.listView,
                          EditorWidgetType.gridView,
                          EditorWidgetType.recyclerView,
                          EditorWidgetType.spinner,
                          EditorWidgetType.viewPager,
                        ]),
                        _buildPaletteSection('Library', const [
                          EditorWidgetType.lottieAnimation,
                          EditorWidgetType.otpView,
                          EditorWidgetType.codeView,
                          EditorWidgetType.patternLock,
                        ]),
                        _buildPaletteSection('Date & Time', const [
                          EditorWidgetType.calendarView,
                          EditorWidgetType.datePicker,
                          EditorWidgetType.timePicker,
                          EditorWidgetType.analogClock,
                          EditorWidgetType.digitalClock,
                        ]),
                        _buildPaletteSection('Other', const [
                          EditorWidgetType.floatingButton,
                          EditorWidgetType.mapView,
                          EditorWidgetType.adView,
                          EditorWidgetType.youtubePlayer,
                        ]),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaletteSection(String label, List<EditorWidgetType> types) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 10, 4, 5),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8E8E93),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        for (final type in types) ...[
          _buildDraggablePaletteTile(type),
          const SizedBox(height: 6),
        ],
      ],
    );
  }

  Widget _buildDraggablePaletteTile(EditorWidgetType type) {
    final tile = _PaletteTile(type: type);
    return LongPressDraggable<EditorWidgetType>(
      data: type,
      delay: const Duration(milliseconds: 120),
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(opacity: 0.5, child: tile),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: tile),
      child: tile,
    );
  }

  Widget _buildCanvas() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.min(constraints.maxWidth, _canvasWidth);
        final scale = width / _canvasWidth;
        return Center(
          child: DragTarget<EditorWidgetType>(
            key: _canvasKey,
            onAcceptWithDetails: (details) {
              final box =
                  _canvasKey.currentContext?.findRenderObject() as RenderBox?;
              if (box == null) return;
              final local = box.globalToLocal(details.offset) / scale;
              _addWidget(details.data, local);
            },
            builder: (context, candidates, _) => AnimatedContainer(
              key: const Key('editor-canvas'),
              duration: const Duration(milliseconds: 120),
              width: width,
              height: _canvasHeight * scale,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: candidates.isNotEmpty ? _editorAccent : _editorBorder,
                  width: candidates.isNotEmpty ? 2 : 1,
                ),
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
                  Positioned.fill(
                    child: CustomPaint(painter: _GridPainter(scale)),
                  ),
                  if (_widgets.isEmpty)
                    const Center(
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
                  for (final node in _widgets)
                    _buildPositionedNode(node, scale),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPositionedNode(EditorWidgetNode node, double scale) {
    final selected = node.id == _selectedWidgetId;
    final absolutePosition = _absolutePosition(node);
    return Positioned(
      left: absolutePosition.dx * scale,
      top: absolutePosition.dy * scale,
      width: node.width * scale,
      height: node.height * scale,
      child: LongPressDraggable<String>(
        data: node.id,
        delay: const Duration(milliseconds: 120),
        dragAnchorStrategy: childDragAnchorStrategy,
        onDragStarted: () {
          _rememberWidgets();
          setState(() {
            _selectedWidgetId = node.id;
            _draggingWidgetId = node.id;
          });
        },
        onDragEnd: (details) => _finishWidgetDrag(node, details, scale),
        feedback: Material(
          color: Colors.transparent,
          child: Opacity(
            opacity: 0.5,
            child: SizedBox(
              width: node.width * scale,
              height: node.height * scale,
              child: _EditorNodePreview(node: node, scale: scale),
            ),
          ),
        ),
        childWhenDragging: const SizedBox.expand(),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _selectedWidgetId = node.id),
          onDoubleTap: () {
            setState(() => _selectedWidgetId = node.id);
            _editSelectedProperties();
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: node.visible ? (node.enabled ? 1 : 0.55) : 0.25,
                  child: _EditorNodePreview(node: node, scale: scale),
                ),
              ),
              if (selected)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0x9599D5D0),
                        border: Border.all(color: _editorAccent, width: 2),
                        borderRadius: BorderRadius.circular(
                          node.borderRadius * scale,
                        ),
                      ),
                    ),
                  ),
                ),
              if (selected)
                const Positioned(right: -5, top: -5, child: _SelectionHandle()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventTab() {
    return _EditorListPage(
      title: 'Events',
      description: 'Activity and view events available for main.xml.',
      emptyText: 'No events added',
      addLabel: 'Add event',
      onAdd: _addEvent,
      children: _events.map((event) {
        return ListTile(
          leading: const CircleAvatar(
            backgroundColor: Color(0xFFFFE9E2),
            foregroundColor: Color(0xFFE56A3C),
            child: Icon(Icons.bolt, size: 20),
          ),
          title: Text(event.name),
          subtitle: Text(event.target),
          trailing: IconButton(
            onPressed: event.name == 'onCreate'
                ? null
                : () {
                    setState(() {
                      _events.remove(event);
                      _dirty = true;
                    });
                  },
            icon: const Icon(Icons.delete_outline),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _addEvent() async {
    final targets = ['Activity', ..._widgets.map((item) => item.id)];
    var target = targets.first;
    var eventName = 'onClick';
    final added = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add event'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: target,
                decoration: const InputDecoration(labelText: 'Target'),
                items: targets
                    .map(
                      (item) =>
                          DropdownMenuItem(value: item, child: Text(item)),
                    )
                    .toList(),
                onChanged: (value) => setDialogState(() => target = value!),
              ),
              DropdownButtonFormField<String>(
                initialValue: eventName,
                decoration: const InputDecoration(labelText: 'Event'),
                items:
                    const [
                          'onClick',
                          'onLongClick',
                          'onTextChanged',
                          'onCheckedChanged',
                        ]
                        .map(
                          (item) =>
                              DropdownMenuItem(value: item, child: Text(item)),
                        )
                        .toList(),
                onChanged: (value) => setDialogState(() => eventName = value!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    if (added == true && mounted) {
      if (_events.any(
        (item) => item.target == target && item.name == eventName,
      )) {
        _showMessage('This event already exists.');
        return;
      }
      setState(() {
        _events.add(EditorEventItem(target: target, name: eventName));
        _dirty = true;
      });
    }
  }

  Widget _buildComponentTab() {
    return _EditorListPage(
      title: 'Components',
      description: 'Non-visual components used by this activity.',
      emptyText: 'No components added',
      addLabel: 'Add component',
      onAdd: _addComponent,
      children: _components.map((component) {
        return ListTile(
          leading: const CircleAvatar(
            backgroundColor: Color(0xFFE8F3FF),
            foregroundColor: Color(0xFF3178C6),
            child: Icon(Icons.extension_outlined, size: 20),
          ),
          title: Text(component.id),
          subtitle: Text(component.type),
          trailing: IconButton(
            onPressed: () {
              setState(() {
                _components.remove(component);
                _dirty = true;
              });
            },
            icon: const Icon(Icons.delete_outline),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _addComponent() async {
    const types = [
      'Intent',
      'SharedPreferences',
      'Calendar',
      'Timer',
      'Dialog',
      'MediaPlayer',
      'FilePicker',
      'RequestNetwork',
      'TextToSpeech',
      'Vibrator',
    ];
    var type = types.first;
    final idController = TextEditingController(text: 'intent1');
    final added = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add component'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: const InputDecoration(labelText: 'Component type'),
                items: types
                    .map(
                      (item) =>
                          DropdownMenuItem(value: item, child: Text(item)),
                    )
                    .toList(),
                onChanged: (value) {
                  setDialogState(() {
                    type = value!;
                    idController.text = '${type.toLowerCase()}1';
                  });
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: idController,
                decoration: const InputDecoration(labelText: 'Component ID'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    final id = idController.text.trim();
    idController.dispose();
    if (added == true && mounted && id.isNotEmpty) {
      if (_components.any((item) => item.id == id)) {
        _showMessage('This component ID already exists.');
        return;
      }
      setState(() {
        _components.add(EditorComponentItem(id: id, type: type));
        _dirty = true;
      });
    }
  }

  Widget _buildStringsTab() {
    final entries = _strings.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return _EditorListPage(
      title: 'Strings',
      description: 'Text resources stored for this project.',
      emptyText: 'No strings added',
      addLabel: 'Add string',
      onAdd: () => _editString(),
      children: entries.map((entry) {
        return ListTile(
          leading: const CircleAvatar(
            backgroundColor: Color(0xFFEDE9FE),
            foregroundColor: _editorAccent,
            child: Icon(Icons.translate, size: 20),
          ),
          title: Text(entry.key),
          subtitle: Text(
            entry.value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => _editString(key: entry.key, value: entry.value),
          trailing: IconButton(
            onPressed: entry.key == 'app_name'
                ? null
                : () {
                    setState(() {
                      _strings.remove(entry.key);
                      _dirty = true;
                    });
                  },
            icon: const Icon(Icons.delete_outline),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _editString({String? key, String value = ''}) async {
    final keyController = TextEditingController(text: key ?? '');
    final valueController = TextEditingController(text: value);
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(key == null ? 'Add string' : 'Edit string'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: keyController,
              enabled: key == null,
              decoration: const InputDecoration(labelText: 'Resource name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: valueController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Value'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    final resourceKey = keyController.text.trim();
    final resourceValue = valueController.text;
    keyController.dispose();
    valueController.dispose();
    if (saved == true && mounted) {
      if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(resourceKey)) {
        _showMessage('Use a lowercase resource name with underscores.');
        return;
      }
      setState(() {
        _strings[resourceKey] = resourceValue;
        _dirty = true;
      });
    }
  }
}

class _PaletteTile extends StatelessWidget {
  const _PaletteTile({required this.type});

  final EditorWidgetType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F2FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE3DEFF)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_iconForWidget(type), color: _editorAccent, size: 24),
          const SizedBox(height: 4),
          Text(
            type.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }
}

IconData _iconForWidget(EditorWidgetType type) {
  return switch (type) {
    EditorWidgetType.linearLayout => Icons.view_agenda_outlined,
    EditorWidgetType.relativeLayout => Icons.dashboard_outlined,
    EditorWidgetType.horizontalScroll => Icons.swap_horiz,
    EditorWidgetType.button => Icons.smart_button_outlined,
    EditorWidgetType.textView => Icons.text_fields,
    EditorWidgetType.editText => Icons.edit_note,
    EditorWidgetType.imageView => Icons.image_outlined,
    EditorWidgetType.webView => Icons.language,
    EditorWidgetType.progressBar => Icons.hourglass_top,
    EditorWidgetType.listView => Icons.view_list,
    EditorWidgetType.spinner => Icons.arrow_drop_down_circle_outlined,
    EditorWidgetType.checkBox => Icons.check_box_outlined,
    EditorWidgetType.scrollView => Icons.swap_vert,
    EditorWidgetType.switchView => Icons.toggle_on_outlined,
    EditorWidgetType.seekBar => Icons.tune,
    EditorWidgetType.calendarView => Icons.calendar_month_outlined,
    EditorWidgetType.floatingButton => Icons.add_circle_outline,
    EditorWidgetType.adView => Icons.ads_click,
    EditorWidgetType.mapView => Icons.map_outlined,
    EditorWidgetType.radioButton => Icons.radio_button_checked,
    EditorWidgetType.ratingBar => Icons.star_border,
    EditorWidgetType.videoView => Icons.video_library_outlined,
    EditorWidgetType.searchView => Icons.search,
    EditorWidgetType.autoCompleteText ||
    EditorWidgetType.multiAutoCompleteText => Icons.manage_search,
    EditorWidgetType.gridView => Icons.grid_view,
    EditorWidgetType.analogClock ||
    EditorWidgetType.digitalClock => Icons.schedule,
    EditorWidgetType.datePicker ||
    EditorWidgetType.timePicker => Icons.event_outlined,
    EditorWidgetType.tabLayout => Icons.tab,
    EditorWidgetType.viewPager => Icons.view_carousel_outlined,
    EditorWidgetType.bottomNavigation => Icons.space_bar,
    EditorWidgetType.badgeView => Icons.badge_outlined,
    EditorWidgetType.patternLock => Icons.pattern,
    EditorWidgetType.waveSideBar => Icons.waves,
    EditorWidgetType.cardView => Icons.crop_16_9,
    EditorWidgetType.collapsingToolbar => Icons.vertical_align_top,
    EditorWidgetType.textInputLayout => Icons.input,
    EditorWidgetType.swipeRefresh => Icons.refresh,
    EditorWidgetType.radioGroup => Icons.radio_button_checked,
    EditorWidgetType.materialButton => Icons.smart_button,
    EditorWidgetType.signInButton => Icons.login,
    EditorWidgetType.circleImageView => Icons.account_circle_outlined,
    EditorWidgetType.lottieAnimation => Icons.animation,
    EditorWidgetType.youtubePlayer => Icons.play_circle_outline,
    EditorWidgetType.otpView => Icons.password,
    EditorWidgetType.codeView => Icons.code,
    EditorWidgetType.recyclerView => Icons.view_stream_outlined,
  };
}

class _EditorNodePreview extends StatelessWidget {
  const _EditorNodePreview({required this.node, required this.scale});

  final EditorWidgetNode node;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final background = Color(node.backgroundColor & 0xFFFFFFFF);
    final foreground = Color(node.textColor & 0xFFFFFFFF);
    final radius = BorderRadius.circular(node.borderRadius * scale);
    final textStyle = TextStyle(
      color: foreground,
      fontSize: node.fontSize * scale,
    );
    final isLayout =
        node.type == EditorWidgetType.linearLayout ||
        node.type == EditorWidgetType.relativeLayout;

    Widget content = switch (node.type) {
      EditorWidgetType.button => Center(
        child: Text(node.text, style: textStyle),
      ),
      EditorWidgetType.textView => Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8 * scale),
          child: Text(node.text, style: textStyle),
        ),
      ),
      EditorWidgetType.editText => Padding(
        padding: EdgeInsets.symmetric(horizontal: 10 * scale),
        child: Align(
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
      ),
      EditorWidgetType.imageView => Center(
        child: Icon(
          Icons.image_outlined,
          color: foreground.withValues(alpha: 0.55),
          size: 36 * scale,
        ),
      ),
      EditorWidgetType.checkBox => Row(
        mainAxisAlignment: MainAxisAlignment.center,
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(node.text, style: textStyle),
          SizedBox(width: 8 * scale),
          Icon(Icons.toggle_on, size: 32 * scale, color: _editorAccent),
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
              _iconForWidget(node.type),
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

    return Material(
      color: background,
      elevation: node.elevation,
      shadowColor: Colors.black54,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: isLayout ? const Color(0xFF9EA6C7) : const Color(0x22000000),
          ),
          borderRadius: radius,
        ),
        child: content,
      ),
    );
  }
}

class _SelectionHandle extends StatelessWidget {
  const _SelectionHandle();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(color: _editorAccent, shape: BoxShape.circle),
      child: SizedBox.square(dimension: 10),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter(this.scale);

  final double scale;

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

class _PropertyResult {
  const _PropertyResult({this.node, this.delete = false});

  final EditorWidgetNode? node;
  final bool delete;
}

class _PropertyEditorSheet extends StatefulWidget {
  const _PropertyEditorSheet({required this.node});

  final EditorWidgetNode node;

  @override
  State<_PropertyEditorSheet> createState() => _PropertyEditorSheetState();
}

class _PropertyEditorSheetState extends State<_PropertyEditorSheet> {
  late final TextEditingController _id;
  late final TextEditingController _text;
  late final TextEditingController _hint;
  late final TextEditingController _width;
  late final TextEditingController _height;
  late final TextEditingController _x;
  late final TextEditingController _y;
  late int _backgroundColor;
  late int _textColor;
  late double _fontSize;
  late double _elevation;
  late double _radius;
  late bool _visible;
  late bool _enabled;
  late String _orientation;

  @override
  void initState() {
    super.initState();
    final node = widget.node;
    _id = TextEditingController(text: node.id);
    _text = TextEditingController(text: node.text);
    _hint = TextEditingController(text: node.hint);
    _width = TextEditingController(text: node.width.round().toString());
    _height = TextEditingController(text: node.height.round().toString());
    _x = TextEditingController(text: node.x.round().toString());
    _y = TextEditingController(text: node.y.round().toString());
    _backgroundColor = node.backgroundColor;
    _textColor = node.textColor;
    _fontSize = node.fontSize;
    _elevation = node.elevation;
    _radius = node.borderRadius;
    _visible = node.visible;
    _enabled = node.enabled;
    _orientation = node.orientation;
  }

  @override
  void dispose() {
    _id.dispose();
    _text.dispose();
    _hint.dispose();
    _width.dispose();
    _height.dispose();
    _x.dispose();
    _y.dispose();
    super.dispose();
  }

  double _number(TextEditingController controller, double fallback) =>
      double.tryParse(controller.text) ?? fallback;

  void _save() {
    final id = _id.text.trim();
    if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$').hasMatch(id)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a valid view ID.')));
      return;
    }
    final node = widget.node.copyWith(
      id: id,
      text: _text.text,
      hint: _hint.text,
      width: _number(_width, widget.node.width).clamp(24, _canvasWidth),
      height: _number(_height, widget.node.height).clamp(24, _canvasHeight),
      x: _number(_x, widget.node.x).clamp(0, _canvasWidth - 24),
      y: _number(_y, widget.node.y).clamp(0, _canvasHeight - 24),
      backgroundColor: _backgroundColor,
      textColor: _textColor,
      fontSize: _fontSize,
      elevation: _elevation,
      borderRadius: _radius,
      visible: _visible,
      enabled: _enabled,
      orientation: _orientation,
    );
    Navigator.pop(context, _PropertyResult(node: node));
  }

  @override
  Widget build(BuildContext context) {
    final isLayout =
        widget.node.type == EditorWidgetType.linearLayout ||
        widget.node.type == EditorWidgetType.relativeLayout;
    return Padding(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 10,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 18,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D1D6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFEDE9FE),
                  foregroundColor: _editorAccent,
                  child: Icon(_iconForWidget(widget.node.type)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.node.type.label,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'View properties',
                        style: TextStyle(color: Color(0xFF8E8E93)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(
                    context,
                    const _PropertyResult(delete: true),
                  ),
                  color: Colors.redAccent,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _id,
              decoration: const InputDecoration(labelText: 'ID'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _text,
              decoration: const InputDecoration(labelText: 'Text'),
            ),
            if (widget.node.type == EditorWidgetType.editText) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _hint,
                decoration: const InputDecoration(labelText: 'Hint'),
              ),
            ],
            const SizedBox(height: 14),
            const _PropertyHeader('Layout'),
            Row(
              children: [
                Expanded(
                  child: _NumberField(controller: _width, label: 'Width'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _NumberField(controller: _height, label: 'Height'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _NumberField(controller: _x, label: 'X position'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _NumberField(controller: _y, label: 'Y position'),
                ),
              ],
            ),
            if (isLayout) ...[
              const SizedBox(height: 10),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'vertical', label: Text('Vertical')),
                  ButtonSegment(value: 'horizontal', label: Text('Horizontal')),
                ],
                selected: {_orientation},
                onSelectionChanged: (value) =>
                    setState(() => _orientation = value.first),
              ),
            ],
            const SizedBox(height: 18),
            const _PropertyHeader('Appearance'),
            _ColorProperty(
              label: 'Background color',
              value: _backgroundColor,
              onChanged: (value) => setState(() => _backgroundColor = value),
            ),
            _ColorProperty(
              label: 'Text color',
              value: _textColor,
              onChanged: (value) => setState(() => _textColor = value),
            ),
            _SliderProperty(
              label: 'Text size',
              value: _fontSize,
              min: 8,
              max: 48,
              onChanged: (value) => setState(() => _fontSize = value),
            ),
            _SliderProperty(
              label: 'Shadow / elevation',
              value: _elevation,
              min: 0,
              max: 24,
              onChanged: (value) => setState(() => _elevation = value),
            ),
            _SliderProperty(
              label: 'Corner radius',
              value: _radius,
              min: 0,
              max: 40,
              onChanged: (value) => setState(() => _radius = value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Visible'),
              value: _visible,
              onChanged: (value) => setState(() => _visible = value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Enabled'),
              value: _enabled,
              onChanged: (value) => setState(() => _enabled = value),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: _editorAccent,
              ),
              icon: const Icon(Icons.check),
              label: const Text('Apply properties'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PropertyHeader extends StatelessWidget {
  const _PropertyHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label,
        style: const TextStyle(
          color: _editorAccent,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      decoration: InputDecoration(labelText: label),
    );
  }
}

class _SliderProperty extends StatelessWidget {
  const _SliderProperty({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text(
              value.toStringAsFixed(0),
              style: const TextStyle(color: Color(0xFF8E8E93)),
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ColorProperty extends StatelessWidget {
  const _ColorProperty({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  static const colors = [
    0x00FFFFFF,
    0xFFFFFFFF,
    0xFF1C1C1E,
    0xFF6B5CE7,
    0xFF2196F3,
    0xFF4CAF50,
    0xFFFF9800,
    0xFFEF4444,
    0xFFF1F2F5,
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 8),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: colors.map((colorValue) {
              final selected = value == colorValue;
              return InkWell(
                onTap: () => onChanged(colorValue),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Color(colorValue),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? _editorAccent : _editorBorder,
                      width: selected ? 3 : 1,
                    ),
                  ),
                  child: colorValue == 0x00FFFFFF
                      ? const Icon(
                          Icons.block,
                          size: 18,
                          color: Colors.redAccent,
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _EditorListPage extends StatelessWidget {
  const _EditorListPage({
    required this.title,
    required this.description,
    required this.emptyText,
    required this.addLabel,
    required this.onAdd,
    required this.children,
  });

  final String title;
  final String description;
  final String emptyText;
  final String addLabel;
  final VoidCallback onAdd;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: const TextStyle(color: Color(0xFF8E8E93)),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: Text(addLabel),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (children.isEmpty)
          Container(
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _editorBorder),
            ),
            child: Center(
              child: Text(
                emptyText,
                style: const TextStyle(color: Color(0xFF8E8E93)),
              ),
            ),
          )
        else
          Card(
            margin: EdgeInsets.zero,
            color: Colors.white,
            child: Column(children: children),
          ),
      ],
    );
  }
}

class _EditorEndDrawer extends StatelessWidget {
  const _EditorEndDrawer({required this.project});

  final ProjectItem project;

  @override
  Widget build(BuildContext context) {
    const sections = <(String, List<(IconData, String, String)>)>[
      (
        'Configuration',
        [
          (
            Icons.category_outlined,
            'Library manager',
            'Manage project libraries',
          ),
          (
            Icons.devices_outlined,
            'View manager',
            'Manage activities and custom views',
          ),
          (Icons.image_outlined, 'Image manager', 'Project image resources'),
          (Icons.animation, 'Lottie manager', 'Lottie animation resources'),
          (
            Icons.music_note_outlined,
            'Sound manager',
            'Project sound resources',
          ),
          (
            Icons.font_download_outlined,
            'Font manager',
            'Project font resources',
          ),
          (Icons.javascript, 'Java/Kotlin manager', 'Project source files'),
          (
            Icons.folder_copy_outlined,
            'Resource manager',
            'Raw project resources',
          ),
          (Icons.edit_document, 'Resource editor', 'Edit values resources'),
          (Icons.inventory_2_outlined, 'Asset manager', 'Project asset files'),
          (
            Icons.security_outlined,
            'Permission manager',
            'Android permissions',
          ),
        ],
      ),
      (
        'Project tools',
        [
          (Icons.code, 'View source code', 'Generated source preview'),
          (Icons.description_outlined, 'AndroidManifest', 'Manifest manager'),
          (
            Icons.integration_instructions_outlined,
            'AppCompat injection',
            'Injection manager',
          ),
          (Icons.shield_outlined, 'Code shrinking', 'ProGuard configuration'),
          (Icons.block_outlined, 'See custom blocks', 'Used custom blocks'),
          (
            Icons.visibility_off_outlined,
            'StringFog manager',
            'String obfuscation',
          ),
          (Icons.data_object, 'XML commands', 'Manage XML commands'),
          (Icons.article_outlined, 'Logcat reader', 'View application logs'),
          (
            Icons.bookmark_outline,
            'Collection manager',
            'Reusable collections',
          ),
        ],
      ),
    ];
    return Drawer(
      width: math.min(MediaQuery.sizeOf(context).width * 0.88, 300),
      backgroundColor: const Color(0xFFF8F9FA),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _editorBorder),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFFEDE9FE),
                    foregroundColor: _editorAccent,
                    child: Icon(Icons.android),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.appName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          project.packageName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            for (final section in sections) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 20, 12, 6),
                child: Text(
                  section.$1,
                  style: const TextStyle(
                    color: Color(0xFF8E8E93),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _editorBorder),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: section.$2.map((item) {
                    return ListTile(
                      leading: Icon(item.$1, color: _editorAccent),
                      title: Text(item.$2),
                      subtitle: Text(
                        item.$3,
                        style: const TextStyle(fontSize: 12),
                      ),
                      onTap: () {},
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
