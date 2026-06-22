import 'dart:convert';

enum EditorWidgetType {
  linearLayout(0, 'Linear Layout'),
  relativeLayout(1, 'Relative Layout'),
  horizontalScroll(2, 'Horizontal Scroll'),
  button(3, 'Button'),
  textView(4, 'TextView'),
  editText(5, 'EditText'),
  imageView(6, 'ImageView'),
  webView(7, 'WebView'),
  progressBar(8, 'ProgressBar'),
  listView(9, 'ListView'),
  spinner(10, 'Spinner'),
  checkBox(11, 'CheckBox'),
  scrollView(12, 'ScrollView'),
  switchView(13, 'Switch'),
  seekBar(14, 'SeekBar'),
  calendarView(15, 'CalendarView'),
  floatingButton(16, 'Floating Button'),
  adView(17, 'AdView'),
  mapView(18, 'MapView'),
  radioButton(19, 'RadioButton'),
  ratingBar(20, 'RatingBar'),
  videoView(21, 'VideoView'),
  searchView(22, 'SearchView'),
  autoCompleteText(23, 'AutoCompleteTextView'),
  multiAutoCompleteText(24, 'MultiAutoCompleteTextView'),
  gridView(25, 'GridView'),
  analogClock(26, 'AnalogClock'),
  datePicker(27, 'DatePicker'),
  timePicker(28, 'TimePicker'),
  digitalClock(29, 'DigitalClock'),
  tabLayout(30, 'TabLayout'),
  viewPager(31, 'ViewPager'),
  bottomNavigation(32, 'BottomNavigationView'),
  badgeView(33, 'BadgeView'),
  patternLock(34, 'PatternLockView'),
  waveSideBar(35, 'WaveSideBar'),
  cardView(36, 'CardView'),
  collapsingToolbar(37, 'CollapsingToolbarLayout'),
  textInputLayout(38, 'TextInputLayout'),
  swipeRefresh(39, 'SwipeRefreshLayout'),
  radioGroup(40, 'RadioGroup'),
  materialButton(41, 'MaterialButton'),
  signInButton(42, 'SignInButton'),
  circleImageView(43, 'CircleImageView'),
  lottieAnimation(44, 'LottieAnimationView'),
  youtubePlayer(45, 'YoutubePlayerView'),
  otpView(46, 'OTPView'),
  codeView(47, 'CodeView'),
  recyclerView(48, 'RecyclerView');

  const EditorWidgetType(this.sketchwareType, this.label);

  final int sketchwareType;
  final String label;

  static EditorWidgetType fromJson(Object? value) {
    final type = int.tryParse(value?.toString() ?? '');
    return values.firstWhere(
      (item) => item.sketchwareType == type,
      orElse: () => EditorWidgetType.textView,
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
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'type': type.sketchwareType,
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
  };

  factory EditorWidgetNode.fromJson(Map<String, Object?> json) {
    double number(String key, double fallback) =>
        (json[key] as num?)?.toDouble() ?? fallback;
    int integer(String key, int fallback) =>
        (json[key] as num?)?.toInt() ?? fallback;

    return EditorWidgetNode(
      id: json['id']?.toString() ?? 'view',
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
      target: json['target']?.toString() ?? 'Activity',
      name: json['name']?.toString() ?? 'onCreate',
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
      type: json['type']?.toString() ?? 'Intent',
    );
  }
}

class EditorProjectData {
  const EditorProjectData({
    this.fileName = 'main.xml',
    this.widgets = const [],
    this.events = const [EditorEventItem(target: 'Activity', name: 'onCreate')],
    this.components = const [],
    this.strings = const {'app_name': 'My application'},
  });

  final String fileName;
  final List<EditorWidgetNode> widgets;
  final List<EditorEventItem> events;
  final List<EditorComponentItem> components;
  final Map<String, String> strings;

  Map<String, Object?> toJson() => {
    'version': 1,
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
      fileName: json['fileName']?.toString() ?? 'main.xml',
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
