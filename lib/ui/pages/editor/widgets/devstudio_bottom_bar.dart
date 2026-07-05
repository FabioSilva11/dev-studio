import 'package:flutter/material.dart';
import 'package:dev_studio/domain/common/editor/editor_project.dart';
import 'editor_palette.dart'; // to reuse iconForWidget

class DevStudioBottomBar extends StatefulWidget {
  const DevStudioBottomBar({
    super.key,
    required this.widgets,
    required this.selectedWidget,
    required this.onSelect,
    required this.onDelete,
    required this.onSave,
    required this.onSeeAll,
    required this.onUpdateWidget,
    required this.accentColor,
  });

  final List<EditorWidgetNode> widgets;
  final EditorWidgetNode selectedWidget;
  final ValueChanged<String?> onSelect;
  final VoidCallback onDelete;
  final VoidCallback onSave;
  final VoidCallback onSeeAll;
  final ValueChanged<EditorWidgetNode> onUpdateWidget;
  final Color accentColor;

  @override
  State<DevStudioBottomBar> createState() => _DevStudioBottomBarState();
}

class _DevStudioBottomBarState extends State<DevStudioBottomBar> {
  String _activeTab = 'Basic';

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 16,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFFE2E3E8))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Dropdown Selection & Control Buttons
              Row(
                children: [
                  Icon(iconForWidget(widget.selectedWidget.type), size: 18, color: Colors.black54),
                  const SizedBox(width: 8),
                  
                  // Widget selection spinner
                  PopupMenuButton<String>(
                    initialValue: widget.selectedWidget.id,
                    onSelected: widget.onSelect,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.selectedWidget.id,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, color: Colors.black54),
                      ],
                    ),
                    itemBuilder: (context) {
                      return widget.widgets.map((node) {
                        return PopupMenuItem<String>(
                          value: node.id,
                          child: Row(
                            children: [
                              Icon(iconForWidget(node.type), size: 16),
                              const SizedBox(width: 8),
                              Text(node.id),
                            ],
                          ),
                        );
                      }).toList();
                    },
                  ),

                  const Spacer(),

                  // Save button
                  IconButton(
                    onPressed: widget.onSave,
                    icon: const Icon(Icons.save_outlined, size: 22, color: Colors.black54),
                    tooltip: 'Save Widget',
                  ),

                  // Delete button
                  IconButton(
                    onPressed: widget.onDelete,
                    icon: const Icon(Icons.delete_sweep_outlined, size: 22, color: Colors.redAccent),
                    tooltip: 'Delete Widget',
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // Row 2: Navigation Tabs (Basic, Recent, Event)
              Row(
                children: [
                  _buildTabPill('Basic'),
                  const SizedBox(width: 8),
                  _buildTabPill('Recent'),
                  const SizedBox(width: 8),
                  _buildTabPill('Event'),
                ],
              ),

              const SizedBox(height: 10),

              // Row 3: Horizontal scrollable cards for properties
              SizedBox(
                height: 78,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _buildPropertyShortcutCards(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabPill(String tabName) {
    final active = _activeTab == tabName;
    return InkWell(
      onTap: () => setState(() => _activeTab = tabName),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFEDE9FE) : const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          tabName,
          style: TextStyle(
            color: active ? widget.accentColor : Colors.black87,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPropertyShortcutCards() {
    if (_activeTab == 'Event') {
      return [
        _buildShortcutCard('onClick', Icons.bolt, () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Click event clicked. Use Event tab above to edit logic.')),
          );
        }),
        _buildShortcutCard('onLongClick', Icons.bolt, () {}),
      ];
    }

    return [
      _buildShortcutCard('Custom attributes', Icons.code, () {}),
      _buildShortcutCard('Convert', Icons.swap_horizontal_circle_outlined, () {}),
      _buildShortcutCard('Width', Icons.swap_horiz, _showWidthDialog),
      _buildShortcutCard('Height', Icons.swap_vert, _showHeightDialog),
      _buildShortcutCard('Text', Icons.title, _showTextDialog),
      _buildShortcutCard('Padding', Icons.space_bar, _showPaddingDialog),
      _buildShortcutCard('Margin', Icons.grid_3x3, _showMarginDialog),
      _buildShortcutCard('See All', Icons.more_horiz, widget.onSeeAll),
    ];
  }

  Widget _buildShortcutCard(String title, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 82,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: Colors.black87),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Width adjustment dialog
  void _showWidthDialog() {
    int mode = widget.selectedWidget.width.round() < 0 ? widget.selectedWidget.width.round() : 1;
    final controller = TextEditingController(
      text: widget.selectedWidget.width >= 0 ? widget.selectedWidget.width.round().toString() : '150',
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Widget Width'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<int>(
                    value: mode,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: -1, child: Text('match_parent')),
                      DropdownMenuItem(value: -2, child: Text('wrap_content')),
                      DropdownMenuItem(value: 1, child: Text('Custom (dp)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => mode = val);
                    },
                  ),
                  if (mode == 1) ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Width in dp'),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final double val = mode < 0
                        ? mode.toDouble()
                        : (double.tryParse(controller.text) ?? 150.0);
                    widget.onUpdateWidget(widget.selectedWidget.copyWith(width: val));
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Height adjustment dialog
  void _showHeightDialog() {
    int mode = widget.selectedWidget.height.round() < 0 ? widget.selectedWidget.height.round() : 1;
    final controller = TextEditingController(
      text: widget.selectedWidget.height >= 0 ? widget.selectedWidget.height.round().toString() : '52',
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Widget Height'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<int>(
                    value: mode,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: -1, child: Text('match_parent')),
                      DropdownMenuItem(value: -2, child: Text('wrap_content')),
                      DropdownMenuItem(value: 1, child: Text('Custom (dp)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => mode = val);
                    },
                  ),
                  if (mode == 1) ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Height in dp'),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final double val = mode < 0
                        ? mode.toDouble()
                        : (double.tryParse(controller.text) ?? 52.0);
                    widget.onUpdateWidget(widget.selectedWidget.copyWith(height: val));
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Text input dialog
  void _showTextDialog() {
    final controller = TextEditingController(text: widget.selectedWidget.text);
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Widget Text'),
          content: TextField(
            controller: controller,
            maxLines: 2,
            decoration: const InputDecoration(hintText: 'Enter text content'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                widget.onUpdateWidget(widget.selectedWidget.copyWith(text: controller.text));
                Navigator.pop(dialogContext);
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  // Padding dialog
  void _showPaddingDialog() {
    final left = TextEditingController(text: widget.selectedWidget.paddingLeft.round().toString());
    final top = TextEditingController(text: widget.selectedWidget.paddingTop.round().toString());
    final right = TextEditingController(text: widget.selectedWidget.paddingRight.round().toString());
    final bottom = TextEditingController(text: widget.selectedWidget.paddingBottom.round().toString());

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Padding (dp)'),
          content: Row(
            children: [
              Expanded(child: TextField(controller: left, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Left'))),
              const SizedBox(width: 6),
              Expanded(child: TextField(controller: top, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Top'))),
              const SizedBox(width: 6),
              Expanded(child: TextField(controller: right, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Right'))),
              const SizedBox(width: 6),
              Expanded(child: TextField(controller: bottom, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Bottom'))),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                widget.onUpdateWidget(widget.selectedWidget.copyWith(
                  paddingLeft: double.tryParse(left.text) ?? 0.0,
                  paddingTop: double.tryParse(top.text) ?? 0.0,
                  paddingRight: double.tryParse(right.text) ?? 0.0,
                  paddingBottom: double.tryParse(bottom.text) ?? 0.0,
                ));
                Navigator.pop(dialogContext);
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  // Margin dialog
  void _showMarginDialog() {
    final left = TextEditingController(text: widget.selectedWidget.marginLeft.round().toString());
    final top = TextEditingController(text: widget.selectedWidget.marginTop.round().toString());
    final right = TextEditingController(text: widget.selectedWidget.marginRight.round().toString());
    final bottom = TextEditingController(text: widget.selectedWidget.marginBottom.round().toString());

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Margins (dp)'),
          content: Row(
            children: [
              Expanded(child: TextField(controller: left, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Left'))),
              const SizedBox(width: 6),
              Expanded(child: TextField(controller: top, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Top'))),
              const SizedBox(width: 6),
              Expanded(child: TextField(controller: right, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Right'))),
              const SizedBox(width: 6),
              Expanded(child: TextField(controller: bottom, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Bottom'))),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                widget.onUpdateWidget(widget.selectedWidget.copyWith(
                  marginLeft: double.tryParse(left.text) ?? 0.0,
                  marginTop: double.tryParse(top.text) ?? 0.0,
                  marginRight: double.tryParse(right.text) ?? 0.0,
                  marginBottom: double.tryParse(bottom.text) ?? 0.0,
                ));
                Navigator.pop(dialogContext);
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }
}

