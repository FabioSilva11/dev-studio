import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/editor_project.dart';
import 'models/project_item.dart';
import 'services/sketchware_project_service.dart';
import 'widgets/editor_palette.dart';
import 'widgets/editor_canvas.dart';
import 'widgets/property_editor.dart';
import 'widgets/editor_list_tabs.dart';
import 'widgets/sketchware_bottom_bar.dart';
import 'widgets/view_manager.dart';

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
  late final TabController _tabController;

  EditorProjectData _projectData = const EditorProjectData();
  List<EditorWidgetNode> _widgets = [];
  List<EditorEventItem> _events = [];
  List<EditorComponentItem> _components = [];
  Map<String, String> _strings = {};
  final List<List<EditorWidgetNode>> _undoStack = [];
  final List<List<EditorWidgetNode>> _redoStack = [];

  String? _selectedWidgetId;
  bool _loading = true;
  bool _saving = false;
  bool _dirty = false;
  bool _showFavoritePalette = false;
  String? _loadError;

  final List<ViewItemData> _views = [ViewItemData(name: 'main')];
  ViewItemData? _currentView;

  ViewItemData get _currentViewData => _currentView ?? _views.first;

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

  void _addWidgetAt(EditorWidgetType type, String parentId, int index) {
    final defaults = _widgetDefaults(type);
    final idBase = type.name.toLowerCase();
    var sequence = 1;
    var id = '$idBase$sequence';
    final ids = _widgets.map((item) => item.id).toSet();
    while (ids.contains(id)) {
      sequence++;
      id = '$idBase$sequence';
    }

    final double initialWidth = (type == EditorWidgetType.linearLayout || type == EditorWidgetType.relativeLayout) ? -1 : -2; // -1: match_parent, -2: wrap_content
    final double initialHeight = (type == EditorWidgetType.linearLayout || type == EditorWidgetType.relativeLayout) ? 180 : -2;

    final node = defaults.copyWith(
      id: id,
      parentId: parentId,
      parentType: _widgets.where((w) => w.id == parentId).firstOrNull?.type.sketchwareType ?? -1,
      index: index,
      width: initialWidth,
      height: initialHeight,
    );

    _rememberWidgets();

    setState(() {
      _widgets = _widgets.map((w) {
        if (w.parentId == parentId && w.index >= index) {
          return w.copyWith(index: w.index + 1);
        }
        return w;
      }).toList();

      _widgets.add(node);
      _selectedWidgetId = node.id;
      _dirty = true;
    });
  }

  void _moveWidget(String id, String newParentId, int newIndex) {
    final widgetNode = _widgets.where((w) => w.id == id).firstOrNull;
    if (widgetNode == null) return;
    
    final oldParentId = widgetNode.parentId;
    final oldIndex = widgetNode.index;

    _rememberWidgets();

    setState(() {
      _widgets = _widgets.map((w) {
        if (w.parentId == oldParentId && w.index > oldIndex) {
          return w.copyWith(index: w.index - 1);
        }
        return w;
      }).toList();

      _widgets = _widgets.map((w) {
        if (w.parentId == newParentId && w.index >= newIndex) {
          return w.copyWith(index: w.index + 1);
        }
        return w;
      }).toList();

      _widgets = _widgets.map((w) {
        if (w.id == id) {
          return w.copyWith(
            parentId: newParentId,
            parentType: _widgets.where((item) => item.id == newParentId).firstOrNull?.type.sketchwareType ?? -1,
            index: newIndex,
          );
        }
        return w;
      }).toList();

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
        paddingLeft: 8.0,
        paddingTop: 8.0,
        paddingRight: 8.0,
        paddingBottom: 8.0,
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
      _dirty = true;
    });
  }

  Future<void> _editSelectedProperties() async {
    final selected = _selectedWidget;
    if (selected == null) return;
    final result = await showModalBottomSheet<PropertyResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      builder: (_) => PropertyEditorSheet(node: selected, accentColor: _editorAccent),
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
        bottomNavigationBar: _loading
            ? null
            : (_selectedWidget != null && _tabController.index == 0)
                ? SketchwareBottomBar(
                    widgets: _widgets,
                    selectedWidget: _selectedWidget!,
                    onSelect: (id) => setState(() => _selectedWidgetId = id),
                    onDelete: _deleteSelectedWidget,
                    onSave: () => _showMessage('Widget saved to collections'),
                    onSeeAll: _editSelectedProperties,
                    onUpdateWidget: (updatedNode) {
                      final index = _widgets.indexWhere((item) => item.id == updatedNode.id);
                      if (index != -1) {
                        _rememberWidgets();
                        setState(() {
                          _widgets = List.of(_widgets)..[index] = updatedNode;
                          _dirty = true;
                        });
                      }
                    },
                    accentColor: _editorAccent,
                  )
                : _buildEditorBottomBar(),
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
                child: InkWell(
                  onTap: _tabController.index == 3 ? null : _openViewManager,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.layers_outlined, size: 16, color: Color(0xFF6E6E76)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            _tabController.index == 3
                                ? 'strings.xml'
                                : _currentViewData.xmlName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
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

  void _openViewManager() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ViewManagerSheet(
          views: _views,
          currentView: _currentViewData,
          accentColor: _editorAccent,
          onSelectView: (view) {
            setState(() {
              _currentView = view;
            });
            _showMessage('Switched to ${view.xmlName}');
          },
          onCreateView: (newView) {
            setState(() {
              _views.add(newView);
              _currentView = newView;
            });
            _showMessage('Created and switched to ${newView.xmlName}');
          },
        );
      },
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
        // Modular Palette
        EditorPalette(
          showFavoritePalette: _showFavoritePalette,
          onToggleFavorite: (val) => setState(() => _showFavoritePalette = val),
          accentColor: _editorAccent,
        ),

        // Modular Canvas & Bottom selection bar
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = math.min(constraints.maxWidth, _canvasWidth);
                    final scale = width / _canvasWidth;
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(10, 14, 10, 112),
                      child: EditorCanvas(
                        widgets: _widgets,
                        selectedWidgetId: _selectedWidgetId,
                        onSelect: (id) => setState(() => _selectedWidgetId = id),
                        onAddWidget: _addWidgetAt,
                        onMoveWidget: _moveWidget,
                        onEditProperties: _editSelectedProperties,
                        scale: scale,
                        accentColor: _editorAccent,
                        canvasWidth: _canvasWidth,
                        canvasHeight: _canvasHeight,
                      ),
                    );
                  },
                ),
              ),

              // Trash bin (shows when dragging)
              DragTarget<String>(
                onAcceptWithDetails: (details) {
                  _deleteWidgetById(details.data);
                },
                builder: (context, candidates, _) {
                  final isHovered = candidates.isNotEmpty;
                  // Only show trash target when dragging is active or hovered
                  return Positioned(
                    left: 16,
                    right: 16,
                    bottom: _selectedWidget != null ? 84 : 16,
                    child: IgnorePointer(
                      ignoring: false,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 160),
                        opacity: 0.9,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          height: 66,
                          decoration: BoxDecoration(
                            color: isHovered
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
                                isHovered
                                    ? 'Release to delete'
                                    : 'Drag widget here to delete',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              if (_selectedWidget != null)
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
                            child: Icon(iconForWidget(_selectedWidget!.type)),
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
                                  'Width: ${_selectedWidget!.width >= 0 ? _selectedWidget!.width.round().toString() : (_selectedWidget!.width == -1 ? "match_parent" : "wrap_content")}  •  Height: ${_selectedWidget!.height >= 0 ? _selectedWidget!.height.round().toString() : (_selectedWidget!.height == -1 ? "match_parent" : "wrap_content")}',
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

  Widget _buildEventTab() {
    return EventsTab(
      events: _events,
      widgets: _widgets,
      accentColor: _editorAccent,
      onChanged: (newEvents) {
        setState(() {
          _events = newEvents;
          _dirty = true;
        });
      },
    );
  }

  Widget _buildComponentTab() {
    return ComponentsTab(
      components: _components,
      accentColor: _editorAccent,
      onChanged: (newComponents) {
        setState(() {
          _components = newComponents;
          _dirty = true;
        });
      },
    );
  }

  Widget _buildStringsTab() {
    return StringsTab(
      strings: _strings,
      accentColor: _editorAccent,
      onChanged: (newStrings) {
        setState(() {
          _strings = newStrings;
          _dirty = true;
        });
      },
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
                    return WidgetListTile(
                      icon: item.$1,
                      title: item.$2,
                      subtitle: item.$3,
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

class WidgetListTile extends StatelessWidget {
  const WidgetListTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: _editorAccent),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12),
      ),
      onTap: () {},
    );
  }
}
