import 'package:flutter/widgets.dart';

/// A mixin that provides pagination functionality for list screens
/// 
/// Usage:
/// ```dart
/// class MyListScreen extends StatefulWidget {
///   ...
/// }
/// 
/// class _MyListScreenState extends State<MyListScreen> 
///     with PaginationMixin<MyItem> {
///   
///   @override
///   Future<List<MyItem>> fetchPage(int page, int pageSize) async {
///     // Implement your API call here
///     return await myRepository.getItems(page: page, limit: pageSize);
///   }
///   
///   @override
///   Widget build(BuildContext context) {
///     return ListView.builder(
///       controller: scrollController,
///       itemCount: items.length + (hasMore ? 1 : 0),
///       itemBuilder: (context, index) {
///         if (index == items.length) {
///           return const Center(child: CircularProgressIndicator());
///         }
///         return MyItemTile(item: items[index]);
///       },
///     );
///   }
/// }
/// ```
mixin PaginationMixin<T> on State {
  final ScrollController scrollController = ScrollController();
  
  List<T> items = [];
  int currentPage = 1;
  int pageSize = 20;
  bool isLoading = false;
  bool hasMore = true;
  String? error;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_onScroll);
    loadInitialData();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (scrollController.position.pixels >= 
        scrollController.position.maxScrollExtent * 0.9) {
      if (!isLoading && hasMore) {
        loadMore();
      }
    }
  }

  /// Override this method to implement your data fetching logic
  Future<List<T>> fetchPage(int page, int pageSize);

  /// Load the first page of data
  Future<void> loadInitialData() async {
    setState(() {
      items = [];
      currentPage = 1;
      hasMore = true;
      error = null;
    });
    await loadMore();
  }

  /// Load the next page of data
  Future<void> loadMore() async {
    if (isLoading || !hasMore) return;

    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final newItems = await fetchPage(currentPage, pageSize);
      
      setState(() {
        items.addAll(newItems);
        currentPage++;
        hasMore = newItems.length >= pageSize;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  /// Refresh the entire list
  Future<void> refresh() async {
    await loadInitialData();
  }
}

/// A helper class for managing pagination state in BLoC
class PaginatedState<T> {

  const PaginatedState({
    this.items = const [],
    this.currentPage = 1,
    this.isLoading = false,
    this.hasMore = true,
    this.error,
  });
  final List<T> items;
  final int currentPage;
  final bool isLoading;
  final bool hasMore;
  final String? error;

  PaginatedState<T> copyWith({
    List<T>? items,
    int? currentPage,
    bool? isLoading,
    bool? hasMore,
    String? error,
  }) {
    return PaginatedState<T>(
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }

  /// Create a new state for loading the first page
  PaginatedState<T> loadingFirstPage() {
    return copyWith(
      items: [],
      currentPage: 1,
      isLoading: true,
      hasMore: true,
      error: null,
    );
  }

  /// Create a new state for loading the next page
  PaginatedState<T> loadingNextPage() {
    return copyWith(
      isLoading: true,
      error: null,
    );
  }

  /// Create a new state when a page is successfully loaded
  PaginatedState<T> pageLoaded(List<T> newItems, int pageSize) {
    return copyWith(
      items: [...items, ...newItems],
      currentPage: currentPage + 1,
      isLoading: false,
      hasMore: newItems.length >= pageSize,
    );
  }

  /// Create a new state when the first page is successfully loaded
  PaginatedState<T> firstPageLoaded(List<T> newItems, int pageSize) {
    return copyWith(
      items: newItems,
      currentPage: 2,
      isLoading: false,
      hasMore: newItems.length >= pageSize,
    );
  }

  /// Create a new state when an error occurs
  PaginatedState<T> loadError(String error) {
    return copyWith(
      isLoading: false,
      error: error,
    );
  }

  bool get isEmpty => items.isEmpty && !isLoading;
  bool get isFirstPage => currentPage == 1;
}

/// Pagination configuration
class PaginationConfig {

  const PaginationConfig({
    this.pageSize = 20,
    this.scrollThreshold = 0.9,
    this.enablePullToRefresh = true,
  });
  final int pageSize;
  final double scrollThreshold;
  final bool enablePullToRefresh;
}
