enum WidgetType {
  column('column', 'Column'),
  row('row', 'Row'),
  container('container', 'Container'),
  text('text', 'Text'),
  button('button', 'Button'),
  image('image', 'Image'),
  textField('textField', 'TextField');

  const WidgetType(this.type, this.label);

  final String type;
  final String label;

  static WidgetType fromString(String value) {
    return values.firstWhere(
      (item) => item.type == value,
      orElse: () => WidgetType.container,
    );
  }
}
