import 'package:flutter/material.dart';
import '../models/editor_project.dart';

class EventsTab extends StatefulWidget {
  const EventsTab({
    super.key,
    required this.events,
    required this.widgets,
    required this.onChanged,
    required this.accentColor,
  });

  final List<EditorEventItem> events;
  final List<EditorWidgetNode> widgets;
  final ValueChanged<List<EditorEventItem>> onChanged;
  final Color accentColor;

  @override
  State<EventsTab> createState() => _EventsTabState();
}

class _EventsTabState extends State<EventsTab> {
  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _addEvent() async {
    final targets = ['Activity', ...widget.widgets.map((item) => item.id)];
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
                value: target,
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
                value: eventName,
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
      if (widget.events.any(
        (item) => item.target == target && item.name == eventName,
      )) {
        _showMessage('This event already exists.');
        return;
      }
      final newEvents = List<EditorEventItem>.from(widget.events)
        ..add(EditorEventItem(target: target, name: eventName));
      widget.onChanged(newEvents);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _EditorListPage(
      title: 'Events',
      description: 'Activity and view events available for main.xml.',
      emptyText: 'No events added',
      addLabel: 'Add event',
      onAdd: _addEvent,
      children: widget.events.map((event) {
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
                    final newEvents = List<EditorEventItem>.from(widget.events)
                      ..remove(event);
                    widget.onChanged(newEvents);
                  },
            icon: const Icon(Icons.delete_outline),
          ),
        );
      }).toList(),
    );
  }
}

class ComponentsTab extends StatefulWidget {
  const ComponentsTab({
    super.key,
    required this.components,
    required this.onChanged,
    required this.accentColor,
  });

  final List<EditorComponentItem> components;
  final ValueChanged<List<EditorComponentItem>> onChanged;
  final Color accentColor;

  @override
  State<ComponentsTab> createState() => _ComponentsTabState();
}

class _ComponentsTabState extends State<ComponentsTab> {
  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
                value: type,
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
      if (widget.components.any((item) => item.id == id)) {
        _showMessage('This component ID already exists.');
        return;
      }
      final newComponents = List<EditorComponentItem>.from(widget.components)
        ..add(EditorComponentItem(id: id, type: type));
      widget.onChanged(newComponents);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _EditorListPage(
      title: 'Components',
      description: 'Non-visual components used by this activity.',
      emptyText: 'No components added',
      addLabel: 'Add component',
      onAdd: _addComponent,
      children: widget.components.map((component) {
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
              final newComponents = List<EditorComponentItem>.from(widget.components)
                ..remove(component);
              widget.onChanged(newComponents);
            },
            icon: const Icon(Icons.delete_outline),
          ),
        );
      }).toList(),
    );
  }
}

class StringsTab extends StatefulWidget {
  const StringsTab({
    super.key,
    required this.strings,
    required this.onChanged,
    required this.accentColor,
  });

  final Map<String, String> strings;
  final ValueChanged<Map<String, String>> onChanged;
  final Color accentColor;

  @override
  State<StringsTab> createState() => _StringsTabState();
}

class _StringsTabState extends State<StringsTab> {
  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
      final newStrings = Map<String, String>.from(widget.strings)
        ..[resourceKey] = resourceValue;
      widget.onChanged(newStrings);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.strings.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return _EditorListPage(
      title: 'Strings',
      description: 'Text resources stored for this project.',
      emptyText: 'No strings added',
      addLabel: 'Add string',
      onAdd: () => _editString(),
      children: entries.map((entry) {
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFFEDE9FE),
            foregroundColor: widget.accentColor,
            child: const Icon(Icons.translate, size: 20),
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
                    final newStrings = Map<String, String>.from(widget.strings)
                      ..remove(entry.key);
                    widget.onChanged(newStrings);
                  },
            icon: const Icon(Icons.delete_outline),
          ),
        );
      }).toList(),
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
              border: Border.all(color: const Color(0xFFE2E3E8)),
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
