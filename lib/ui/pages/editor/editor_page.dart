
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:dev_studio/core/config/dependencies.dart';
import 'package:dev_studio/domain/common/project/dev_studio_project.dart';
import 'package:dev_studio/domain/common/editor/editor_screen.dart';
import 'package:dev_studio/domain/common/editor/widget_node.dart';
import 'package:dev_studio/domain/common/editor/widget_type.dart';
import 'package:dev_studio/ui/pages/editor/viewmodel/editor_viewmodel.dart';
// import 'package:dev_studio/ui/pages/editor/widgets/editor_canvas.dart';
// import 'package:dev_studio/ui/pages/editor/widgets/editor_list_tabs.dart';
// import 'package:dev_studio/ui/pages/editor/widgets/editor_palette.dart';
// import 'package:dev_studio/ui/pages/editor/widgets/property_editor.dart';
// import 'package:dev_studio/ui/pages/editor/widgets/devstudio_bottom_bar.dart';
// import 'package:dev_studio/ui/pages/editor/widgets/view_manager.dart';

const _editorAccent = Color(0xFF6B5CE7);
const _editorBackground = Color(0xFFF5F6F8);
const _editorBorder = Color(0xFFE2E3E8);
const _canvasWidth = 360.0;
const _canvasHeight = 640.0;

class EditorPage extends StatefulWidget {
  const EditorPage({
    super.key,
    required this.project,
    this.viewModel,
  });

  final DevStudioProject project;
  final EditorViewModel? viewModel;

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage>
    with SingleTickerProviderStateMixin {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late final TabController _tabController;
  late final EditorViewModel _viewModel;

  bool _loading = true;
  bool _saving = false;
  bool _dirty = false;
  bool _showFavoritePalette = false;
  String? _loadError;

  final List<List<WidgetNode>> _undoStack = [];
  final List<List<WidgetNode>> _redoStack = [];

  EditorScreen? get _currentScreen {
    if (_viewModel.project == null || _viewModel.selectedScreenId == null) {
      return null;
    }
    try {
      return _viewModel.project!.screens.firstWhere(
        (s) => s.id == _viewModel.selectedScreenId,
      );
    } catch (e) {
      return null;
    }
  }

  WidgetNode? get _selectedWidget {
    if (_currentScreen == null || _viewModel.selectedWidgetId == null) {
      return null;
    }
    try {
      return _currentScreen!.widgets.firstWhere(
        (w) => w.id == _viewModel.selectedWidgetId,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _viewModel = widget.viewModel ?? Dependencies.editorViewModel();
    _viewModel.addListener(_onViewModelChanged);
    _loadProject();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    if (mounted) {
      setState(() {
        _dirty = true;
      });
    }
  }

  Future<void> _loadProject() async {
    final result = await _viewModel.loadProject(widget.project.id);
    if (!mounted) return;
    if (result.error != null) {
      setState(() {
        _loading = false;
        _loadError = result.error?.message ?? 'Unable to open the project editor.';
      });
      return;
    }
    setState(() => _loading = false);
  }

  Future<void> _saveProject() async {
    if (_saving) return;
    setState(() => _saving = true);
    final error = await _viewModel.saveProject();
    if (!mounted) return;
    if (error != null) {
      setState(() => _saving = false);
      _showMessage(error.message);
      return;
    }
    setState(() {
      _saving = false;
      _dirty = false;
    });
    _showMessage('Project saved');
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
    if (_currentScreen == null) return;
    _undoStack.add(List.of(_currentScreen!.widgets));
    if (_undoStack.length > 30) _undoStack.removeAt(0);
    _redoStack.clear();
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(List.of(_currentScreen!.widgets));
    setState(() {
      _viewModel.selectWidget('');
      _dirty = true;
    });
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(List.of(_currentScreen!.widgets));
    setState(() {
      _viewModel.selectWidget('');
      _dirty = true;
    });
  }

  void _deleteSelectedWidget() {
    final selected = _selectedWidget;
    if (selected == null) return;
    _deleteWidgetById(selected.id);
  }

  Future<void> _deleteWidgetById(String id) async {
    _rememberWidgets();
    final error = await _viewModel.removeWidget(id);
    if (error != null) {
      _showMessage(error.message);
    }
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
                _viewModel.project?.name ?? widget.project.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _currentScreen?.name ?? 'main',
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
        endDrawer: _EditorEndDrawer(project: _viewModel.project ?? widget.project),
        body: _buildBody(),
        bottomNavigationBar: _loading
            ? null
            : (_selectedWidget != null && _tabController.index == 0)
                ? _buildWidgetBottomBar()
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
                  onTap: _tabController.index == 3 ? null : () {},
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
                            _currentScreen?.name ?? 'main',
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

  Widget _buildWidgetBottomBar() {
    final widget = _selectedWidget;
    if (widget == null) {
      return _buildEditorBottomBar();
    }
    return Material(
      color: Colors.white,
      elevation: 10,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFEDE9FE),
                foregroundColor: _editorAccent,
                child: Icon(iconForWidget(widget.type)),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.id,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.type.label,
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
                onPressed: () {},
                icon: const Icon(Icons.tune, size: 18),
                label: const Text('See All'),
              ),
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
    final screen = _currentScreen;
    if (screen == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No screens found'),
        ),
      );
    }
    return Row(
      children: [
        // Palette
        SizedBox(
          width: 260,
          child: Material(
            color: Colors.white,
            child: Column(
              children: [
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    children: [
                      _buildPaletteSection('Layout', [
                        WidgetType.column,
                        WidgetType.row,
                        WidgetType.container,
                      ]),
                      _buildPaletteSection('Widgets', [
                        WidgetType.text,
                        WidgetType.button,
                        WidgetType.image,
                        WidgetType.textField,
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Canvas
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
                      child: _buildCanvas(screen, scale),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCanvas(EditorScreen screen, double scale) {
    return Container(
      width: _canvasWidth,
      height: _canvasHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _editorBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: _buildWidgetTree(screen.widgets),
    );
  }

  Widget _buildWidgetTree(List<WidgetNode> widgets) {
    if (widgets.isEmpty) {
      return const Center(
        child: Text('Drag widgets here from the palette'),
      );
    }
    // Build tree based on parentId
    // For MVP, just show a simple Column with all widgets
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: widgets.map((widget) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: InkWell(
            onTap: () {
              _viewModel.selectWidget(widget.id);
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _viewModel.selectedWidgetId == widget.id
                    ? const Color(0xFFEDE9FE)
                    : const Color(0xFFF5F6F8),
                border: Border.all(
                  color: _viewModel.selectedWidgetId == widget.id
                      ? _editorAccent
                      : _editorBorder,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(iconForWidget(widget.type), color: _editorAccent),
                  const SizedBox(width: 8),
                  Text(widget.id),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPaletteSection(String title, List<WidgetType> types) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, right: 8, top: 16, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF707077),
              fontSize: 12,
            ),
          ),
        ),
        ...types.map((type) {
          return _buildPaletteItem(type);
        }),
      ],
    );
  }

  Widget _buildPaletteItem(WidgetType type) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Draggable<WidgetType>(
        data: type,
        feedback: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: _editorBorder),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(iconForWidget(type), color: _editorAccent),
                const SizedBox(width: 8),
                Text(type.label),
              ],
            ),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.5,
          child: _buildPaletteItemContent(type),
        ),
        child: _buildPaletteItemContent(type),
      ),
    );
  }

  Widget _buildPaletteItemContent(WidgetType type) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _editorBorder),
      ),
      child: Row(
        children: [
          Icon(iconForWidget(type), color: _editorAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              type.label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventTab() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('Event editor will be implemented later'),
      ),
    );
  }

  Widget _buildComponentTab() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('Component manager will be implemented later'),
      ),
    );
  }

  Widget _buildStringsTab() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('Strings manager will be implemented later'),
      ),
    );
  }
}

class _EditorEndDrawer extends StatelessWidget {
  const _EditorEndDrawer({required this.project});

  final DevStudioProject project;

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
                          project.name,
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

IconData iconForWidget(WidgetType type) {
  return switch (type) {
    WidgetType.column => Icons.view_column,
    WidgetType.row => Icons.view_stream,
    WidgetType.container => Icons.web_stories,
    WidgetType.text => Icons.text_fields,
    WidgetType.button => Icons.smart_button,
    WidgetType.image => Icons.image,
    WidgetType.textField => Icons.text_snippet,
  };
}
