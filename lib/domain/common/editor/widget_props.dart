class WidgetProps {
  const WidgetProps({
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.alignment,
    this.spacing,
    this.backgroundColor,
    this.borderRadius,
    this.borderColor,
    this.borderWidth,
    this.text,
    this.fontSize,
    this.color,
    this.fontWeight,
    this.hint,
    this.imagePath,
  });

  final double? width;
  final double? height;
  final double? padding;
  final double? margin;
  final String? alignment;
  final double? spacing;
  final String? backgroundColor;
  final double? borderRadius;
  final String? borderColor;
  final double? borderWidth;
  final String? text;
  final double? fontSize;
  final String? color;
  final String? fontWeight;
  final String? hint;
  final String? imagePath;

  WidgetProps copyWith({
    double? width,
    double? height,
    double? padding,
    double? margin,
    String? alignment,
    double? spacing,
    String? backgroundColor,
    double? borderRadius,
    String? borderColor,
    double? borderWidth,
    String? text,
    double? fontSize,
    String? color,
    String? fontWeight,
    String? hint,
    String? imagePath,
  }) {
    return WidgetProps(
      width: width ?? this.width,
      height: height ?? this.height,
      padding: padding ?? this.padding,
      margin: margin ?? this.margin,
      alignment: alignment ?? this.alignment,
      spacing: spacing ?? this.spacing,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderRadius: borderRadius ?? this.borderRadius,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      text: text ?? this.text,
      fontSize: fontSize ?? this.fontSize,
      color: color ?? this.color,
      fontWeight: fontWeight ?? this.fontWeight,
      hint: hint ?? this.hint,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{};
    if (width != null) json['width'] = width;
    if (height != null) json['height'] = height;
    if (padding != null) json['padding'] = padding;
    if (margin != null) json['margin'] = margin;
    if (alignment != null) json['alignment'] = alignment;
    if (spacing != null) json['spacing'] = spacing;
    if (backgroundColor != null) json['backgroundColor'] = backgroundColor;
    if (borderRadius != null) json['borderRadius'] = borderRadius;
    if (borderColor != null) json['borderColor'] = borderColor;
    if (borderWidth != null) json['borderWidth'] = borderWidth;
    if (text != null) json['text'] = text;
    if (fontSize != null) json['fontSize'] = fontSize;
    if (color != null) json['color'] = color;
    if (fontWeight != null) json['fontWeight'] = fontWeight;
    if (hint != null) json['hint'] = hint;
    if (imagePath != null) json['imagePath'] = imagePath;
    return json;
  }

  factory WidgetProps.fromJson(Map<String, Object?> json) {
    return WidgetProps(
      width: (json['width'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      padding: (json['padding'] as num?)?.toDouble(),
      margin: (json['margin'] as num?)?.toDouble(),
      alignment: json['alignment'] as String?,
      spacing: (json['spacing'] as num?)?.toDouble(),
      backgroundColor: json['backgroundColor'] as String?,
      borderRadius: (json['borderRadius'] as num?)?.toDouble(),
      borderColor: json['borderColor'] as String?,
      borderWidth: (json['borderWidth'] as num?)?.toDouble(),
      text: json['text'] as String?,
      fontSize: (json['fontSize'] as num?)?.toDouble(),
      color: json['color'] as String?,
      fontWeight: json['fontWeight'] as String?,
      hint: json['hint'] as String?,
      imagePath: json['imagePath'] as String?,
    );
  }
}
