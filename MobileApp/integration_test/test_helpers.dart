import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Helper function to find any of the provided finders.
/// Returns a Finder that evaluates to true if at least one of the provided finders finds widgets.
Finder findAnyOf(List<Finder> finders) {
  return find.byWidgetPredicate(
    (widget) => finders.any((f) => f.evaluate().isNotEmpty),
  );
}

/// Helper function to find all of the provided finders.
/// Returns a Finder that evaluates to true only if all provided finders find widgets.
Finder findAllOf(List<Finder> finders) {
  return find.byWidgetPredicate(
    (widget) => finders.every((f) => f.evaluate().isNotEmpty),
  );
}

/// Helper function to find text widgets matching a regular expression pattern.
/// 
/// Example usage:
/// ```dart
/// findTextByPattern('Cases|القضايا', caseSensitive: false)
/// ```
Finder findTextByPattern(String pattern, {bool caseSensitive = true}) {
  return find.byWidgetPredicate((widget) {
    if (widget is Text) {
      final text = widget.data ?? '';
      return RegExp(pattern, caseSensitive: caseSensitive).hasMatch(text);
    }
    return false;
  });
}

/// Helper function to find widgets with text matching a regular expression pattern.
/// 
/// Example usage:
/// ```dart
/// findWidgetWithTextPattern<ElevatedButton>('Logout|Sign Out')
/// ```
Finder findWidgetWithTextPattern<T extends Widget>(
  String pattern, {
  bool caseSensitive = true,
}) {
  return find.byWidgetPredicate((widget) {
    if (widget is! T) return false;
    
    // For buttons, check the child
    if (widget is ElevatedButton ||
        widget is TextButton ||
        widget is OutlinedButton) {
      final button = widget as dynamic;
      final child = button.child as Object?;
      if (child is Text) {
        final text = child.data ?? '';
        return RegExp(pattern, caseSensitive: caseSensitive).hasMatch(text);
      }
    }
    
    // For IconButton with Tooltip
    if (widget is IconButton) {
      final button = widget;
      final tooltip = button.tooltip;
      if (tooltip != null) {
        return RegExp(pattern, caseSensitive: caseSensitive).hasMatch(tooltip);
      }
    }
    
    return false;
  });
}

/// Helper function to check if text contains a pattern using RegExp.
/// Useful for assertions with expect().
bool textContainsPattern(String text, String pattern, {bool caseSensitive = true}) {
  return RegExp(pattern, caseSensitive: caseSensitive).hasMatch(text);
}

/// Helper to find any widget containing text that matches the pattern.
Finder findTextContaining(String pattern, {bool caseSensitive = true}) {
  return find.byWidgetPredicate((widget) {
    if (widget is Text) {
      final text = widget.data ?? '';
      return RegExp(pattern, caseSensitive: caseSensitive).hasMatch(text);
    }
    return false;
  });
}
