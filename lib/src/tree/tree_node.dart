/// JSON-serializable model for a widget tree node.
class TreeNode {
  final String type;
  final String? key;
  final String? semanticsLabel;
  final double? x;
  final double? y;
  final double? width;
  final double? height;
  final Map<String, dynamic> properties;
  final List<TreeNode> children;

  TreeNode({
    required this.type,
    this.key,
    this.semanticsLabel,
    this.x,
    this.y,
    this.width,
    this.height,
    this.properties = const {},
    this.children = const [],
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'type': type,
    };
    if (key != null) json['key'] = key;
    if (semanticsLabel != null) json['semanticsLabel'] = semanticsLabel;
    if (x != null || y != null || width != null || height != null) {
      json['bounds'] = {
        if (x != null) 'x': x,
        if (y != null) 'y': y,
        if (width != null) 'width': width,
        if (height != null) 'height': height,
      };
    }
    if (properties.isNotEmpty) json['properties'] = properties;
    if (children.isNotEmpty) {
      json['children'] = children.map((c) => c.toJson()).toList();
    }
    return json;
  }
}
