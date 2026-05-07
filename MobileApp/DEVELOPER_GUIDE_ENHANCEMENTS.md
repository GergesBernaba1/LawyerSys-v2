# Developer Guide: Using New Enhancement Utilities

This guide demonstrates how to use the newly implemented utilities in your screens and features.

---

## 🎨 Skeleton Loading Screens

### Basic Usage

Replace your loading indicators with skeleton screens for better UX:

```dart
import 'package:qadaya_lawyersys/shared/widgets/skeleton_loader.dart';

// Before
if (state is Loading) {
  return const Center(child: CircularProgressIndicator());
}

// After
if (state is Loading) {
  return const ListSkeleton(itemCount: 5);
}
```

### Available Skeleton Types

#### 1. List Skeleton
```dart
// Simple list
const ListSkeleton(itemCount: 5)

// Custom item builder
ListSkeleton(
  itemCount: 10,
  itemBuilder: (context, index) => const CustomSkeleton(),
)
```

#### 2. Grid Skeleton
```dart
const GridSkeleton(
  itemCount: 6,
  crossAxisCount: 2,
)
```

#### 3. Card Skeleton
```dart
const CardSkeleton(height: 150)
```

#### 4. Form Field Skeleton
```dart
const FormFieldSkeleton(width: 200)
```

#### 5. Profile Header Skeleton
```dart
const ProfileHeaderSkeleton()
```

### Creating Custom Skeletons

```dart
class CustomCaseSkeleton extends StatelessWidget {
  const CustomCaseSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SkeletonLoader(width: 60, height: 60),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonLoader(
                        width: MediaQuery.of(context).size.width * 0.5,
                        height: 18,
                      ),
                      const SizedBox(height: 8),
                      SkeletonLoader(
                        width: MediaQuery.of(context).size.width * 0.3,
                        height: 14,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const SkeletonLoader(height: 100),
          ],
        ),
      ),
    );
  }
}
```

---

## 📄 Pagination

### Option 1: Using PaginationMixin (Simplest)

Best for simple screens with basic pagination needs:

```dart
import 'package:qadaya_lawyersys/shared/utils/pagination_helper.dart';

class CasesListScreen extends StatefulWidget {
  const CasesListScreen({super.key});

  @override
  State<CasesListScreen> createState() => _CasesListScreenState();
}

class _CasesListScreenState extends State<CasesListScreen>
    with PaginationMixin<Case> {
  final CasesRepository _repository = CasesRepository();

  @override
  Future<List<Case>> fetchPage(int page, int pageSize) async {
    return await _repository.getCases(page: page, limit: pageSize);
  }

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return ErrorStateWidget(
        message: error!,
        onRetry: refresh,
      );
    }

    if (items.isEmpty && isLoading) {
      return const ListSkeleton();
    }

    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView.builder(
        controller: scrollController,
        itemCount: items.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return CaseListTile(case: items[index]);
        },
      ),
    );
  }
}
```

### Option 2: Using PaginatedState with BLoC (Recommended)

Best for complex screens with state management:

```dart
// In your BLoC state
import 'package:qadaya_lawyersys/shared/utils/pagination_helper.dart';

class CasesState extends Equatable {
  final PaginatedState<Case> paginatedCases;
  
  const CasesState({
    this.paginatedCases = const PaginatedState(),
  });
  
  @override
  List<Object?> get props => [paginatedCases];
}

// In your BLoC
class CasesBloc extends Bloc<CasesEvent, CasesState> {
  final CasesRepository repository;
  
  CasesBloc({required this.repository}) : super(const CasesState()) {
    on<LoadCases>(_onLoadCases);
    on<LoadMoreCases>(_onLoadMoreCases);
  }
  
  Future<void> _onLoadCases(LoadCases event, Emitter<CasesState> emit) async {
    emit(state.copyWith(
      paginatedCases: state.paginatedCases.loadingFirstPage(),
    ));
    
    try {
      final cases = await repository.getCases(page: 1, limit: 20);
      emit(state.copyWith(
        paginatedCases: state.paginatedCases.firstPageLoaded(cases, 20),
      ));
    } catch (e) {
      emit(state.copyWith(
        paginatedCases: state.paginatedCases.loadError(e.toString()),
      ));
    }
  }
  
  Future<void> _onLoadMoreCases(LoadMoreCases event, Emitter<CasesState> emit) async {
    if (!state.paginatedCases.hasMore || state.paginatedCases.isLoading) {
      return;
    }
    
    emit(state.copyWith(
      paginatedCases: state.paginatedCases.loadingNextPage(),
    ));
    
    try {
      final cases = await repository.getCases(
        page: state.paginatedCases.currentPage,
        limit: 20,
      );
      emit(state.copyWith(
        paginatedCases: state.paginatedCases.pageLoaded(cases, 20),
      ));
    } catch (e) {
      emit(state.copyWith(
        paginatedCases: state.paginatedCases.loadError(e.toString()),
      ));
    }
  }
}

// In your screen
class CasesListScreen extends StatefulWidget {
  const CasesListScreen({super.key});

  @override
  State<CasesListScreen> createState() => _CasesListScreenState();
}

class _CasesListScreenState extends State<CasesListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    context.read<CasesBloc>().add(LoadCases());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      context.read<CasesBloc>().add(LoadMoreCases());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CasesBloc, CasesState>(
      builder: (context, state) {
        final paginated = state.paginatedCases;

        if (paginated.items.isEmpty && paginated.isLoading) {
          return const ListSkeleton();
        }

        if (paginated.isEmpty && paginated.error != null) {
          return ErrorStateWidget(
            message: paginated.error!,
            onRetry: () => context.read<CasesBloc>().add(LoadCases()),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            context.read<CasesBloc>().add(LoadCases());
          },
          child: ListView.builder(
            controller: _scrollController,
            itemCount: paginated.items.length + (paginated.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == paginated.items.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return CaseListTile(case: paginated.items[index]);
            },
          ),
        );
      },
    );
  }
}
```

---

## 🛡️ Error Handling

### Basic Error Handling

```dart
import 'package:qadaya_lawyersys/core/error/failures.dart';
import 'package:dartz/dartz.dart';

// In your repository
Future<Either<Failure, List<Case>>> getCases() async {
  try {
    final response = await apiClient.get('/cases');
    final cases = (response.data as List)
        .map((json) => Case.fromJson(json))
        .toList();
    return Right(cases);
  } catch (e) {
    final failure = ErrorHandler.handleError(e);
    return Left(failure);
  }
}

// In your BLoC
Future<void> _onLoadCases(LoadCases event, Emitter<CasesState> emit) async {
  emit(CasesLoading());
  
  final result = await repository.getCases();
  
  result.fold(
    (failure) {
      // Handle different error types
      if (failure.isAuthError) {
        // Navigate to login or show session expired message
        emit(CasesAuthError(failure.message));
      } else if (failure.isNetworkError) {
        // Show offline message with retry option
        emit(CasesNetworkError(failure.message));
      } else {
        // Generic error
        emit(CasesError(failure.userMessage));
      }
    },
    (cases) => emit(CasesLoaded(cases)),
  );
}
```

### Advanced Error Handling with Field Validation

```dart
// In your form submission
Future<void> _onSubmitForm(SubmitForm event, Emitter<FormState> emit) async {
  emit(FormSubmitting());
  
  final result = await repository.createCase(event.data);
  
  result.fold(
    (failure) {
      if (failure is ValidationFailure && failure.fieldErrors != null) {
        // Show field-specific errors
        emit(FormValidationError(failure.fieldErrors!));
      } else {
        emit(FormError(failure.userMessage));
      }
    },
    (case_) => emit(FormSuccess(case_)),
  );
}

// In your screen
BlocListener<FormBloc, FormState>(
  listener: (context, state) {
    if (state is FormValidationError) {
      // Update form field errors
      state.fieldErrors.forEach((field, error) {
        // Show error for specific field
        if (field == 'title') {
          _titleError = error;
        } else if (field == 'description') {
          _descriptionError = error;
        }
      });
      setState(() {});
    } else if (state is FormError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message)),
      );
    }
  },
  child: Form(...),
)
```

### Custom Error Types

```dart
// Create your own specific failures
class CaseNotFoundFailure extends NotFoundFailure {
  const CaseNotFoundFailure({required super.message})
      : super(code: 404);
}

class InsufficientPermissionsFailure extends UnauthorizedFailure {
  const InsufficientPermissionsFailure()
      : super(
          message: 'You do not have permission to perform this action',
          code: 403,
        );
}

// Use in repository
if (response.statusCode == 404) {
  return const Left(CaseNotFoundFailure(
    message: 'The requested case could not be found',
  ));
}
```

---

## 🔔 Crash Reporting with Sentry

### Automatic Error Capture

Sentry is already configured in `main.dart` and will automatically capture:
- Unhandled exceptions
- Flutter framework errors
- Native crashes

### Manual Error Reporting

```dart
import 'package:sentry_flutter/sentry_flutter.dart';

// Report errors manually
try {
  await someDangerousOperation();
} catch (error, stackTrace) {
  await Sentry.captureException(
    error,
    stackTrace: stackTrace,
    hint: Hint.withMap({'operation': 'someDangerousOperation'}),
  );
  // Still show error to user
  emit(ErrorState(error.toString()));
}
```

### Add Breadcrumbs

```dart
// Add context to help debug issues
Sentry.addBreadcrumb(Breadcrumb(
  message: 'User opened case #123',
  category: 'navigation',
  level: SentryLevel.info,
));

Sentry.addBreadcrumb(Breadcrumb(
  message: 'API call to /cases',
  category: 'http',
  data: {'method': 'GET', 'url': '/cases'},
));
```

### Set User Context

```dart
// In your authentication bloc after login
Sentry.configureScope((scope) {
  scope.setUser(SentryUser(
    id: user.id,
    email: user.email,
    username: user.username,
  ));
});

// Clear on logout
Sentry.configureScope((scope) {
  scope.setUser(null);
});
```

### Tag Events

```dart
Sentry.configureScope((scope) {
  scope.setTag('feature', 'cases');
  scope.setTag('environment', 'production');
  scope.setTag('locale', 'ar');
});
```

---

## 📝 Best Practices

### 1. Always Use Skeletons for Initial Loading

```dart
// Good
if (state is InitialLoading) {
  return const ListSkeleton();
}

// Avoid
if (state is Loading) {
  return const Center(child: CircularProgressIndicator());
}
```

### 2. Combine Pagination with Skeleton Loading

```dart
if (paginated.items.isEmpty && paginated.isLoading) {
  return const ListSkeleton(); // First load
}

if (index == paginated.items.length && paginated.isLoading) {
  return const ListItemSkeleton(); // Loading more
}
```

### 3. Use Typed Failures

```dart
// Good - Type safe
Either<Failure, Case> getCase(String id);

// Avoid - Loses error information
Future<Case?> getCase(String id);
```

### 4. Handle All Error Types

```dart
result.fold(
  (failure) {
    if (failure.isAuthError) {
      // Handle auth errors
    } else if (failure.isNetworkError) {
      // Handle network errors
    } else if (failure.isValidationError) {
      // Handle validation errors
    } else {
      // Handle generic errors
    }
  },
  (success) => handleSuccess(success),
);
```

### 5. Add Context to Sentry Reports

```dart
try {
  await operation();
} catch (error, stackTrace) {
  await Sentry.captureException(
    error,
    stackTrace: stackTrace,
    withScope: (scope) {
      scope.setContexts('operation', {
        'name': 'updateCase',
        'caseId': caseId,
        'userId': userId,
      });
    },
  );
}
```

---

## 🧪 Testing

### Testing Pagination

```dart
test('loads more items when scrolling near end', () async {
  final mockRepo = MockCasesRepository();
  when(mockRepo.getCases(page: 1, limit: 20))
      .thenAnswer((_) async => List.generate(20, (i) => Case(id: '$i')));
  
  await tester.pumpWidget(MyApp(repository: mockRepo));
  
  // Scroll to bottom
  await tester.drag(find.byType(ListView), const Offset(0, -500));
  await tester.pumpAndSettle();
  
  // Verify second page is loaded
  verify(mockRepo.getCases(page: 2, limit: 20)).called(1);
});
```

### Testing Error Handling

```dart
test('shows error message when network fails', () {
  final bloc = CasesBloc(repository: mockRepo);
  
  when(mockRepo.getCases())
      .thenAnswer((_) async => Left(NetworkFailure(
        message: 'No connection',
      )));
  
  bloc.add(LoadCases());
  
  expectLater(
    bloc.stream,
    emitsInOrder([
      CasesLoading(),
      isA<CasesNetworkError>()
          .having((s) => s.message, 'message', 'No connection'),
    ]),
  );
});
```

---

## 📚 Additional Resources

- [Shimmer Documentation](https://pub.dev/packages/shimmer)
- [Dartz (Either) Guide](https://pub.dev/packages/dartz)
- [Sentry Flutter Docs](https://docs.sentry.io/platforms/flutter/)
- [Flutter Testing Best Practices](https://docs.flutter.dev/testing)

---

## ❓ FAQ

**Q: Should I use skeletons for all loading states?**
A: Use skeletons for initial page loads and first-time data fetching. For "load more" scenarios, a simple progress indicator at the bottom is fine.

**Q: When should I use PaginationMixin vs PaginatedState?**
A: Use PaginationMixin for simple screens. Use PaginatedState with BLoC when you need more control or have complex state management needs.

**Q: How do I test code that uses Sentry?**
A: Sentry calls are already wrapped in try-catch in the main initialization. For tests, you can mock Sentry or simply ensure your test environment doesn't break when Sentry is unavailable.

**Q: Should I report all errors to Sentry?**
A: Report unexpected errors and crashes. Don't report expected errors like validation failures or user cancellations.
