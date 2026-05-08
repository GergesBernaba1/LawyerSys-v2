import 'package:qadaya_lawyersys/features/governments/models/government.dart';

abstract class GovernmentsState {}

class GovernmentsInitial extends GovernmentsState {}

class GovernmentsLoading extends GovernmentsState {}

class GovernmentsLoaded extends GovernmentsState {
  GovernmentsLoaded({
    required this.governments,
    required this.totalCount,
    required this.page,
    required this.hasMore,
    this.searchQuery = '',
  });
  final List<Government> governments;
  final int totalCount;
  final int page;
  final bool hasMore;
  final String searchQuery;
}

/// Emitted while the next page is being fetched; holds current data so UI
/// can keep the existing list visible with a bottom spinner.
class GovernmentsLoadingMore extends GovernmentsState {
  GovernmentsLoadingMore(this.current);
  final GovernmentsLoaded current;
}

class GovernmentsError extends GovernmentsState {
  GovernmentsError(this.message);
  final String message;
}

class GovernmentOperationSuccess extends GovernmentsState {
  GovernmentOperationSuccess(this.message);
  final String message;
}
