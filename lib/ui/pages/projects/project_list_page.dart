
import 'dart:math' as math;

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:dev_studio/core/config/dependencies.dart';
import 'package:dev_studio/domain/common/project/project_summary.dart';
import 'package:dev_studio/domain/common/project/dev_studio_project.dart';
import 'package:dev_studio/ui/pages/editor/editor_page.dart';
import 'package:dev_studio/ui/pages/projects/project_create_page.dart';
import 'package:dev_studio/ui/pages/projects/viewmodel/project_list_viewmodel.dart';

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

class ProjectListPage extends StatefulWidget {
  const ProjectListPage({
    super.key,
    this.initialProjects,
    this.viewModel,
  });

  final List<ProjectSummary>? initialProjects;
  final ProjectListViewModel? viewModel;

  @override
  State<ProjectListPage> createState() => _ProjectListPageState();
}

class _ProjectListPageState extends State<ProjectListPage>
    with RestorationMixin, WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final RestorableInt _selectedPage = RestorableInt(0);
  final RestorableInt _sortField = RestorableInt(_SortField.name.index);
  final RestorableBool _sortAscending = RestorableBool(true);
  final RestorableStringN _pinnedProjectId = RestorableStringN(null);
  final TextEditingController _searchController = TextEditingController();

  late final PageController _pageController;
  late final ProjectListViewModel _viewModel;
  late final List<ProjectSummary> _projects;
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
    _viewModel = widget.viewModel ?? Dependencies.projectListViewModel();
    _projects = List<ProjectSummary>.of(widget.initialProjects ?? const []);
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

    final state = await _viewModel.loadProjects();
    if (!mounted) return;
    setState(() {
      _projects
        ..clear()
        ..addAll(state.projects);
      _needsStorageAccess = state.needsStorageAccess;
      _projectLoadError = state.needsStorageAccess ? null : state.error?.message;
      _isLoadingProjects = false;
    });
  }

  Future<void> _requestStorageAccess() async {
    final error = await _viewModel.requestStorageAccess();
    if (!mounted || error == null) return;
    setState(() => _projectLoadError = error.message);
  }

  List<ProjectSummary> get _visibleProjects {
    final query = _searchQuery.trim().toLowerCase();
    final projects = _projects.where((project) {
      if (query.isEmpty) return true;
      return project.id.toLowerCase().contains(query) ||
          project.name.toLowerCase().contains(query) ||
          project.packageName.toLowerCase().contains(query);
    }).toList();

    projects.sort((left, right) {
      final leftPinned = left.id == _pinnedProjectId.value;
      final rightPinned = right.id == _pinnedProjectId.value;
      if (leftPinned != rightPinned) return leftPinned ? -1 : 1;

      final result = _sortField.value == _SortField.name.index
          ? left.name.toLowerCase().compareTo(right.name.toLowerCase())
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
    final project = await Navigator.push<DevStudioProject>(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectCreatePage(
          viewModel: Dependencies.projectCreateViewModel(),
        ),
      ),
    );
    if (!mounted || project == null) return;

    if (widget.initialProjects == null) {
      await _loadProjects();
    }
  }

  Future<void> _openProjectEditor(ProjectSummary project) async {
    final result = await _viewModel.openProject(project.id);
    if (!mounted) return;
    if (result.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error!.message)),
      );
      return;
    }
    if (result.project == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to open project')),
      );
      return;
    }
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => EditorPage(
          project: result.project!,
          viewModel: Dependencies.editorViewModel(),
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

  void _togglePin(ProjectSummary project) {
    setState(() {
      _pinnedProjectId.value = _pinnedProjectId.value == project.id
          ? null
          : project.id;
    });
  }

  Future<void> _confirmDelete(ProjectSummary project) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.delete_outline, color: mainError),
        title: const Text('Delete project'),
        content: Text('Delete ${project.name}?'),
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

  Future<void> _showProjectOptions(ProjectSummary project) async {
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
                project.name,
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
                    onProjectOptions: _showProjectOptions,
                  ),
                  _WebServicesPage(onItemTap: _ignoreExternalNavigation),
                  _ChatPage(
                    projects: _visibleProjects,
                    onProjectTap: _openProjectEditor,
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
    required this.onProjectOptions,
  });

  final List<ProjectSummary> projects;
  final String? pinnedProjectId;
  final bool isLoading;
  final bool needsStorageAccess;
  final String? loadError;
  final Future<void> Function() onRefresh;
  final VoidCallback onGrantStorageAccess;
  final VoidCallback onRetryLoad;
  final VoidCallback onSort;
  final VoidCallback onRestore;
  final ValueChanged<ProjectSummary> onProjectTap;
  final ValueChanged<ProjectSummary> onProjectOptions;

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
                  'No projects found',
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
    required this.onOptions,
  });

  final ProjectSummary project;
  final bool pinned;
  final VoidCallback onTap;
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
                Stack(
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
                      child: const Icon(
                        Icons.folder,
                        color: mainAccent,
                        size: 32,
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
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.name,
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
                          const _Badge(label: 'Dev Studio'),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${project.versionName} (${project.versionCode})',
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

  final List<ProjectSummary> projects;
  final ValueChanged<ProjectSummary> onProjectTap;
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
            _ChatProjectCard(
              project: project,
              onTap: () => onProjectTap(project),
            ),
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

  final ProjectSummary project;
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
                  child: const Icon(Icons.folder, color: mainAccent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${project.name} - ${project.versionName}',
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
                        project.name,
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
                        style: const TextStyle(
                          color: mainTextPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
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

class _OutlinedCard extends StatelessWidget {
  const _OutlinedCard({required this.child, this.margin});

  final Widget child;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: mainSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: mainBorder),
      ),
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
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: mainAccentSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: mainAccent, size: 26),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: selected ? mainAccent : mainTextSecondary,
            ),
            const SizedBox(width: 8),
            Text(label),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: destructive ? mainError : mainAccent,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: destructive ? mainError : mainTextPrimary,
              ),
            ),
          ],
        ),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accent ? mainAccentSoft : mainSurfaceSoft,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: accent ? mainAccent : mainTextSecondary,
          fontSize: 11,
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
          (Icons.code, 'Java/Kotlin manager', 'Project source files'),
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
      backgroundColor: mainBackground,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: mainSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: mainBorder),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: mainAccentSoft,
                    foregroundColor: mainAccent,
                    child: Icon(Icons.developer_mode),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dev Studio',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Visual app development',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: mainTextSecondary,
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
                    color: mainTextSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: mainSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: mainBorder),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: section.$2.map((item) {
                    return WidgetListTile(
                      icon: item.$1,
                      title: item.$2,
                      subtitle: item.$3,
                      onTap: onItemTap,
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
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: mainAccent),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12),
      ),
      onTap: onTap,
    );
  }
}

