import 'package:flutter/material.dart';

class ViewItemData {
  ViewItemData({
    required this.name,
    this.hasStatusBar = true,
    this.hasToolbar = true,
    this.hasDrawer = false,
    this.hasFAB = false,
    this.type = 'Activity',
    this.orientation = 'Both',
    this.keyboardSetting = 'Unspecified',
  });

  String name;
  bool hasStatusBar;
  bool hasToolbar;
  bool hasDrawer;
  bool hasFAB;
  String type;
  String orientation;
  String keyboardSetting;

  String get xmlName => name.endsWith('.xml') ? name : '$name.xml';
  String get javaName {
    final base = name.replaceAll('.xml', '');
    if (base.isEmpty) return 'MainActivity.java';
    final capitalized = base[0].toUpperCase() + base.substring(1);
    return '${capitalized}Activity.java';
  }
}

// 1. Bottom Sheet List of Views
class ViewManagerSheet extends StatefulWidget {
  const ViewManagerSheet({
    super.key,
    required this.views,
    required this.currentView,
    required this.onSelectView,
    required this.onCreateView,
    required this.accentColor,
  });

  final List<ViewItemData> views;
  final ViewItemData currentView;
  final ValueChanged<ViewItemData> onSelectView;
  final ValueChanged<ViewItemData> onCreateView;
  final Color accentColor;

  @override
  State<ViewManagerSheet> createState() => _ViewManagerSheetState();
}

class _ViewManagerSheetState extends State<ViewManagerSheet> {
  bool _isCustomView = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      // SafeArea (somente bottom) mantém o sheet branco colado na borda da
      // tela, mas empurra o CONTEÚDO para cima da barra de navegação/gesto
      // do sistema -- antes o botão "Create new view" ficava atrás dela.
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
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

              // View / Custom View Switcher Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildToggleOption('View', !_isCustomView),
                  _buildToggleOption('Custom View', _isCustomView),
                ],
              ),
              const SizedBox(height: 18),

              // Views List
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: ListView(
                  shrinkWrap: true,
                  children: widget.views.map((view) {
                    final isCurrent = view.name == widget.currentView.name;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isCurrent ? widget.accentColor : const Color(0xFFE2E3E8),
                          width: isCurrent ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F2F7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.phone_android, color: Colors.black54),
                        ),
                        title: Text(view.xmlName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(view.javaName, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                        trailing: isCurrent
                            ? Icon(Icons.check_circle, color: widget.accentColor)
                            : const Icon(Icons.edit, color: Colors.black54),
                        onTap: () {
                          widget.onSelectView(view);
                          Navigator.pop(context);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 14),

              // Create new view button
              FilledButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  final newView = await showGeneralDialog<ViewItemData>(
                    context: context,
                    barrierDismissible: true,
                    barrierLabel: 'Create View',
                    pageBuilder: (context, anim1, anim2) {
                      return CreateViewScreen(accentColor: widget.accentColor);
                    },
                  );
                  if (newView != null) {
                    widget.onCreateView(newView);
                  }
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: widget.accentColor,
                ),
                icon: const Icon(Icons.add),
                label: const Text('Create new view'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleOption(String label, bool active) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isCustomView = label == 'Custom View'),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? widget.accentColor : const Color(0xFFF2F2F7),
            borderRadius: label == 'View'
                ? const BorderRadius.horizontal(left: Radius.circular(20))
                : const BorderRadius.horizontal(right: Radius.circular(20)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

// 2. Create View Full-Screen Form with live mockup preview
class CreateViewScreen extends StatefulWidget {
  const CreateViewScreen({super.key, required this.accentColor});

  final Color accentColor;

  @override
  State<CreateViewScreen> createState() => _CreateViewScreenState();
}

class _CreateViewScreenState extends State<CreateViewScreen> {
  final _nameController = TextEditingController();

  bool _statusBar = true;
  bool _toolbar = true;
  bool _drawer = false;
  bool _fab = false;

  String _type = 'Activity';
  String _orientation = 'Both';
  String _keyboard = 'Unspecified';

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Create new', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: live phone mockup preview (left) next to the
              // StatusBar/Toolbar/Drawer/FAB checklist (right). Both sit
              // inside the SAME scrolling column and are top-aligned, so
              // the preview no longer floats inside an oversized,
              // independently-sized split column (the original bug).
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 130,
                    height: 230,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFC7C7CC), width: 3),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 16),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          // Background content area
                          Positioned.fill(
                            child: Column(
                              children: [
                                // Status Bar Mockup
                                if (_statusBar)
                                  Container(
                                    height: 24,
                                    color: Colors.blue.shade800,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('1:56', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                        Icon(Icons.signal_cellular_4_bar, color: Colors.white, size: 10),
                                      ],
                                    ),
                                  ),
                                // Toolbar Mockup
                                if (_toolbar)
                                  Container(
                                    height: 40,
                                    color: Colors.blue,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.arrow_back, color: Colors.white, size: 18),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            _nameController.text.isEmpty ? 'Activity' : _nameController.text,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                // Canvas Body Mockup
                                Expanded(
                                  child: Container(
                                    color: const Color(0xFFECEFF1),
                                    child: Center(
                                      child: Text(
                                        _type,
                                        style: const TextStyle(color: Colors.black26, fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Drawer Mockup overlay
                          if (_drawer)
                            Positioned(
                              left: 0,
                              top: _statusBar ? 24 : 0,
                              bottom: 0,
                              width: 90,
                              child: Container(
                                color: Colors.white,
                                child: const Column(
                                  children: [
                                    SizedBox(height: 12),
                                    CircleAvatar(radius: 16, child: Icon(Icons.android, size: 16)),
                                    SizedBox(height: 8),
                                    Divider(height: 1),
                                  ],
                                ),
                              ),
                            ),

                          // FAB Mockup overlay
                          if (_fab)
                            Positioned(
                              right: 8,
                              bottom: 8,
                              child: FloatingActionButton(
                                onPressed: null,
                                backgroundColor: Colors.pink,
                                mini: true,
                                child: const Icon(Icons.add, color: Colors.white, size: 16),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        _buildOptionCheckbox('StatusBar', _statusBar, (val) => setState(() => _statusBar = val ?? true)),
                        _buildOptionCheckbox('Toolbar', _toolbar, (val) => setState(() => _toolbar = val ?? true)),
                        _buildOptionCheckbox('Drawer', _drawer, (val) => setState(() => _drawer = val ?? false)),
                        _buildOptionCheckbox('FAB', _fab, (val) => setState(() => _fab = val ?? false)),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Name input
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Enter name',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => setState(() {}),
              ),

              const SizedBox(height: 20),

              // Type segmented control
              _buildSegmentHeader('Type'),
              Row(
                children: [
                  _buildSegmentButton('Type', 'Activity'),
                  const SizedBox(width: 8),
                  _buildSegmentButton('Type', 'Fragment'),
                  const SizedBox(width: 8),
                  _buildSegmentButton('Type', 'DialogFragment'),
                ],
              ),

              const SizedBox(height: 20),

              // Orientation control
              _buildSegmentHeader('Screen orientation'),
              Row(
                children: [
                  _buildSegmentButton('Orientation', 'Portrait'),
                  const SizedBox(width: 8),
                  _buildSegmentButton('Orientation', 'Landscape'),
                  const SizedBox(width: 8),
                  _buildSegmentButton('Orientation', 'Both'),
                ],
              ),

              const SizedBox(height: 20),

              // Keyboard settings
              _buildSegmentHeader('Keyboard settings'),
              Row(
                children: [
                  _buildSegmentButton('Keyboard', 'Unspecified'),
                  const SizedBox(width: 8),
                  _buildSegmentButton('Keyboard', 'Visible'),
                  const SizedBox(width: 8),
                  _buildSegmentButton('Keyboard', 'Hidden'),
                ],
              ),

              const SizedBox(height: 32),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        final name = _nameController.text.trim();
                        if (name.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a view name.')),
                          );
                          return;
                        }
                        final view = ViewItemData(
                          name: name,
                          hasStatusBar: _statusBar,
                          hasToolbar: _toolbar,
                          hasDrawer: _drawer,
                          hasFAB: _fab,
                          type: _type,
                          orientation: _orientation,
                          keyboardSetting: _keyboard,
                        );
                        Navigator.pop(context, view);
                      },
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: widget.accentColor,
                      ),
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCheckbox(String label, bool value, ValueChanged<bool?> onChanged) {
    return CheckboxListTile(
      value: value,
      onChanged: onChanged,
      title: Text(label),
      controlAffinity: ListTileControlAffinity.trailing,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }

  Widget _buildSegmentHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54),
      ),
    );
  }

  Widget _buildSegmentButton(String category, String value) {
    String currentSelected = '';
    if (category == 'Type') currentSelected = _type;
    if (category == 'Orientation') currentSelected = _orientation;
    if (category == 'Keyboard') currentSelected = _keyboard;

    final isSelected = currentSelected == value;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            if (category == 'Type') _type = value;
            if (category == 'Orientation') _orientation = value;
            if (category == 'Keyboard') _keyboard = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2E2E38) : Colors.transparent,
            border: Border.all(color: const Color(0xFFC7C7CC)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
