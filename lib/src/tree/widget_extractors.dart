import 'package:flutter/material.dart';

/// Extracts meaningful properties from known widget types.
Map<String, dynamic> extractProperties(Widget widget) {
  if (widget is Text) {
    return {
      'text': widget.data ?? widget.textSpan?.toPlainText(),
      if (widget.style != null) 'style': _textStyleProps(widget.style!),
      if (widget.maxLines != null) 'maxLines': widget.maxLines,
      if (widget.overflow != null) 'overflow': widget.overflow.toString(),
    };
  }
  if (widget is Icon) {
    return {
      if (widget.icon != null) 'icon': widget.icon!.codePoint,
      if (widget.size != null) 'size': widget.size,
      if (widget.color != null) 'color': _colorHex(widget.color!),
      if (widget.semanticLabel != null)
        'semanticLabel': widget.semanticLabel,
    };
  }
  if (widget is Image) {
    return {
      'image': widget.image.toString(),
      if (widget.width != null) 'width': widget.width,
      if (widget.height != null) 'height': widget.height,
      if (widget.semanticLabel != null)
        'semanticLabel': widget.semanticLabel,
    };
  }
  if (widget is Slider) {
    return {
      'value': widget.value,
      if (widget.min != 0.0) 'min': widget.min,
      if (widget.max != 1.0) 'max': widget.max,
      if (widget.label != null) 'label': widget.label,
    };
  }
  if (widget is Switch) {
    return {'value': widget.value};
  }
  if (widget is Checkbox) {
    return {'value': widget.value};
  }
  if (widget is Radio) {
    return {
      'value': widget.value,
      'groupValue': widget.groupValue,
    };
  }
  if (widget is TextField) {
    return {
      if (widget.controller?.text != null) 'text': widget.controller!.text,
      if (widget.decoration?.labelText != null)
        'labelText': widget.decoration!.labelText,
      if (widget.decoration?.hintText != null)
        'hintText': widget.decoration!.hintText,
      'obscureText': widget.obscureText,
      'enabled': widget.enabled,
    };
  }
  if (widget is ElevatedButton || widget is TextButton || widget is OutlinedButton) {
    return {
      'enabled': (widget as dynamic).onPressed != null,
    };
  }
  if (widget is FloatingActionButton) {
    return {
      'enabled': widget.onPressed != null,
      if (widget.tooltip != null) 'tooltip': widget.tooltip,
    };
  }
  if (widget is IconButton) {
    return {
      'enabled': widget.onPressed != null,
      if (widget.tooltip != null) 'tooltip': widget.tooltip,
    };
  }
  if (widget is Opacity) {
    return {'opacity': widget.opacity};
  }
  if (widget is Container) {
    return {
      if (widget.constraints != null)
        'constraints': widget.constraints.toString(),
    };
  }
  if (widget is SizedBox) {
    return {
      if (widget.width != null) 'width': widget.width,
      if (widget.height != null) 'height': widget.height,
    };
  }
  if (widget is Padding) {
    return {'padding': widget.padding.toString()};
  }
  if (widget is Scaffold) {
    return {
      'hasAppBar': widget.appBar != null,
      'hasDrawer': widget.drawer != null,
      'hasFloatingActionButton': widget.floatingActionButton != null,
      'hasBottomNavigationBar': widget.bottomNavigationBar != null,
    };
  }
  if (widget is AppBar) {
    return {
      if (widget.title != null) 'hasTitle': true,
    };
  }
  return {};
}

Map<String, dynamic> _textStyleProps(TextStyle style) {
  return {
    if (style.fontSize != null) 'fontSize': style.fontSize,
    if (style.fontWeight != null) 'fontWeight': style.fontWeight.toString(),
    if (style.color != null) 'color': _colorHex(style.color!),
    if (style.fontFamily != null) 'fontFamily': style.fontFamily,
  };
}

String _colorHex(Color color) {
  // ignore: deprecated_member_use
  return '#${color.value.toRadixString(16).padLeft(8, '0')}';
}
