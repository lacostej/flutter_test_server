import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shelf/shelf.dart';

import 'tap.dart';

/// Handler for POST /enterText
/// Body: {"text": "hello", "key": "myField"} or {"text": "hello", "semantics": "Username"}
///
/// If key/semantics/type is provided, taps the widget first to focus it,
/// then sets the text. If no target is specified, enters text into the
/// currently focused field.
Future<Response> handleEnterText(Request request) async {
  final body = await request.readAsString();
  final json = jsonDecode(body) as Map<String, dynamic>;
  final text = json['text'] as String?;
  final append = json['append'] as bool? ?? false;

  if (text == null) {
    return Response(400,
      body: jsonEncode({'error': 'Missing "text" field'}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  // If a target is specified, tap it first to focus
  final hasTarget = json.containsKey('key') ||
      json.containsKey('semantics') ||
      json.containsKey('type');
  if (hasTarget) {
    final target = findTargetWidget(json);
    if (target == null) {
      return Response.notFound(
        jsonEncode({'error': 'Widget not found', 'query': json}),
        headers: {'Content-Type': 'application/json'},
      );
    }
    if (target.x != null && target.y != null &&
        target.width != null && target.height != null) {
      dispatchTap(Offset(
        target.x! + target.width! / 2,
        target.y! + target.height! / 2,
      ));
      // Allow the tap to process and focus the field
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  // Find the currently focused EditableTextState and set its value
  final result = enterTextInFocusedField(text, append: append);
  if (!result) {
    return Response(400,
      body: jsonEncode({'error': 'No focused text field found'}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  return Response.ok(
    jsonEncode({'status': 'ok', 'text': text}),
    headers: {'Content-Type': 'application/json'},
  );
}

/// Find the currently focused EditableText and set its value.
bool enterTextInFocusedField(String text, {bool append = false}) {
  final binding = WidgetsBinding.instance;
  final rootElement = binding.rootElement;
  if (rootElement == null) return false;

  EditableTextState? editableTextState;
  _findFocusedEditableText(rootElement, (state) {
    editableTextState = state;
  });

  if (editableTextState == null) return false;

  final currentValue = editableTextState!.textEditingValue;
  final newText = append ? currentValue.text + text : text;

  editableTextState!.updateEditingValue(TextEditingValue(
    text: newText,
    selection: TextSelection.collapsed(offset: newText.length),
  ));

  return true;
}

/// Walk the element tree to find an EditableText that has focus.
void _findFocusedEditableText(
  Element element,
  void Function(EditableTextState) onFound,
) {
  if (element.widget is EditableText) {
    final state = (element as StatefulElement).state;
    if (state is EditableTextState) {
      // Check if this EditableText's FocusNode has focus
      final focusNode = (element.widget as EditableText).focusNode;
      if (focusNode.hasFocus) {
        onFound(state);
        return;
      }
    }
  }
  element.visitChildren((child) {
    _findFocusedEditableText(child, onFound);
  });
}
