import 'package:flutter/widgets.dart';

import 'tree_node.dart';
import 'widget_extractors.dart';

/// Walks the Flutter Element tree and produces a [TreeNode] hierarchy.
class TreeWalker {
  /// Build the full tree starting from the root element.
  static TreeNode? buildTree(Element rootElement) {
    return _visitElement(rootElement);
  }

  /// Filter the tree, returning only nodes matching [predicate] (and their ancestors).
  static List<TreeNode> findAll(
    Element rootElement,
    bool Function(TreeNode node) predicate,
  ) {
    final results = <TreeNode>[];
    _collectMatching(rootElement, predicate, results);
    return results;
  }

  static TreeNode _visitElement(Element element) {
    final widget = element.widget;
    final renderObject = element.renderObject;

    double? x, y, w, h;
    if (renderObject is RenderBox && renderObject.hasSize) {
      final size = renderObject.size;
      w = size.width;
      h = size.height;
      try {
        final offset = renderObject.localToGlobal(Offset.zero);
        x = offset.dx;
        y = offset.dy;
      } catch (_) {
        // localToGlobal can throw if not attached
      }
    }

    String? semanticsLabel;
    if (renderObject is RenderBox) {
      final semantics = renderObject.debugSemantics;
      if (semantics != null) {
        final data = semantics.getSemanticsData();
        if (data.label.isNotEmpty) {
          semanticsLabel = data.label;
        }
      }
    }

    final children = <TreeNode>[];
    element.visitChildren((child) {
      children.add(_visitElement(child));
    });

    return TreeNode(
      type: widget.runtimeType.toString(),
      key: widget.key?.toString(),
      semanticsLabel: semanticsLabel,
      x: x,
      y: y,
      width: w,
      height: h,
      properties: extractProperties(widget),
      children: children,
    );
  }

  static void _collectMatching(
    Element element,
    bool Function(TreeNode node) predicate,
    List<TreeNode> results,
  ) {
    final node = _visitElement(element);
    if (predicate(node)) {
      // Return flat node without children for search results
      results.add(TreeNode(
        type: node.type,
        key: node.key,
        semanticsLabel: node.semanticsLabel,
        x: node.x,
        y: node.y,
        width: node.width,
        height: node.height,
        properties: node.properties,
      ));
    }
    element.visitChildren((child) {
      _collectMatching(child, predicate, results);
    });
  }
}
