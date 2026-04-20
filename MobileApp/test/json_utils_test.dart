import 'package:flutter_test/flutter_test.dart';
import 'package:qadaya_lawyersys/core/utils/json_utils.dart';

void main() {
  group('normalizeJsonList', () {
    test('returns list directly when raw is a List', () {
      final input = [{'id': 1}, {'id': 2}];
      expect(normalizeJsonList(input), equals(input));
    });

    test('returns items key when raw is a Map with items', () {
      final items = [{'id': 1}];
      final input = {'items': items, 'totalCount': 1};
      expect(normalizeJsonList(input), equals(items));
    });

    test('returns Items key (capital I) when present', () {
      final items = [{'id': 1}];
      final input = {'Items': items};
      expect(normalizeJsonList(input), equals(items));
    });

    test('returns empty list when raw is a Map without items key', () {
      expect(normalizeJsonList({'total': 0}), isEmpty);
    });

    test('returns empty list when raw is null', () {
      expect(normalizeJsonList(null), isEmpty);
    });

    test('returns empty list when raw is a String', () {
      expect(normalizeJsonList('invalid'), isEmpty);
    });

    test('returns empty list when raw is an empty Map', () {
      expect(normalizeJsonList(<String, dynamic>{}), isEmpty);
    });

    test('handles nested list of mixed types gracefully', () {
      final input = [1, 'two', {'id': 3}];
      expect(normalizeJsonList(input), equals(input));
    });
  });
}
