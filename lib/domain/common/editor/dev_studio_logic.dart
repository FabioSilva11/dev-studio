class DevStudioLogic {
  const DevStudioLogic({
    required this.events,
  });

  final List<DevStudioEvent> events;

  DevStudioLogic copyWith({
    List<DevStudioEvent>? events,
  }) {
    return DevStudioLogic(
      events: events ?? this.events,
    );
  }
}

class DevStudioEvent {
  const DevStudioEvent({
    required this.id,
    required this.target,
    required this.trigger,
    required this.blocks,
  });

  final String id;
  final String target;
  final String trigger;
  final List<DevStudioBlock> blocks;

  DevStudioEvent copyWith({
    String? id,
    String? target,
    String? trigger,
    List<DevStudioBlock>? blocks,
  }) {
    return DevStudioEvent(
      id: id ?? this.id,
      target: target ?? this.target,
      trigger: trigger ?? this.trigger,
      blocks: blocks ?? this.blocks,
    );
  }
}

class DevStudioBlock {
  const DevStudioBlock({
    required this.id,
    required this.type,
    required this.props,
    required this.inputs,
    required this.children,
  });

  final String id;
  final String type;
  final Map<String, Object?> props;
  final Map<String, Object?> inputs;
  final List<DevStudioBlock> children;

  DevStudioBlock copyWith({
    String? id,
    String? type,
    Map<String, Object?>? props,
    Map<String, Object?>? inputs,
    List<DevStudioBlock>? children,
  }) {
    return DevStudioBlock(
      id: id ?? this.id,
      type: type ?? this.type,
      props: props ?? this.props,
      inputs: inputs ?? this.inputs,
      children: children ?? this.children,
    );
  }
}
