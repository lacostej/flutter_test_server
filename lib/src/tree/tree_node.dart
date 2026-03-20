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
    final bx = _finiteOrNull(x);
    final by = _finiteOrNull(y);
    final bw = _finiteOrNull(width);
    final bh = _finiteOrNull(height);
    if (bx != null || by != null || bw != null || bh != null) {
      json['bounds'] = {
        if (bx != null) 'x': bx,
        if (by != null) 'y': by,
        if (bw != null) 'width': bw,
        if (bh != null) 'height': bh,
      };
    }
    if (properties.isNotEmpty) json['properties'] = properties;
    if (children.isNotEmpty) {
      json['children'] = children.map((c) => c.toJson()).toList();
    }
    return json;
  }

  static double? _finiteOrNull(double? value) {
    if (value == null || value.isNaN || value.isInfinite) return null;
    return value;
  }
}
