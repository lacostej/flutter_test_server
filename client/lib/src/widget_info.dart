/// Represents a widget found in the app's widget tree.
class WidgetInfo {
  final String type;
  final String? key;
  final String? semanticsLabel;
  final double? x;
  final double? y;
  final double? width;
  final double? height;
  final Map<String, dynamic> properties;

  WidgetInfo({
    required this.type,
    this.key,
    this.semanticsLabel,
    this.x,
    this.y,
    this.width,
    this.height,
    this.properties = const {},
  });

  factory WidgetInfo.fromJson(Map<String, dynamic> json) {
    final bounds = json['bounds'] as Map<String, dynamic>?;
    return WidgetInfo(
      type: json['type'] as String,
      key: json['key'] as String?,
      semanticsLabel: json['semanticsLabel'] as String?,
      x: bounds?['x'] as double?,
      y: bounds?['y'] as double?,
      width: bounds?['width'] as double?,
      height: bounds?['height'] as double?,
      properties: Map<String, dynamic>.from(json['properties'] as Map? ?? {}),
    );
  }

  /// Get a text property (e.g. for Text widgets).
  String? get text => properties['text'] as String?;

  /// Check if a button is enabled.
  bool? get enabled => properties['enabled'] as bool?;

  @override
  String toString() => 'WidgetInfo($type, key=$key, text=$text)';
}
