import 'package:flutter_test/flutter_test.dart';
import 'package:qadaya_lawyersys/shared/utils/pagination_helper.dart';

void main() {
  group('PaginatedState', () {
    test('initial state has correct defaults', () {
      const state = PaginatedState<String>();

      expect(state.items, isEmpty);
      expect(state.currentPage, equals(1));
      expect(state.isLoading, isFalse);
      expect(state.hasMore, isTrue);
      expect(state.error, isNull);
    });

    test('loadingFirstPage creates correct state', () {
      const initial = PaginatedState<String>(
        items: ['item1'],
        currentPage: 2,
      );

      final loading = initial.loadingFirstPage();

      expect(loading.items, isEmpty);
      expect(loading.currentPage, equals(1));
      expect(loading.isLoading, isTrue);
      expect(loading.hasMore, isTrue);
      expect(loading.error, isNull);
    });

    test('loadingNextPage maintains items and sets loading', () {
      const initial = PaginatedState<String>(
        items: ['item1', 'item2'],
        currentPage: 2,
      );

      final loading = initial.loadingNextPage();

      expect(loading.items, equals(['item1', 'item2']));
      expect(loading.currentPage, equals(2));
      expect(loading.isLoading, isTrue);
      expect(loading.error, isNull);
    });

    test('pageLoaded appends items and increments page', () {
      const initial = PaginatedState<String>(
        items: ['item1', 'item2'],
        currentPage: 1,
      );

      final loaded = initial.pageLoaded(['item3', 'item4'], 2);

      expect(loaded.items, equals(['item1', 'item2', 'item3', 'item4']));
      expect(loaded.currentPage, equals(2));
      expect(loaded.isLoading, isFalse);
      expect(loaded.hasMore, isTrue); // 2 items >= pageSize of 2
    });

    test('pageLoaded sets hasMore to false when items < pageSize', () {
      const initial = PaginatedState<String>(
        items: ['item1', 'item2'],
        currentPage: 2,
      );

      final loaded = initial.pageLoaded(['item3'], 5);

      expect(loaded.hasMore, isFalse); // 1 item < pageSize of 5
    });

    test('firstPageLoaded replaces items and sets page to 2', () {
      const initial = PaginatedState<String>(
        items: ['old1', 'old2'],
        currentPage: 3,
      );

      final loaded = initial.firstPageLoaded(['new1', 'new2'], 2);

      expect(loaded.items, equals(['new1', 'new2']));
      expect(loaded.currentPage, equals(2));
      expect(loaded.isLoading, isFalse);
      expect(loaded.hasMore, isTrue);
    });

    test('loadError sets error and stops loading', () {
      const initial = PaginatedState<String>(
        items: ['item1'],
        isLoading: true,
      );

      final error = initial.loadError('Network error');

      expect(error.error, equals('Network error'));
      expect(error.isLoading, isFalse);
      expect(error.items, equals(['item1'])); // Maintains items
    });

    test('isEmpty returns true when items empty and not loading', () {
      const empty = PaginatedState<String>();
      const loading = PaginatedState<String>(isLoading: true);
      const withItems = PaginatedState<String>(items: ['item1']);

      expect(empty.isEmpty, isTrue);
      expect(loading.isEmpty, isFalse);
      expect(withItems.isEmpty, isFalse);
    });

    test('isFirstPage returns true only on page 1', () {
      const page1 = PaginatedState<String>(currentPage: 1);
      const page2 = PaginatedState<String>(currentPage: 2);

      expect(page1.isFirstPage, isTrue);
      expect(page2.isFirstPage, isFalse);
    });

    test('copyWith creates new instance with updated fields', () {
      const initial = PaginatedState<String>(
        items: ['item1'],
        currentPage: 1,
      );

      final updated = initial.copyWith(
        items: ['item1', 'item2'],
        currentPage: 2,
        isLoading: true,
      );

      expect(updated.items, equals(['item1', 'item2']));
      expect(updated.currentPage, equals(2));
      expect(updated.isLoading, isTrue);
      expect(updated.hasMore, equals(initial.hasMore)); // Unchanged
    });
  });

  group('PaginationConfig', () {
    test('has correct default values', () {
      const config = PaginationConfig();

      expect(config.pageSize, equals(20));
      expect(config.scrollThreshold, equals(0.9));
      expect(config.enablePullToRefresh, isTrue);
    });

    test('allows custom configuration', () {
      const config = PaginationConfig(
        pageSize: 50,
        scrollThreshold: 0.8,
        enablePullToRefresh: false,
      );

      expect(config.pageSize, equals(50));
      expect(config.scrollThreshold, equals(0.8));
      expect(config.enablePullToRefresh, isFalse);
    });
  });
}
