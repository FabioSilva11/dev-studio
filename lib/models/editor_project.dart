import 'dart:convert';

enum EditorWidgetType {
  flexLayout(0, 'Flex Layout'),
  stackLayout(1, 'Stack'),
  horizontalScroll(2, 'Horizontal Scroll'),
  button(3, 'Button'),
  text(4, 'Text'),
  textField(5, 'TextField'),
  image(6, 'Image'),
  webView(7, 'WebView'),
  progressIndicator(8, 'Progress Indicator'),
  listView(9, 'ListView'),
  dropdown(10, 'Dropdown'),
  checkbox(11, 'Checkbox'),
  scrollView(12, 'ScrollView'),
  switchTile(13, 'Switch'),
  slider(14, 'Slider'),
  calendarView(15, 'Calendar View'),
  floatingActionButton(16, 'FloatingActionButton'),
  adView(17, 'Ad View'),
  mapView(18, 'Map View'),
  radio(19, 'Radio'),
  ratingBar(20, 'Rating Bar'),
  videoView(21, 'Video View'),
  searchBar(22, 'SearchBar'),
  autocomplete(23, 'Autocomplete'),
  multiAutocomplete(24, 'Multi Autocomplete'),
  gridView(25, 'GridView'),
  analogClock(26, 'Analog Clock'),
  datePicker(27, 'Date Picker'),
  timePicker(28, 'Time Picker'),
  digitalClock(29, 'Digital Clock'),
  tabBar(30, 'TabBar'),
  pageView(31, 'PageView'),
  navigationBar(32, 'NavigationBar'),
  badge(33, 'Badge'),
  patternLock(34, 'Pattern Lock'),
  waveSideBar(35, 'Wave Side Bar'),
  card(36, 'Card'),
  collapsingToolbar(37, 'Sliver App Bar'),
  inputDecorator(38, 'Input Decorator'),
  refreshIndicator(39, 'RefreshIndicator'),
  radioGroup(40, 'Radio Group'),
  filledButton(41, 'FilledButton'),
  signInButton(42, 'Sign In Button'),
  circleAvatar(43, 'CircleAvatar'),
  lottieAnimation(44, 'Lottie Animation'),
  youtubePlayer(45, 'YouTube Player'),
  otpField(46, 'OTP Field'),
  codeView(47, 'Code View'),
  recyclerList(48, 'Virtual List');

  const EditorWidgetType(this.devStudioType, this.label);

  final int devStudioType;
  final String label;

  static EditorWidgetType fromJson(Object? value) {
    final type = int.tryParse(value?.toString() ?? '');
    return values.firstWhere(
      (item) => item.devStudioType == type,
      orElse: () => EditorWidgetType.text,
    );
  }
}

class EditorWidgetNode {
  const EditorWidgetNode({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.text,
    this.parentId = 'root',
    this.parentType = -1,
    this.index = 0,
    this.hint = '',
    this.backgroundColor = 0xFFFFFFFF,
    this.textColor = 0xFF1C1C1E,
    this.fontSize = 14,
    this.elevation = 0,
    this.borderRadius = 4,
    this.visible = true,
    this.enabled = true,
    this.orientation = 'vertical',
    this.paddingLeft = 0.0,
    this.paddingTop = 0.0,
    this.paddingRight = 0.0,
    this.paddingBottom = 0.0,
    this.marginLeft = 0.0,
    this.marginTop = 0.0,
    this.marginRight = 0.0,
    this.marginBottom = 0.0,
    this.gravity = 0,
    this.layoutGravity = 0,
    this.weight = 0,
    this.layoutFile = 'main.dart',
  });

  final String id;
  final EditorWidgetType type;
  final double x;
  final double y;
  final double width;
  final double height;
  final String text;
  final String parentId;
  final int parentType;
  final int index;
  final String hint;
  final int backgroundColor;
  final int textColor;
  final double fontSize;
  final double elevation;
  final double borderRadius;
  final bool visible;
  final bool enabled;
  final String orientation;
  final double paddingLeft;
  final double paddingTop;
  final double paddingRight;
  final double paddingBottom;
  final double marginLeft;
  final double marginTop;
  final double marginRight;
  final double marginBottom;
  final int gravity;
  final int layoutGravity;
  final int weight;
  final String layoutFile;

  EditorWidgetNode copyWith({
    String? id,
    EditorWidgetType? type,
    double? x,
    double? y,
    double? width,
    double? height,
    String? text,
    String? parentId,
    int? parentType,
    int? index,
    String? hint,
    int? backgroundColor,
    int? textColor,
    double? fontSize,
    double? elevation,
    double? borderRadius,
    bool? visible,
    bool? enabled,
    String? orientation,
    double? paddingLeft,
    double? paddingTop,
    double? paddingRight,
    double? paddingBottom,
    double? marginLeft,
    double? marginTop,
    double? marginRight,
    double? marginBottom,
    int? gravity,
    int? layoutGravity,
    int? weight,
    String? layoutFile,
  }) {
    return EditorWidgetNode(
      id: id ?? this.id,
      type: type ?? this.type,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      text: text ?? this.text,
      parentId: parentId ?? this.parentId,
      parentType: parentType ?? this.parentType,
      index: index ?? this.index,
      hint: hint ?? this.hint,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      fontSize: fontSize ?? this.fontSize,
      elevation: elevation ?? this.elevation,
      borderRadius: borderRadius ?? this.borderRadius,
      visible: visible ?? this.visible,
      enabled: enabled ?? this.enabled,
      orientation: orientation ?? this.orientation,
      paddingLeft: paddingLeft ?? this.paddingLeft,
      paddingTop: paddingTop ?? this.paddingTop,
      paddingRight: paddingRight ?? this.paddingRight,
      paddingBottom: paddingBottom ?? this.paddingBottom,
      marginLeft: marginLeft ?? this.marginLeft,
      marginTop: marginTop ?? this.marginTop,
      marginRight: marginRight ?? this.marginRight,
      marginBottom: marginBottom ?? this.marginBottom,
      gravity: gravity ?? this.gravity,
      layoutGravity: layoutGravity ?? this.layoutGravity,
      weight: weight ?? this.weight,
      layoutFile: layoutFile ?? this.layoutFile,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'type': type.devStudioType,
    'name': id,
    'parent': parentId,
    'parentType': parentType,
    'index': index,
    'x': x,
    'y': y,
    'width': width,
    'height': height,
    'text': text,
    'hint': hint,
    'backgroundColor': backgroundColor,
    'textColor': textColor,
    'fontSize': fontSize,
    'elevation': elevation,
    'borderRadius': borderRadius,
    'visible': visible,
    'enabled': enabled,
    'orientation': orientation,
    'paddingLeft': paddingLeft,
    'paddingTop': paddingTop,
    'paddingRight': paddingRight,
    'paddingBottom': paddingBottom,
    'marginLeft': marginLeft,
    'marginTop': marginTop,
    'marginRight': marginRight,
    'marginBottom': marginBottom,
    'gravity': gravity,
    'layoutGravity': layoutGravity,
    'weight': weight,
    'layoutFile': layoutFile,
  };

  factory EditorWidgetNode.fromJson(Map<String, Object?> json) {
    double number(String key, double fallback) =>
        (json[key] as num?)?.toDouble() ?? fallback;
    int integer(String key, int fallback) =>
        (json[key] as num?)?.toInt() ?? fallback;

    return EditorWidgetNode(
      id: json['id']?.toString() ?? 'widget',
      type: EditorWidgetType.fromJson(json['type']),
      x: number('x', 24),
      y: number('y', 24),
      width: number('width', 140),
      height: number('height', 52),
      text: json['text']?.toString() ?? '',
      parentId: json['parent']?.toString() ?? 'root',
      parentType: integer('parentType', -1),
      index: integer('index', 0),
      hint: json['hint']?.toString() ?? '',
      backgroundColor: integer('backgroundColor', 0xFFFFFFFF),
      textColor: integer('textColor', 0xFF1C1C1E),
      fontSize: number('fontSize', 14),
      elevation: number('elevation', 0),
      borderRadius: number('borderRadius', 4),
      visible: json['visible'] != false,
      enabled: json['enabled'] != false,
      orientation: json['orientation']?.toString() ?? 'vertical',
      paddingLeft: number('paddingLeft', 0),
      paddingTop: number('paddingTop', 0),
      paddingRight: number('paddingRight', 0),
      paddingBottom: number('paddingBottom', 0),
      marginLeft: number('marginLeft', 0),
      marginTop: number('marginTop', 0),
      marginRight: number('marginRight', 0),
      marginBottom: number('marginBottom', 0),
      gravity: integer('gravity', 0),
      layoutGravity: integer('layoutGravity', 0),
      weight: integer('weight', 0),
      layoutFile: json['layoutFile']?.toString() ?? 'main.dart',
    );
  }
}

class EditorEventItem {
  const EditorEventItem({required this.target, required this.name});

  final String target;
  final String name;

  Map<String, Object?> toJson() => {'target': target, 'name': name};

  factory EditorEventItem.fromJson(Map<String, Object?> json) {
    return EditorEventItem(
      target: json['target']?.toString() ?? 'App',
      name: json['name']?.toString() ?? 'main',
    );
  }
}

class EditorComponentItem {
  const EditorComponentItem({required this.id, required this.type});

  final String id;
  final String type;

  Map<String, Object?> toJson() => {'id': id, 'type': type};

  factory EditorComponentItem.fromJson(Map<String, Object?> json) {
    return EditorComponentItem(
      id: json['id']?.toString() ?? 'component',
      type: json['type']?.toString() ?? 'Service',
    );
  }
}

class EditorProjectData {
  const EditorProjectData({
    this.fileName = 'main.dart',
    this.widgets = const [],
    this.events = const [EditorEventItem(target: 'App', name: 'main')],
    this.components = const [],
    this.strings = const {'app_name': 'My application'},
  });

  final String fileName;
  final List<EditorWidgetNode> widgets;
  final List<EditorEventItem> events;
  final List<EditorComponentItem> components;
  final Map<String, String> strings;

  Map<String, Object?> toJson() => {
    'version': 2,
    'fileName': fileName,
    'widgets': widgets.map((item) => item.toJson()).toList(),
    'events': events.map((item) => item.toJson()).toList(),
    'components': components.map((item) => item.toJson()).toList(),
    'strings': strings,
  };

  String encode() => jsonEncode(toJson());

  factory EditorProjectData.fromJson(Map<String, Object?> json) {
    Map<String, Object?> mapValue(Object? value) => value is Map
        ? value.map((key, item) => MapEntry(key.toString(), item))
        : const {};
    final rawStrings = mapValue(json['strings']);
    return EditorProjectData(
      fileName: json['fileName']?.toString() ?? 'main.dart',
      widgets: (json['widgets'] as List? ?? const [])
          .map((item) => EditorWidgetNode.fromJson(mapValue(item)))
          .toList(),
      events: (json['events'] as List? ?? const [])
          .map((item) => EditorEventItem.fromJson(mapValue(item)))
          .toList(),
      components: (json['components'] as List? ?? const [])
          .map((item) => EditorComponentItem.fromJson(mapValue(item)))
          .toList(),
      strings: rawStrings.map(
        (key, value) => MapEntry(key, value?.toString() ?? ''),
      ),
    );
  }
}
