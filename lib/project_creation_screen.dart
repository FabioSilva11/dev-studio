import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'services/sketchware_project_service.dart';

class ProjectCreationScreen extends StatefulWidget {
  const ProjectCreationScreen({
    super.key,
    this.projectService = const SketchwareProjectService(),
  });

  final SketchwareProjectService projectService;

  @override
  State<ProjectCreationScreen> createState() => _ProjectCreationScreenState();
}

class _ProjectCreationScreenState extends State<ProjectCreationScreen> {
  static const _accent = Color(0xFF6B5CE7);
  static const _background = Color(0xFFF8F9FA);
  static const _border = Color(0xFFE5E5EA);
  static const _reservedWords = <String>{
    'abstract',
    'boolean',
    'break',
    'byte',
    'case',
    'catch',
    'char',
    'class',
    'const',
    'continue',
    'default',
    'do',
    'double',
    'else',
    'extends',
    'final',
    'finally',
    'float',
    'for',
    'goto',
    'if',
    'implements',
    'import',
    'instanceof',
    'int',
    'interface',
    'long',
    'native',
    'new',
    'package',
    'private',
    'protected',
    'public',
    'return',
    'short',
    'static',
    'super',
    'switch',
    'synchronized',
    'this',
    'throw',
    'throws',
    'transient',
    'try',
    'void',
    'volatile',
    'while',
    'true',
    'false',
    'null',
    'Override',
    'Deprecated',
    'Activity',
    'Bundle',
    'LayoutInfater',
    'Toolbar',
    'DrawerLayout',
    'FloatingActionButton',
    'View',
    'Context',
    'EditText',
    'onCreate',
    'onClick',
    'LinearLayout',
    'FrameLayout',
    'RelativeLayout',
    'TextView',
    'Spinner',
    'CheckBox',
    'WebView',
    'CalendarView',
    'ImageView',
    'Button',
    'ArrayList',
    'String',
    'Intent',
    'SharedPreferences',
    'Calendar',
    'none',
    'SeekBar',
    'Switch',
    'root',
    'R',
    'gyroscope',
    'FirebaseDatabase',
    'DatabaseReference',
    'FirebaseStorage',
    'StorageReference',
    'File',
    'AdView',
    'RequestNetwork',
    'MediaController',
    'NetworkRequest',
    'RequestNetworkController',
    'ProgressBar',
    'TextToSpeech',
    'SpeechRecognizer',
    'BluetoothConnect',
    'BluetoothController',
    'GoogleMapController',
    'MapView',
    'GoogleMap',
    'LocationListener',
    'LocationManager',
    'ProgressDialog',
    'RewardedVideoAd',
    'DatePickerDialog',
    'TimePickerDialog',
    'Notification',
    'ListView',
    'CardView',
    'GridView',
    'VideoView',
    'SearchView',
    'RadioButton',
    'RatingBar',
    'DatePicker',
    'TimePicker',
    'DigitalClock',
    'AnalogClock',
    'RecyclerView',
    'ViewPager',
    'SwipeRefreshLayout',
    'CoordinatorLayout',
    'TabLayout',
    'TextInputLayout',
    'BottomNavigationView',
    'ImageButton',
    'ShimmerButton',
    'ShimmerTextView',
    'CircleImageView',
    'AutoCompleteTextView',
    'MultiAutoCompleteTextView',
    'BadgeView',
    'BubbleLayout',
    'PatternLockView',
    'WaveSideBar',
    'BottomAppBar',
    'BottomSheetBehavior',
    'NavigationView',
    'NestedScrollView',
    'CollapsingToolbarLayout',
    'AppBarLayout',
  };

  final _formKey = GlobalKey<FormState>();
  final _appNameController = TextEditingController();
  final _projectNameController = TextEditingController();
  final _packageController = TextEditingController();
  final _versionCodeController = TextEditingController();
  final _versionNameController = TextEditingController();

  ProjectCreationDefaults? _defaults;
  Uint8List? _iconBytes;
  List<Color> _colors = const [];
  bool _loading = true;
  bool _saving = false;
  bool _showColorGuide = false;
  String? _selectedThemeName;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadDefaults();
  }

  @override
  void dispose() {
    _appNameController.dispose();
    _projectNameController.dispose();
    _packageController.dispose();
    _versionCodeController.dispose();
    _versionNameController.dispose();
    super.dispose();
  }

  Future<void> _loadDefaults() async {
    try {
      final defaults = await widget.projectService.getProjectCreationDefaults();
      if (!mounted) return;
      _appNameController.clear();
      _projectNameController.text = defaults.projectName;
      _packageController.text = defaults.packageName;
      _versionCodeController.text = defaults.versionCode;
      _versionNameController.text = defaults.versionName;
      setState(() {
        _defaults = defaults;
        _colors = defaults.colors
            .map((value) => Color(value & 0xFFFFFFFF))
            .toList(growable: false);
        _loading = false;
      });
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.message ?? 'Unable to prepare a new project.';
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _selectIcon() async {
    try {
      final iconBytes = await widget.projectService.pickProjectIcon();
      if (mounted && iconBytes != null) {
        setState(() => _iconBytes = iconBytes);
      }
    } on PlatformException catch (error) {
      _showMessage(error.message ?? 'Unable to load the selected icon.');
    }
  }

  Future<void> _save() async {
    if (_saving || _defaults == null) return;
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final versionCode = int.tryParse(_versionCodeController.text);
    final versionNameIsValid = RegExp(
      r'^[0-9]+(?:\.[0-9]+)*(?: [A-Za-z0-9_]+)?$',
    ).hasMatch(_versionNameController.text);
    if (versionCode == null || versionCode < 1 || !versionNameIsValid) {
      _showMessage('Check the version code and version name.');
      return;
    }

    setState(() => _saving = true);
    try {
      final project = await widget.projectService.createProject(
        defaults: _defaults!,
        appName: _appNameController.text,
        projectName: _projectNameController.text,
        packageName: _packageController.text,
        versionCode: _versionCodeController.text.trim(),
        versionName: _versionNameController.text.trim(),
        colors: _colors.map((color) => color.toARGB32()).toList(),
        iconBytes: _iconBytes,
      );
      if (mounted) Navigator.pop(context, project);
    } on PlatformException catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        _showMessage(error.message ?? 'Unable to create the project.');
      }
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        _showMessage(error.toString());
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String? _validateAppName(String? rawValue) {
    final value = rawValue?.trim() ?? '';
    if (value.isEmpty) return 'Enter the application name';
    if (value.length > 50) return 'Use no more than 50 characters';
    if (RegExp('[&"\'<>]').hasMatch(value)) {
      return 'Do not use &, quotes, <, or >';
    }
    return null;
  }

  String? _validateProjectName(String? rawValue) {
    final value = rawValue ?? '';
    if (!RegExp(r'^[A-Za-z][A-Za-z0-9_]{0,19}$').hasMatch(value)) {
      return 'Start with a letter; use up to 20 letters, numbers, or _';
    }
    return null;
  }

  String? _validatePackage(String? rawValue) {
    final value = rawValue ?? '';
    if (value.length > 50) return 'Use no more than 50 characters';
    final segments = value.split('.');
    if (segments.length < 2 ||
        segments.any(
          (segment) =>
              !RegExp(r'^[A-Za-z][A-Za-z0-9]*$').hasMatch(segment) ||
              _reservedWords.contains(segment),
        )) {
      return 'Enter a valid package, such as com.my.application';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildToolbar(),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
        bottomNavigationBar: _loading || _loadError != null
            ? null
            : _buildBottomActions(),
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      height: 62,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _saving ? null : () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back',
          ),
          const SizedBox(width: 4),
          const Text(
            'New Project',
            style: TextStyle(
              color: Color(0xFF1C1C1E),
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _saving ? null : () => Navigator.maybePop(context),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: const Color(0xFFF0EDFF),
                    foregroundColor: const Color(0xFF34323C),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  key: const Key('save-project'),
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                  ),
                  child: _saving
                      ? const SizedBox.square(
                          dimension: 19,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Create'),
                ),
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
                size: 44,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 12),
              Text(_loadError!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _loadError = null;
                  });
                  _loadDefaults();
                },
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    return Form(
      key: _formKey,
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 26, 16, 32),
        children: [
          _buildIconPicker(),
          const SizedBox(height: 34),
          _field(
            key: const Key('application-name'),
            controller: _appNameController,
            label: 'Application name',
            hintText: 'Enter application name',
            icon: Icons.smartphone_outlined,
            validator: _validateAppName,
            maxLength: 50,
          ),
          _field(
            key: const Key('package-name'),
            controller: _packageController,
            label: 'Package name',
            icon: Icons.inventory_2_outlined,
            validator: _validatePackage,
            maxLength: 50,
            textCapitalization: TextCapitalization.none,
          ),
          _field(
            key: const Key('project-name'),
            controller: _projectNameController,
            label: 'Project name',
            icon: Icons.favorite_border,
            validator: _validateProjectName,
            maxLength: 20,
          ),
          const SizedBox(height: 4),
          _buildThemeColorsCard(),
          const SizedBox(height: 13),
          _buildThemePresets(),
          const SizedBox(height: 13),
          _buildVersionCard(),
        ],
      ),
    );
  }

  Widget _buildIconPicker() {
    return Center(
      child: Column(
        children: [
          InkWell(
            key: const Key('project-icon-picker'),
            onTap: _selectIcon,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 72,
              height: 72,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border),
              ),
              child: _iconBytes == null
                  ? Image.asset(
                      'assets/images/default_sketchware_project_icon.png',
                      fit: BoxFit.contain,
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: Image.memory(_iconBytes!, fit: BoxFit.cover),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _selectIcon,
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              child: Text(
                'Tap to change Icon',
                style: TextStyle(fontSize: 12, color: _accent),
              ),
            ),
          ),
          if (_iconBytes != null)
            TextButton(
              onPressed: () => setState(() => _iconBytes = null),
              child: const Text('Use default icon'),
            ),
        ],
      ),
    );
  }

  Widget _buildThemeColorsCard() {
    const labels = [
      'colorAccent',
      'colorPrimary',
      'colorPrimaryDark',
      'colorControlHighlight',
      'colorControlNormal',
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SizedBox(
            height: 94,
            child: Row(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    scrollDirection: Axis.horizontal,
                    itemCount: _colors.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) => _ThemeColorTile(
                      label: labels[index],
                      color: _colors[index],
                      onTap: () => _editColor(index),
                    ),
                  ),
                ),
                const VerticalDivider(
                  width: 1,
                  indent: 12,
                  endIndent: 12,
                  color: _border,
                ),
                SizedBox(
                  width: 52,
                  child: IconButton(
                    key: const Key('theme-color-help'),
                    onPressed: () {
                      setState(() => _showColorGuide = !_showColorGuide);
                    },
                    icon: Icon(
                      _showColorGuide ? Icons.help : Icons.help_outline,
                      color: const Color(0xFF77777E),
                    ),
                    tooltip: 'Color guide',
                  ),
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: _showColorGuide
                ? ColoredBox(
                    color: Colors.black,
                    child: Image.asset(
                      'assets/images/color_guide.png',
                      width: double.infinity,
                      fit: BoxFit.fitWidth,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _field({
    Key? key,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
    int? maxLength,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.sentences,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        key: key,
        controller: controller,
        validator: validator,
        onChanged: onChanged,
        maxLength: maxLength,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        textCapitalization: textCapitalization,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          counterText: '',
          prefixIcon: Icon(icon, size: 20),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _accent, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildThemePresets() {
    const palettes = <(String, List<int>)>[
      (
        'Material Purple',
        [0xFF03DAC5, 0xFF6200EE, 0xFF3700B3, 0xFFE8EAF6, 0xFFBDBDBD],
      ),
      (
        'Material Blue',
        [0xFF03DAC5, 0xFF1976D2, 0xFF0D47A1, 0xFFE3F2FD, 0xFFBDBDBD],
      ),
      (
        'Material Green',
        [0xFF03DAC5, 0xFF388E3C, 0xFF1B5E20, 0xFFE8F5E8, 0xFFBDBDBD],
      ),
      (
        'Material Red',
        [0xFF03DAC5, 0xFFD32F2F, 0xFFB71C1C, 0xFFFFEBEE, 0xFFBDBDBD],
      ),
      (
        'Material Orange',
        [0xFF03DAC5, 0xFFF57C00, 0xFFE65100, 0xFFFFF3E0, 0xFFBDBDBD],
      ),
      (
        'Material Teal',
        [0xFF03DAC5, 0xFF00796B, 0xFF004D40, 0xFFE0F2F1, 0xFFBDBDBD],
      ),
      (
        'Material Indigo',
        [0xFF03DAC5, 0xFF3F51B5, 0xFF1A237E, 0xFFE8EAF6, 0xFFBDBDBD],
      ),
      (
        'Material Pink',
        [0xFF03DAC5, 0xFFC2185B, 0xFF880E4F, 0xFFFCE4EC, 0xFFBDBDBD],
      ),
      (
        'Dark Purple',
        [0xFF03DAC5, 0xFFBB86FC, 0xFF3700B3, 0xFF1F1F1F, 0xFF666666],
      ),
      (
        'Dark Blue',
        [0xFF03DAC5, 0xFF64B5F6, 0xFF1976D2, 0xFF1F1F1F, 0xFF666666],
      ),
      (
        'Light Purple',
        [0xFF03DAC5, 0xFF6200EE, 0xFF3700B3, 0xFFF3E5F5, 0xFFE1BEE7],
      ),
      (
        'Light Blue',
        [0xFF03DAC5, 0xFF1976D2, 0xFF0D47A1, 0xFFE3F2FD, 0xFFBBDEFB],
      ),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.palette_outlined, color: _accent, size: 23),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Theme Presets',
                  maxLines: 1,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              FilledButton(
                onPressed: _generateRandomTheme,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 42),
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                  backgroundColor: Colors.white,
                  foregroundColor: _accent,
                  elevation: 2,
                  shadowColor: Colors.black26,
                  shape: const StadiumBorder(),
                ),
                child: const Text(
                  'Generate Random',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: _resetTheme,
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF0EDFF),
                  foregroundColor: const Color(0xFF1C1C1E),
                ),
                icon: const Icon(Icons.refresh, size: 25),
                tooltip: 'Reset theme',
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Choose from predefined themes or generate a random one',
            style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 112,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: palettes.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final palette = palettes[index];
                final colors = palette.$2.map(Color.new).toList();
                return _ThemePresetTile(
                  name: palette.$1,
                  colors: colors,
                  selected: _selectedThemeName == palette.$1,
                  onTap: () {
                    setState(() {
                      _colors = colors;
                      _selectedThemeName = palette.$1;
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _resetTheme() {
    final defaults = _defaults;
    if (defaults == null) return;
    setState(() {
      _colors = defaults.colors
          .map((value) => Color(value & 0xFFFFFFFF))
          .toList();
      _selectedThemeName = null;
    });
  }

  void _generateRandomTheme() {
    final random = math.Random();
    final primaryHsv = HSVColor.fromAHSV(
      1,
      random.nextDouble() * 360,
      0.6 + random.nextDouble() * 0.3,
      0.5 + random.nextDouble() * 0.4,
    );
    final primary = primaryHsv.toColor();
    final primaryDark = primaryHsv.withValue(primaryHsv.value * 0.7).toColor();
    final accent = HSVColor.fromAHSV(
      1,
      (primaryHsv.hue + 180) % 360,
      0.7 + random.nextDouble() * 0.2,
      0.8 + random.nextDouble() * 0.2,
    ).toColor();
    final highlight = primaryHsv
        .withSaturation(math.max(0.0, primaryHsv.saturation - 0.45))
        .withValue(math.min(1.0, primaryHsv.value + 0.9))
        .toColor();
    setState(() {
      _colors = [
        accent,
        primary,
        primaryDark,
        highlight,
        const Color(0xFF888888),
      ];
      _selectedThemeName = null;
    });
  }

  Widget _buildVersionCard() {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: _border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const Key('version-settings'),
        onTap: _showVersionEditor,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      _versionCodeController.text,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Version code',
                      style: TextStyle(color: Color(0xFF8E8E93), fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.call_split, color: _accent, size: 25),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      _versionNameController.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Version name',
                      style: TextStyle(color: Color(0xFF8E8E93), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showVersionEditor() async {
    final formKey = GlobalKey<FormState>();
    final codeController = TextEditingController(
      text: _versionCodeController.text,
    );
    final nameController = TextEditingController(
      text: _versionNameController.text,
    );
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.numbers, color: _accent),
        title: const Text('Version Control'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: codeController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Version code',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final code = int.tryParse(value ?? '');
                  return code == null || code < 1
                      ? 'Enter a positive number'
                      : null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: nameController,
                textCapitalization: TextCapitalization.none,
                decoration: const InputDecoration(
                  labelText: 'Version name',
                  hintText: '1.0 or 1.0 beta',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    RegExp(
                      r'^[0-9]+(?:\.[0-9]+)*(?: [A-Za-z0-9_]+)?$',
                    ).hasMatch(value ?? '')
                    ? null
                    : 'Use numbers, dots and an optional postfix',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (shouldSave == true && mounted) {
      setState(() {
        _versionCodeController.text = codeController.text;
        _versionNameController.text = nameController.text;
      });
    }
    codeController.dispose();
    nameController.dispose();
  }

  Future<void> _editColor(int index) async {
    var argb = _colors[index].toARGB32();
    var red = ((argb >> 16) & 0xFF).toDouble();
    var green = ((argb >> 8) & 0xFF).toDouble();
    var blue = (argb & 0xFF).toDouble();

    final selected = await showDialog<Color>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final color = Color.fromARGB(
            255,
            red.round(),
            green.round(),
            blue.round(),
          );
          return AlertDialog(
            title: const Text('Choose color'),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 70,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _border),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _channelSlider('R', red, Colors.red, (value) {
                      setDialogState(() => red = value);
                    }),
                    _channelSlider('G', green, Colors.green, (value) {
                      setDialogState(() => green = value);
                    }),
                    _channelSlider('B', blue, Colors.blue, (value) {
                      setDialogState(() => blue = value);
                    }),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, color),
                child: const Text('Use color'),
              ),
            ],
          );
        },
      ),
    );
    if (selected != null && mounted) {
      setState(() {
        _colors[index] = selected;
        _selectedThemeName = null;
      });
    }
  }

  Widget _channelSlider(
    String label,
    double value,
    Color color,
    ValueChanged<double> onChanged,
  ) {
    return Row(
      children: [
        SizedBox(width: 18, child: Text(label)),
        Expanded(
          child: Slider(
            value: value,
            min: 0,
            max: 255,
            activeColor: color,
            onChanged: onChanged,
          ),
        ),
        SizedBox(width: 30, child: Text(value.round().toString())),
      ],
    );
  }
}

class _ThemeColorTile extends StatelessWidget {
  const _ThemeColorTile({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7F7FB),
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 112,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E5EA)),
                ),
              ),
              const SizedBox(height: 5),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemePresetTile extends StatelessWidget {
  const _ThemePresetTile({
    required this.name,
    required this.colors,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final List<Color> colors;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7F7FB),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: selected ? const Color(0xFF6B5CE7) : const Color(0xFFE5E5EA),
          width: selected ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 112,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E5EA)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: colors
                        .map(
                          (color) => Expanded(child: ColoredBox(color: color)),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected
                        ? const Color(0xFF6B5CE7)
                        : const Color(0xFF8E8E93),
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
