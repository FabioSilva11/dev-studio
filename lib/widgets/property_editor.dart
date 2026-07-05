import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/editor_project.dart';
import 'editor_palette.dart'; // to reuse iconForWidget

class PropertyResult {
  const PropertyResult({this.node, this.delete = false});

  final EditorWidgetNode? node;
  final bool delete;
}

class PropertyEditorSheet extends StatefulWidget {
  const PropertyEditorSheet({
    super.key,
    required this.node,
    required this.accentColor,
  });

  final EditorWidgetNode node;
  final Color accentColor;

  @override
  State<PropertyEditorSheet> createState() => _PropertyEditorSheetState();
}

class _PropertyEditorSheetState extends State<PropertyEditorSheet> {
  late final TextEditingController _id;
  late final TextEditingController _text;
  late final TextEditingController _hint;
  late final TextEditingController _customWidth;
  late final TextEditingController _customHeight;
  late final TextEditingController _customMarginLeft;
  late final TextEditingController _customMarginTop;
  late final TextEditingController _customMarginRight;
  late final TextEditingController _customMarginBottom;
  late final TextEditingController _customPaddingLeft;
  late final TextEditingController _customPaddingTop;
  late final TextEditingController _customPaddingRight;
  late final TextEditingController _customPaddingBottom;
  late final TextEditingController _weight;

  late int _widthMode; // -1: match_parent, -2: wrap_content, >0: custom
  late int _heightMode; // -1: match_parent, -2: wrap_content, >0: custom

  late int _backgroundColor;
  late int _textColor;
  late double _fontSize;
  late double _elevation;
  late double _radius;
  late bool _visible;
  late bool _enabled;
  late String _orientation;

  late int _gravity;
  late int _layoutGravity;

  @override
  void initState() {
    super.initState();
    final node = widget.node;
    _id = TextEditingController(text: node.id);
    _text = TextEditingController(text: node.text);
    _hint = TextEditingController(text: node.hint);

    _widthMode = node.width.round() < 0 ? node.width.round() : 1;
    _customWidth = TextEditingController(
      text: node.width >= 0 ? node.width.round().toString() : '150',
    );

    _heightMode = node.height.round() < 0 ? node.height.round() : 1;
    _customHeight = TextEditingController(
      text: node.height >= 0 ? node.height.round().toString() : '52',
    );

    _customMarginLeft = TextEditingController(text: node.marginLeft.round().toString());
    _customMarginTop = TextEditingController(text: node.marginTop.round().toString());
    _customMarginRight = TextEditingController(text: node.marginRight.round().toString());
    _customMarginBottom = TextEditingController(text: node.marginBottom.round().toString());

    _customPaddingLeft = TextEditingController(text: node.paddingLeft.round().toString());
    _customPaddingTop = TextEditingController(text: node.paddingTop.round().toString());
    _customPaddingRight = TextEditingController(text: node.paddingRight.round().toString());
    _customPaddingBottom = TextEditingController(text: node.paddingBottom.round().toString());

    _weight = TextEditingController(text: node.weight.toString());

    _backgroundColor = node.backgroundColor;
    _textColor = node.textColor;
    _fontSize = node.fontSize;
    _elevation = node.elevation;
    _radius = node.borderRadius;
    _visible = node.visible;
    _enabled = node.enabled;
    _orientation = node.orientation;

    _gravity = node.gravity;
    _layoutGravity = node.layoutGravity;
  }

  @override
  void dispose() {
    _id.dispose();
    _text.dispose();
    _hint.dispose();
    _customWidth.dispose();
    _customHeight.dispose();
    _customMarginLeft.dispose();
    _customMarginTop.dispose();
    _customMarginRight.dispose();
    _customMarginBottom.dispose();
    _customPaddingLeft.dispose();
    _customPaddingTop.dispose();
    _customPaddingRight.dispose();
    _customPaddingBottom.dispose();
    _weight.dispose();
    super.dispose();
  }

  double _number(TextEditingController controller, double fallback) =>
      double.tryParse(controller.text) ?? fallback;

  int _intVal(TextEditingController controller, int fallback) =>
      int.tryParse(controller.text) ?? fallback;

  void _save() {
    final id = _id.text.trim();
    if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$').hasMatch(id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid view ID.')),
      );
      return;
    }

    final double resolvedWidth = _widthMode < 0
        ? _widthMode.toDouble()
        : _number(_customWidth, 150).clamp(10, 1000);

    final double resolvedHeight = _heightMode < 0
        ? _heightMode.toDouble()
        : _number(_customHeight, 52).clamp(10, 1000);

    final node = widget.node.copyWith(
      id: id,
      text: _text.text,
      hint: _hint.text,
      width: resolvedWidth,
      height: resolvedHeight,
      backgroundColor: _backgroundColor,
      textColor: _textColor,
      fontSize: _fontSize,
      elevation: _elevation,
      borderRadius: _radius,
      visible: _visible,
      enabled: _enabled,
      orientation: _orientation,
      paddingLeft: _number(_customPaddingLeft, 0),
      paddingTop: _number(_customPaddingTop, 0),
      paddingRight: _number(_customPaddingRight, 0),
      paddingBottom: _number(_customPaddingBottom, 0),
      marginLeft: _number(_customMarginLeft, 0),
      marginTop: _number(_customMarginTop, 0),
      marginRight: _number(_customMarginRight, 0),
      marginBottom: _number(_customMarginBottom, 0),
      gravity: _gravity,
      layoutGravity: _layoutGravity,
      weight: _intVal(_weight, 0),
    );
    Navigator.pop(context, PropertyResult(node: node));
  }

  @override
  Widget build(BuildContext context) {
    final isLayout =
        widget.node.type == EditorWidgetType.linearLayout ||
        widget.node.type == EditorWidgetType.relativeLayout ||
        widget.node.type == EditorWidgetType.scrollView ||
        widget.node.type == EditorWidgetType.horizontalScroll;

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
                  foregroundColor: widget.accentColor,
                  child: Icon(iconForWidget(widget.node.type)),
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
                    const PropertyResult(delete: true),
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
            const _PropertyHeader('Layout Dimensions'),
            
            // Width setting
            Row(
              children: [
                const SizedBox(width: 60, child: Text('Width:')),
                Expanded(
                  child: DropdownButton<int>(
                    value: _widthMode,
                    items: const [
                      DropdownMenuItem(value: -1, child: Text('match_parent')),
                      DropdownMenuItem(value: -2, child: Text('wrap_content')),
                      DropdownMenuItem(value: 1, child: Text('custom (dp)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _widthMode = val);
                    },
                  ),
                ),
                if (_widthMode == 1) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: _NumberField(controller: _customWidth, label: 'Width (dp)'),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),

            // Height setting
            Row(
              children: [
                const SizedBox(width: 60, child: Text('Height:')),
                Expanded(
                  child: DropdownButton<int>(
                    value: _heightMode,
                    items: const [
                      DropdownMenuItem(value: -1, child: Text('match_parent')),
                      DropdownMenuItem(value: -2, child: Text('wrap_content')),
                      DropdownMenuItem(value: 1, child: Text('custom (dp)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _heightMode = val);
                    },
                  ),
                ),
                if (_heightMode == 1) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: _NumberField(controller: _customHeight, label: 'Height (dp)'),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),

            const _PropertyHeader('Margins & Padding'),
            Row(
              children: [
                Expanded(child: _NumberField(controller: _customMarginLeft, label: 'Margin Left')),
                const SizedBox(width: 8),
                Expanded(child: _NumberField(controller: _customMarginTop, label: 'Margin Top')),
                const SizedBox(width: 8),
                Expanded(child: _NumberField(controller: _customMarginRight, label: 'Margin Right')),
                const SizedBox(width: 8),
                Expanded(child: _NumberField(controller: _customMarginBottom, label: 'Margin Bottom')),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _NumberField(controller: _customPaddingLeft, label: 'Padding Left')),
                const SizedBox(width: 8),
                Expanded(child: _NumberField(controller: _customPaddingTop, label: 'Padding Top')),
                const SizedBox(width: 8),
                Expanded(child: _NumberField(controller: _customPaddingRight, label: 'Padding Right')),
                const SizedBox(width: 8),
                Expanded(child: _NumberField(controller: _customPaddingBottom, label: 'Padding Bottom')),
              ],
            ),
            const SizedBox(height: 14),

            const _PropertyHeader('Layout Parameters'),
            Row(
              children: [
                Expanded(
                  child: _NumberField(controller: _weight, label: 'Weight'),
                ),
                if (isLayout) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Orientation'),
                      value: _orientation,
                      items: const [
                        DropdownMenuItem(value: 'vertical', child: Text('Vertical')),
                        DropdownMenuItem(value: 'horizontal', child: Text('Horizontal')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _orientation = val);
                      },
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),

            const _PropertyHeader('Appearance'),
            _ColorProperty(
              label: 'Background color',
              value: _backgroundColor,
              accentColor: widget.accentColor,
              onChanged: (value) => setState(() => _backgroundColor = value),
            ),
            _ColorProperty(
              label: 'Text color',
              value: _textColor,
              accentColor: widget.accentColor,
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
                backgroundColor: widget.accentColor,
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
      padding: const EdgeInsets.only(bottom: 10, top: 10),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF6B5CE7),
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
      decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(fontSize: 12)),
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
    required this.accentColor,
    required this.onChanged,
  });

  final String label;
  final int value;
  final Color accentColor;
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
                      color: selected ? accentColor : const Color(0xFFE2E3E8),
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
