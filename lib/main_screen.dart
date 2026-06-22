import 'dart:math' as math;

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/project_item.dart';
import 'project_creation_screen.dart';
import 'project_editor_screen.dart';
import 'services/sketchware_project_service.dart';

const mainBackground = Color(0xFFF8F9FA);
const mainSurface = Color(0xFFFFFFFF);
const mainSurfaceSoft = Color(0xFFF2F2F7);
const mainBorder = Color(0xFFE5E5EA);
const mainAccent = Color(0xFF6B5CE7);
const mainAccentSoft = Color(0xFFEDE9FE);
const mainTextPrimary = Color(0xFF1C1C1E);
const mainTextSecondary = Color(0xFF8E8E93);
const mainTextHint = Color(0xFFAEAEB2);
const mainError = Color(0xFFEF4444);

enum _SortField { name, id }

class MainScreen extends StatefulWidget {
  const MainScreen({
    super.key,
    this.initialProjects,
    this.projectService = const SketchwareProjectService(),
  });

  final List<ProjectItem>? initialProjects;
  final SketchwareProjectService projectService;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with RestorationMixin, WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final RestorableInt _selectedPage = RestorableInt(0);
  final RestorableInt _sortField = RestorableInt(_SortField.name.index);
  final RestorableBool _sortAscending = RestorableBool(true);
  final RestorableStringN _pinnedProjectId = RestorableStringN(null);
  final TextEditingController _searchController = TextEditingController();

  late final PageController _pageController;
  late final List<ProjectItem> _projects;
  String _searchQuery = '';
  bool _isSearching = false;
  bool _isLoadingProjects = false;
  bool _needsStorageAccess = false;
  String? _projectLoadError;

  @override
  String? get restorationId => 'dev_studio_main';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_selectedPage, 'selected_page');
    registerForRestoration(_sortField, 'sort_field');
    registerForRestoration(_sortAscending, 'sort_ascending');
    registerForRestoration(_pinnedProjectId, 'pinned_project_id');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pageController.hasClients) {
        _pageController.jumpToPage(_selectedPage.value);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController();
    _projects = List<ProjectItem>.of(widget.initialProjects ?? const []);
    if (widget.initialProjects == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadProjects());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _searchController.dispose();
    _selectedPage.dispose();
    _sortField.dispose();
    _sortAscending.dispose();
    _pinnedProjectId.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.initialProjects == null) {
      _loadProjects();
    }
  }

  Future<void> _loadProjects() async {
    if (widget.initialProjects != null || _isLoadingProjects) return;
    setState(() {
      _isLoadingProjects = true;
      _projectLoadError = null;
    });

    try {
      final hasAccess = await widget.projectService.hasStorageAccess();
      if (!hasAccess) {
        if (!mounted) return;
        setState(() {
          _projects.clear();
          _needsStorageAccess = true;
          _isLoadingProjects = false;
        });
        return;
      }

      final projects = await widget.projectService.loadProjects();
      if (!mounted) return;
      setState(() {
        _projects
          ..clear()
          ..addAll(projects);
        _needsStorageAccess = false;
        _isLoadingProjects = false;
      });
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() {
        _needsStorageAccess = error.code == 'storage_permission_required';
        _projectLoadError = _needsStorageAccess ? null : error.message;
        _isLoadingProjects = false;
      });
    } on MissingPluginException {
      if (!mounted) return;
      setState(() {
        _needsStorageAccess = true;
        _isLoadingProjects = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _projectLoadError = error.toString();
        _isLoadingProjects = false;
      });
    }
  }

  Future<void> _requestStorageAccess() async {
    try {
      await widget.projectService.requestStorageAccess();
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() => _projectLoadError = error.message);
    }
  }

  List<ProjectItem> get _visibleProjects {
    final query = _searchQuery.trim().toLowerCase();
    final projects = _projects.where((project) {
      if (query.isEmpty) return true;
      return project.id.toLowerCase().contains(query) ||
          project.workspaceName.toLowerCase().contains(query) ||
          project.appName.toLowerCase().contains(query) ||
          project.packageName.toLowerCase().contains(query);
    }).toList();

    projects.sort((left, right) {
      final leftPinned = left.id == _pinnedProjectId.value;
      final rightPinned = right.id == _pinnedProjectId.value;
      if (leftPinned != rightPinned) return leftPinned ? -1 : 1;

      final result = _sortField.value == _SortField.name.index
          ? left.workspaceName.toLowerCase().compareTo(
              right.workspaceName.toLowerCase(),
            )
          : _compareProjectIds(left.id, right.id);
      return _sortAscending.value ? result : -result;
    });
    return projects;
  }

  int _compareProjectIds(String left, String right) {
    final leftNumber = int.tryParse(left);
    final rightNumber = int.tryParse(right);
    if (leftNumber != null && rightNumber != null) {
      return leftNumber.compareTo(rightNumber);
    }
    return left.compareTo(right);
  }

  void _selectPage(int page) {
    if (_selectedPage.value == page) return;
    setState(() {
      _selectedPage.value = page;
      if (page != 0) _closeSearch();
    });
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _onPageChanged(int page) {
    if (_selectedPage.value == page) return;
    setState(() {
      _selectedPage.value = page;
      if (page != 0) _closeSearch();
    });
  }

  void _openSearch() {
    setState(() => _isSearching = true);
  }

  void _closeSearch() {
    _searchController.clear();
    _searchQuery = '';
    _isSearching = false;
  }

  Future<void> _refreshProjects() async {
    if (widget.initialProjects != null) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (mounted) setState(() {});
      return;
    }
    await _loadProjects();
  }

  void _ignoreExternalNavigation() {
    // The original Sketchware action starts another Activity or external URL.
    // It is intentionally disabled until that destination exists in Dev Studio.
  }

  Future<void> _openProjectCreation() async {
    final project = await Navigator.push<ProjectItem>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ProjectCreationScreen(projectService: widget.projectService),
      ),
    );
    if (!mounted || project == null) return;

    if (widget.initialProjects == null) {
      await _loadProjects();
    } else {
      setState(() => _projects.add(project));
    }
  }

  Future<void> _openProjectEditor(ProjectItem project) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectEditorScreen(
          project: project,
          projectService: widget.projectService,
        ),
      ),
    );
  }

  Future<void> _showSortDialog() async {
    var selectedField = _SortField.values[_sortField.value];
    var ascending = _sortAscending.value;
    final result = await showDialog<(_SortField, bool)>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Sort options'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _RadioChoice(
                      selected: selectedField == _SortField.name,
                      label: 'Sort by Project Name',
                      onTap: () =>
                          setDialogState(() => selectedField = _SortField.name),
                    ),
                  ),
                  Expanded(
                    child: _RadioChoice(
                      selected: selectedField == _SortField.id,
                      label: 'Sort by ID',
                      onTap: () =>
                          setDialogState(() => selectedField = _SortField.id),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _RadioChoice(
                      selected: ascending,
                      label: 'Ascending (A-Z)',
                      onTap: () => setDialogState(() => ascending = true),
                    ),
                  ),
                  Expanded(
                    child: _RadioChoice(
                      selected: !ascending,
                      label: 'Descending (Z-A)',
                      onTap: () => setDialogState(() => ascending = false),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, (selectedField, ascending)),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _sortField.value = result.$1.index;
      _sortAscending.value = result.$2;
    });
  }

  void _togglePin(ProjectItem project) {
    setState(() {
      _pinnedProjectId.value = _pinnedProjectId.value == project.id
          ? null
          : project.id;
    });
  }

  Future<void> _confirmDelete(ProjectItem project) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.delete_outline, color: mainError),
        title: const Text('Delete project'),
        content: Text('Delete ${project.appName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete', style: TextStyle(color: mainError)),
          ),
        ],
      ),
    );
    if (shouldDelete == true) _ignoreExternalNavigation();
  }

  Future<void> _showProjectOptions(ProjectItem project) async {
    final isPinned = _pinnedProjectId.value == project.id;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: mainSurface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                project.workspaceName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: mainTextPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                project.id,
                style: const TextStyle(color: mainTextSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
              _SheetAction(
                icon: isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                label: isPinned ? 'Unpin project' : 'Pin project',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _togglePin(project);
                },
              ),
              _SheetAction(
                icon: Icons.history,
                label: 'Backup project',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _ignoreExternalNavigation();
                },
              ),
              _SheetAction(
                icon: Icons.ios_share_outlined,
                label: 'Export/Sign',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _ignoreExternalNavigation();
                },
              ),
              _SheetAction(
                icon: Icons.tune,
                label: 'Change project settings',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _ignoreExternalNavigation();
                },
              ),
              _SheetAction(
                icon: Icons.toggle_on_outlined,
                label: 'Project configuration',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _ignoreExternalNavigation();
                },
              ),
              _SheetAction(
                icon: Icons.delete_outline,
                label: 'Delete project',
                destructive: true,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _confirmDelete(project);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: mainBackground,
      drawer: _MainDrawer(
        onItemTap: () {
          Navigator.pop(context);
          _ignoreExternalNavigation();
        },
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _SearchToolbar(
              isSearching: _isSearching,
              showSearchAction: _selectedPage.value == 0,
              controller: _searchController,
              onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
              onOpenSearch: _openSearch,
              onCloseSearch: () => setState(_closeSearch),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                children: [
                  _ProjectsPage(
                    projects: _visibleProjects,
                    pinnedProjectId: _pinnedProjectId.value,
                    isLoading: _isLoadingProjects,
                    needsStorageAccess: _needsStorageAccess,
                    loadError: _projectLoadError,
                    onRefresh: _refreshProjects,
                    onGrantStorageAccess: _requestStorageAccess,
                    onRetryLoad: _loadProjects,
                    onSort: _showSortDialog,
                    onRestore: _ignoreExternalNavigation,
                    onProjectTap: _openProjectEditor,
                    onProjectIconTap: _ignoreExternalNavigation,
                    onProjectOptions: _showProjectOptions,
                  ),
                  _WebServicesPage(onItemTap: _ignoreExternalNavigation),
                  _ChatPage(
                    projects: _visibleProjects,
                    onProjectTap: _ignoreExternalNavigation,
                    onRefresh: _refreshProjects,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _MainBottomNavigation(
        selectedIndex: _selectedPage.value,
        onDestinationSelected: _selectPage,
      ),
      floatingActionButton: _selectedPage.value == 0
          ? FloatingActionButton.extended(
              key: const Key('new-project-fab'),
              onPressed: _openProjectCreation,
              backgroundColor: mainAccent,
              foregroundColor: Colors.white,
              icon: const Icon(CupertinoIcons.add),
              label: const Text('New Project'),
            )
          : null,
    );
  }
}

class _SearchToolbar extends StatelessWidget {
  const _SearchToolbar({
    required this.isSearching,
    required this.showSearchAction,
    required this.controller,
    required this.onOpenDrawer,
    required this.onOpenSearch,
    required this.onCloseSearch,
    required this.onChanged,
  });

  final bool isSearching;
  final bool showSearchAction;
  final TextEditingController controller;
  final VoidCallback onOpenDrawer;
  final VoidCallback onOpenSearch;
  final VoidCallback onCloseSearch;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: mainSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: mainBorder),
      ),
      child: Row(
        children: [
          IconButton(
            key: const Key('open-drawer'),
            onPressed: isSearching ? onCloseSearch : onOpenDrawer,
            icon: Icon(isSearching ? Icons.arrow_back : Icons.menu),
            color: mainTextPrimary,
            tooltip: isSearching ? 'Close search' : 'Open navigation menu',
          ),
          Expanded(
            child: isSearching
                ? TextField(
                    key: const Key('project-search-field'),
                    controller: controller,
                    autofocus: true,
                    onChanged: onChanged,
                    style: const TextStyle(fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Search projects...',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  )
                : const Text(
                    'Search projects...',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: mainTextSecondary, fontSize: 14),
                  ),
          ),
          if (showSearchAction && !isSearching)
            IconButton(
              key: const Key('open-project-search'),
              onPressed: onOpenSearch,
              icon: const Icon(CupertinoIcons.search),
              color: mainTextPrimary,
              tooltip: 'Search',
            ),
          if (isSearching && controller.text.isNotEmpty)
            IconButton(
              onPressed: () {
                controller.clear();
                onChanged('');
              },
              icon: const Icon(Icons.close),
              color: mainTextSecondary,
              tooltip: 'Clear',
            ),
        ],
      ),
    );
  }
}

class _MainBottomNavigation extends StatelessWidget {
  const _MainBottomNavigation({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: mainSurface,
        border: Border(top: BorderSide(color: mainBorder)),
      ),
      child: SafeArea(
        top: false,
        child: NavigationBar(
          height: 72,
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          backgroundColor: mainSurface,
          indicatorColor: mainAccentSoft,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              key: Key('nav-projects'),
              icon: Icon(CupertinoIcons.list_bullet),
              selectedIcon: Icon(CupertinoIcons.list_bullet),
              label: 'Projects',
            ),
            NavigationDestination(
              key: Key('nav-web-service'),
              icon: Icon(CupertinoIcons.globe),
              selectedIcon: Icon(CupertinoIcons.globe),
              label: 'Web Service',
            ),
            NavigationDestination(
              key: Key('nav-chat'),
              icon: Icon(CupertinoIcons.chat_bubble_text),
              selectedIcon: Icon(CupertinoIcons.chat_bubble_text_fill),
              label: 'Chat',
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectsPage extends StatelessWidget {
  const _ProjectsPage({
    required this.projects,
    required this.pinnedProjectId,
    required this.isLoading,
    required this.needsStorageAccess,
    required this.loadError,
    required this.onRefresh,
    required this.onGrantStorageAccess,
    required this.onRetryLoad,
    required this.onSort,
    required this.onRestore,
    required this.onProjectTap,
    required this.onProjectIconTap,
    required this.onProjectOptions,
  });

  final List<ProjectItem> projects;
  final String? pinnedProjectId;
  final bool isLoading;
  final bool needsStorageAccess;
  final String? loadError;
  final Future<void> Function() onRefresh;
  final VoidCallback onGrantStorageAccess;
  final VoidCallback onRetryLoad;
  final VoidCallback onSort;
  final VoidCallback onRestore;
  final ValueChanged<ProjectItem> onProjectTap;
  final VoidCallback onProjectIconTap;
  final ValueChanged<ProjectItem> onProjectOptions;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: mainAccent,
      child: ListView(
        key: const PageStorageKey('projects-list'),
        padding: const EdgeInsets.only(bottom: 112),
        children: [
          _RestoreProjectsCard(onTap: onRestore),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 4, 0),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'My Projects',
                    style: TextStyle(
                      color: mainTextPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('sort-projects'),
                  onPressed: onSort,
                  icon: const Icon(CupertinoIcons.sort_down),
                  color: mainTextSecondary,
                  tooltip: 'Sort options',
                ),
              ],
            ),
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: CircularProgressIndicator(color: mainAccent),
              ),
            )
          else if (needsStorageAccess)
            _ProjectStatusCard(
              icon: CupertinoIcons.folder,
              title: 'Storage access required',
              message:
                  'Allow access so Dev Studio can read .sketchware/mysc/list and display your real projects.',
              actionLabel: 'Allow access',
              onAction: onGrantStorageAccess,
            )
          else if (loadError != null)
            _ProjectStatusCard(
              icon: Icons.error_outline,
              title: 'Could not read projects',
              message: loadError!,
              actionLabel: 'Try again',
              onAction: onRetryLoad,
            )
          else if (projects.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No Sketchware projects found',
                  style: TextStyle(color: mainTextSecondary),
                ),
              ),
            ),
          if (!isLoading && !needsStorageAccess && loadError == null)
            for (final project in projects)
              _ProjectCard(
                project: project,
                pinned: pinnedProjectId == project.id,
                onTap: () => onProjectTap(project),
                onIconTap: onProjectIconTap,
                onOptions: () => onProjectOptions(project),
              ),
        ],
      ),
    );
  }
}

class _RestoreProjectsCard extends StatelessWidget {
  const _RestoreProjectsCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _OutlinedCard(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 82),
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                _SquareIcon(icon: Icons.history),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Restore Projects',
                        style: TextStyle(
                          color: mainTextPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Restore saved backups and imported projects.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: mainTextSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 20,
                  color: mainTextSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProjectStatusCard extends StatelessWidget {
  const _ProjectStatusCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return _OutlinedCard(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SquareIcon(icon: icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: mainTextPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: const TextStyle(
                      color: mainTextSecondary,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: onAction,
                    icon: const Icon(CupertinoIcons.folder_open, size: 18),
                    label: Text(actionLabel),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
    required this.pinned,
    required this.onTap,
    required this.onIconTap,
    required this.onOptions,
  });

  final ProjectItem project;
  final bool pinned;
  final VoidCallback onTap;
  final VoidCallback onIconTap;
  final VoidCallback onOptions;

  @override
  Widget build(BuildContext context) {
    return _OutlinedCard(
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      child: InkWell(
        onTap: onTap,
        onLongPress: onOptions,
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 92),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onIconTap,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: mainSurfaceSoft,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: mainBorder),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(7),
                              child: project.iconBytes != null
                                  ? Image.memory(
                                      project.iconBytes!,
                                      fit: BoxFit.contain,
                                      gaplessPlayback: true,
                                    )
                                  : Image.asset(
                                      'assets/images/default_project_icon.png',
                                      fit: BoxFit.contain,
                                    ),
                            ),
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                height: 18,
                                width: double.infinity,
                                color: Colors.black.withValues(alpha: 0.4),
                                alignment: Alignment.center,
                                child: Text(
                                  project.id,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (pinned)
                        const Positioned(
                          right: -2,
                          top: -2,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: mainAccentSoft,
                              shape: BoxShape.circle,
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.push_pin,
                                color: mainAccent,
                                size: 12,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.appName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: mainTextPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const _Badge(label: 'Native'),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${project.workspaceName} - ${project.versionName} (${project.versionCode})',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: mainTextSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        project.packageName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: mainTextHint,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onOptions,
                  icon: const Icon(Icons.more_horiz),
                  color: mainTextSecondary,
                  tooltip: 'Project settings',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatPage extends StatelessWidget {
  const _ChatPage({
    required this.projects,
    required this.onProjectTap,
    required this.onRefresh,
  });

  final List<ProjectItem> projects;
  final VoidCallback onProjectTap;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: mainAccent,
      child: ListView(
        key: const PageStorageKey('chat-projects-list'),
        padding: const EdgeInsets.only(top: 6, bottom: 96),
        children: [
          for (final project in projects)
            _ChatProjectCard(project: project, onTap: onProjectTap),
          if (projects.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No projects found',
                  style: TextStyle(color: mainTextSecondary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChatProjectCard extends StatelessWidget {
  const _ChatProjectCard({required this.project, required this.onTap});

  final ProjectItem project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _OutlinedCard(
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 82),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: mainSurfaceSoft,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: mainBorder),
                  ),
                  child: project.iconBytes != null
                      ? Image.memory(
                          project.iconBytes!,
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                        )
                      : Image.asset('assets/images/default_project_icon.png'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${project.workspaceName} - ${project.versionName} (${project.versionCode})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: mainTextPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        project.appName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: mainTextSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        project.packageName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: mainTextHint,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          _Badge(label: project.id),
                          const _Badge(label: 'AI chat', accent: true),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  CupertinoIcons.chevron_right,
                  color: mainTextSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WebServicesPage extends StatelessWidget {
  const _WebServicesPage({required this.onItemTap});

  final VoidCallback onItemTap;

  static const services = <(String, String, IconData)>[
    ('JSONPlaceholder', 'jsonplaceholder.typicode.com', Icons.language),
    ('DummyJSON', 'dummyjson.com', Icons.code),
    ('REST Countries', 'restcountries.com', Icons.link),
    ('Open-Meteo', 'open-meteo.com', Icons.cloud_outlined),
    ('Firebase', 'firebase.google.com', Icons.local_fire_department_outlined),
    ('Android Docs', 'developer.android.com', Icons.android),
    ('Material 3', 'developer.android.com', Icons.palette_outlined),
    ('GitHub API', 'docs.github.com', Icons.code_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const PageStorageKey('web-services-list'),
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 28, 16, 10),
          child: Text(
            'APIs and resources',
            style: TextStyle(
              color: mainTextPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        for (final service in services)
          _WebServiceCard(
            title: service.$1,
            subtitle: service.$2,
            icon: service.$3,
            onTap: onItemTap,
          ),
      ],
    );
  }
}

class _WebServiceCard extends StatelessWidget {
  const _WebServiceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _OutlinedCard(
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 82),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _SquareIcon(icon: icon),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: mainTextPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: mainTextSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  CupertinoIcons.chevron_right,
                  color: mainTextSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MainDrawer extends StatelessWidget {
  const _MainDrawer({required this.onItemTap});

  final VoidCallback onItemTap;

  @override
  Widget build(BuildContext context) {
    final width = math.min(MediaQuery.sizeOf(context).width * 0.86, 320.0);
    return Drawer(
      width: width,
      backgroundColor: mainSurface,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
          children: [
            Container(
              constraints: const BoxConstraints(minHeight: 82),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: mainSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: mainBorder),
              ),
              child: const Row(
                children: [
                  _SquareIcon(icon: Icons.lightbulb_outline),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dev Studio',
                          style: TextStyle(
                            color: mainTextPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Project tools and app links',
                          maxLines: 2,
                          style: TextStyle(
                            color: mainTextSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _DrawerItem(
              icon: Icons.groups_outlined,
              label: 'About the team',
              onTap: onItemTap,
            ),
            _DrawerItem(
              icon: Icons.update,
              label: 'Changelog',
              onTap: onItemTap,
            ),
            _DrawerItem(
              icon: Icons.info_outline,
              label: 'App information',
              onTap: onItemTap,
            ),
            _DrawerItem(
              icon: Icons.key_outlined,
              label: 'Create keystore',
              onTap: onItemTap,
            ),
            _DrawerItem(
              icon: Icons.settings_outlined,
              label: 'Settings',
              onTap: onItemTap,
            ),
            const _DrawerSection('Apps'),
            _DrawerItem(
              icon: Icons.auto_awesome_outlined,
              label: 'SwAssist',
              onTap: onItemTap,
            ),
            _DrawerItem(
              icon: Icons.volunteer_activism_outlined,
              label: 'Donate',
              onTap: onItemTap,
            ),
            const _DrawerSection('Related links'),
            _DrawerItem(
              icon: Icons.play_circle_outline,
              label: 'YouTube',
              onTap: onItemTap,
            ),
            _DrawerItem(
              icon: Icons.send_outlined,
              label: 'Telegram',
              onTap: onItemTap,
            ),
            _DrawerItem(icon: Icons.code, label: 'GitHub', onTap: onItemTap),
          ],
        ),
      ),
    );
  }
}

class _DrawerSection extends StatelessWidget {
  const _DrawerSection(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
      child: Text(
        label,
        style: const TextStyle(
          color: mainTextSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minTileHeight: 52,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      leading: Icon(icon, color: mainTextSecondary, size: 22),
      title: Text(
        label,
        style: const TextStyle(color: mainTextPrimary, fontSize: 14),
      ),
      onTap: onTap,
    );
  }
}

class _OutlinedCard extends StatelessWidget {
  const _OutlinedCard({required this.margin, required this.child});

  final EdgeInsetsGeometry margin;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: mainSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: mainBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _SquareIcon extends StatelessWidget {
  const _SquareIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: mainSurfaceSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: mainBorder),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: mainAccent, size: 24),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, this.accent = false});

  final String label;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      constraints: const BoxConstraints(minWidth: 42),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent ? mainAccentSoft : mainSurfaceSoft,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: accent ? mainAccent : mainTextSecondary,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _RadioChoice extends StatelessWidget {
  const _RadioChoice({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? mainAccent : mainTextSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          ],
        ),
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? mainError : mainTextPrimary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 58),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: destructive
                ? mainError.withValues(alpha: 0.06)
                : mainSurfaceSoft,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: destructive
                  ? mainError.withValues(alpha: 0.2)
                  : mainBorder,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: destructive ? mainError : mainAccent, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: color, fontSize: 15),
                ),
              ),
              Icon(CupertinoIcons.chevron_right, color: color, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
