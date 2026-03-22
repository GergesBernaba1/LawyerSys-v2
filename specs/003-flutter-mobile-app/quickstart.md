# Quickstart Guide: Flutter Mobile App Development

**Feature**: 003-flutter-mobile-app  
**Date**: 2026-03-20  
**Phase**: 1 (Design & Contracts)

## Overview

This guide helps developers set up their environment, run the LawyerSys Flutter mobile app, and understand the codebase structure. Follow these steps to get started with mobile app development.

---

## Prerequisites

### Required Software

1. **Flutter SDK 3.x**
   - Download: https://flutter.dev/docs/get-started/install
   - Verify: `flutter --version` (should show 3.x)
   - Run: `flutter doctor` to check for issues

2. **Dart SDK 3.x**
   - Included with Flutter (no separate installation)
   - Verify: `dart --version`

3. **IDE** (Choose one):
   - **Visual Studio Code** (recommended for Flutter):
     - Install Flutter extension: `Flutter` by Dart Code
     - Install Dart extension: `Dart` by Dart Code
   - **Android Studio**:
     - Install Flutter plugin via plugin marketplace
     - Install Dart plugin via plugin marketplace

4. **Platform-Specific Tools**:

   **For Android Development**:
   - Android Studio (includes Android SDK and emulator)
   - Java Development Kit (JDK) 11 or newer
   - Android SDK Platform-Tools
   - Android Emulator or physical Android device (8.0+)

   **For iOS Development** (macOS only):
   - Xcode 13+ from Mac App Store
   - CocoaPods: `sudo gem install cocoapods`
   - iOS Simulator or physical iOS device (iOS 13+)
   - Apple Developer account (for device testing)

5. **Git** for version control

---

## Initial Setup

### 1. Clone Repository

```bash
cd "d:\Gerges Files\Ahemd- Taajeer\LawyerSystem\LawyerSys-v2"
git checkout 003-flutter-mobile-app
```

### 2. Navigate to Mobile App Directory

```bash
cd MobileApp
```

### 3. Install Dependencies

```bash
flutter pub get
```

This downloads all packages defined in `pubspec.yaml`.

### 4. Verify Flutter Setup

```bash
flutter doctor -v
```

Ensure all checks pass (green checkmarks). Common issues:
- Android licenses not accepted: `flutter doctor --android-licenses`
- Xcode not configured: Open Xcode once to complete setup

---

## Running the App

### Development Mode (Hot Reload Enabled)

**On Android Emulator/Device**:

1. Start Android emulator:
   - Open Android Studio → AVD Manager → Start emulator
   - Or: Physical device connected via USB with USB debugging enabled

2. Run app:
   ```bash
   flutter run
   ```

3. Hot reload:
   - Press `r` in terminal for hot reload (fast UI updates)
   - Press `R` for hot restart (full app restart)
   - Save files in VS Code (auto hot reload if enabled)

**On iOS Simulator/Device**:

1. Start iOS Simulator:
   ```bash
   open -a Simulator
   ```

2. Run app:
   ```bash
   flutter run
   ```

3. For physical iOS device:
   - Connect device via USB
   - Trust computer on device
   - Xcode signing: `open ios/Runner.xcworkspace` → Signing & Capabilities → Select Team

**List Available Devices**:
```bash
flutter devices
```

**Run on Specific Device**:
```bash
flutter run -d <device-id>
```

---

## Configuration

### API Base URL

Edit `lib/core/api/api_constants.dart`:

```dart
class ApiConstants {
  static const String baseUrl = 'https://api.lawyersys.example.com';
  // For local development:
  // static const String baseUrl = 'http://10.0.2.2:5000';  // Android emulator
  // static const String baseUrl = 'http://localhost:5000';  // iOS simulator
}
```

### Firebase Configuration (Push Notifications)

**Android**:
1. Obtain `google-services.json` from Firebase Console
2. Place in `android/app/google-services.json`

**iOS**:
1. Obtain `GoogleService-Info.plist` from Firebase Console
2. Place in `ios/Runner/GoogleService-Info.plist`
3. Xcode: Add file to Runner target

---

## Project Structure Overview

```
MobileApp/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── app.dart                     # MaterialApp configuration
│   ├── core/                        # Shared infrastructure
│   │   ├── api/                     # HTTP client, interceptors
│   │   ├── storage/                 # Secure storage, SQLite, preferences
│   │   ├── sync/                    # Offline sync service
│   │   ├── notifications/           # Push notifications
│   │   ├── auth/                    # Biometric auth
│   │   └── localization/            # i18n (Arabic/English)
│   ├── features/                    # Feature modules (BLoC pattern)
│   │   ├── authentication/
│   │   ├── dashboard/
│   │   ├── cases/
│   │   ├── hearings/
│   │   ├── customers/
│   │   └── documents/
│   └── shared/                      # Shared widgets and utilities
├── test/                            # Unit and widget tests
├── integration_test/                # End-to-end tests
├── android/                         # Android platform code
├── ios/                             # iOS platform code
└── pubspec.yaml                     # Dependencies
```

---

## Development Workflow

### 1. Feature Development Pattern

Each feature follows this structure:

```
features/{feature_name}/
├── bloc/                            # State management
│   ├── {feature}_bloc.dart          # Business logic
│   ├── {feature}_event.dart         # User actions
│   └── {feature}_state.dart         # UI states
├── models/                          # Data models
│   └── {entity}.dart                # Entity class with JSON serialization
├── repositories/                    # Data access layer
│   └── {feature}_repository.dart    # API calls, caching
└── screens/                         # UI screens
    └── {screen}_screen.dart         # Flutter widgets
```

**Example: Creating a new case screen**

1. Define events in `lib/features/cases/bloc/cases_event.dart`:
   ```dart
   abstract class CasesEvent {}
   class LoadCases extends CasesEvent {}
   class SearchCases extends CasesEvent {
     final String query;
     SearchCases(this.query);
   }
   ```

2. Define states in `lib/features/cases/bloc/cases_state.dart`:
   ```dart
   abstract class CasesState {}
   class CasesInitial extends CasesState {}
   class CasesLoading extends CasesState {}
   class CasesLoaded extends CasesState {
     final List<Case> cases;
     CasesLoaded(this.cases);
   }
   class CasesError extends CasesState {
     final String message;
     CasesError(this.message);
   }
   ```

3. Implement BLoC in `lib/features/cases/bloc/cases_bloc.dart`:
   ```dart
   class CasesBloc extends Bloc<CasesEvent, CasesState> {
     final CasesRepository repository;
     
     CasesBloc(this.repository) : super(CasesInitial()) {
       on<LoadCases>(_onLoadCases);
       on<SearchCases>(_onSearchCases);
     }
     
     Future<void> _onLoadCases(LoadCases event, Emitter<CasesState> emit) async {
       emit(CasesLoading());
       try {
         final cases = await repository.getCases();
         emit(CasesLoaded(cases));
       } catch (e) {
         emit(CasesError(e.toString()));
       }
     }
   }
   ```

4. Build UI in `lib/features/cases/screens/cases_list_screen.dart`:
   ```dart
   class CasesListScreen extends StatelessWidget {
     @override
     Widget build(BuildContext context) {
       return BlocBuilder<CasesBloc, CasesState>(
         builder: (context, state) {
           if (state is CasesLoading) {
             return Center(child: CircularProgressIndicator());
           } else if (state is CasesLoaded) {
             return ListView.builder(
               itemCount: state.cases.length,
               itemBuilder: (context, index) {
                 final case = state.cases[index];
                 return ListTile(
                   title: Text(case.caseNumber),
                   subtitle: Text(case.customerFullName),
                 );
               },
             );
           } else if (state is CasesError) {
             return Center(child: Text(state.message));
           }
           return Container();
         },
       );
     }
   }
   ```

### 2. Adding Translations

Edit localization files:

**English** (`lib/core/localization/l10n/app_en.arb`):
```json
{
  "@@locale": "en",
  "loginTitle": "Login",
  "@loginTitle": {
    "description": "Title for login screen"
  },
  "caseNumber": "Case Number",
  "search": "Search"
}
```

**Arabic** (`lib/core/localization/l10n/app_ar.arb`):
```json
{
  "@@locale": "ar",
  "loginTitle": "تسجيل الدخول",
  "@loginTitle": {
    "description": "Title for login screen"
  },
  "caseNumber": "رقم القضية",
  "search": "بحث"
}
```

Generate localization code:
```bash
flutter gen-l10n
```

Use in code:
```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

Text(AppLocalizations.of(context)!.loginTitle)
```

### 3. RTL Layout Testing

Test both LTR and RTL:

1. Change device language to Arabic in iOS Simulator or Android Emulator settings
2. Or set locale in `main.dart` for testing:
   ```dart
   MaterialApp(
     locale: Locale('ar'),  // Force Arabic
     // ... rest of config
   )
   ```

3. Verify:
   - Text aligns right
   - Navigation drawer opens from right
   - Icons mirror (back arrow flips)
   - No text overflow or layout breaks

---

## Testing

### Unit Tests

Run all unit tests:
```bash
flutter test
```

Run specific test file:
```bash
flutter test test/unit/auth_bloc_test.dart
```

**Example Unit Test** (`test/unit/auth_bloc_test.dart`):
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('AuthBloc', () {
    test('emits AuthLoading then AuthAuthenticated on successful login', () async {
      // Arrange
      final repository = MockAuthRepository();
      when(repository.login(any, any)).thenAnswer((_) async => mockUserSession);
      final bloc = AuthBloc(repository);
      
      // Act
      bloc.add(LoginRequested('user@example.com', 'password'));
      
      // Assert
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          isA<AuthAuthenticated>(),
        ]),
      );
    });
  });
}
```

### Widget Tests

Test UI components:
```bash
flutter test test/widget/login_screen_test.dart
```

**Example Widget Test**:
```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Login screen displays email and password fields', (tester) async {
    await tester.pumpWidget(MyApp());
    
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
}
```

### Integration Tests

Run end-to-end tests:
```bash
flutter test integration_test/app_test.dart
```

**Example Integration Test**:
```dart
import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Complete login flow', (tester) async {
    app.main();
    await tester.pumpAndSettle();
    
    // Enter credentials
    await tester.enterText(find.byKey(Key('emailField')), 'test@example.com');
    await tester.enterText(find.byKey(Key('passwordField')), 'password123');
    
    // Tap login button
    await tester.tap(find.byKey(Key('loginButton')));
    await tester.pumpAndSettle();
    
    // Verify dashboard appears
    expect(find.text('Dashboard'), findsOneWidget);
  });
}
```

### Code Coverage

Generate coverage report:
```bash
flutter test --coverage
```

View coverage in browser:
```bash
# Install genhtml (if not installed)
# On macOS: brew install lcov
# On Windows: Download lcov from GitHub

genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## Debugging

### Debug Mode

Run app with debugging:
```bash
flutter run --debug
```

**VS Code Launch Configuration** (`.vscode/launch.json`):
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Flutter (Debug)",
      "type": "dart",
      "request": "launch",
      "program": "lib/main.dart"
    },
    {
      "name": "Flutter (Profile)",
      "type": "dart",
      "request": "launch",
      "program": "lib/main.dart",
      "flutterMode": "profile"
    }
  ]
}
```

Set breakpoints in VS Code by clicking left of line numbers.

### Flutter DevTools

Launch DevTools:
```bash
flutter run
# In another terminal:
flutter pub global activate devtools
flutter pub global run devtools
```

Features:
- **Inspector**: UI widget tree inspection
- **Timeline**: Performance profiling
- **Network**: API request/response monitoring
- **Logging**: Console output and error logs
- **Memory**: Memory usage analysis

### Logging

Use `print` for quick debugging or Dart's `log` for structured logging:

```dart
import 'dart:developer' as developer;

developer.log('Login successful', name: 'AuthBloc', error: null);
```

---

## Building Release Versions

### Android APK

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle (for Google Play)

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### iOS

```bash
flutter build ios --release
```

Then open `ios/Runner.xcworkspace` in Xcode:
1. Select Runner target
2. Product → Archive
3. Distribute App to TestFlight or App Store

---

## Common Issues & Solutions

### Issue: "Waiting for another flutter command to release the startup lock"

**Solution**:
```bash
# Delete lock file
rm <flutter-sdk-path>/.flutter_tool_state
```

### Issue: Android emulator not detected

**Solution**:
1. Ensure emulator is running
2. Check: `adb devices`
3. Restart adb: `adb kill-server && adb start-server`

### Issue: iOS build fails with CocoaPods error

**Solution**:
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter run
```

### Issue: Hot reload not working

**Solution**:
1. Full restart: Press `R` in terminal
2. Or: `flutter clean && flutter pub get && flutter run`

### Issue: JSON serialization errors

**Solution**: Ensure model classes have proper `fromJson` and `toJson` methods. Check for null safety violations.

---

## Next Steps

1. **Read Documentation**:
   - [plan.md](plan.md): Technical design decisions
   - [research.md](research.md): Technology choices and rationale
   - [data-model.md](data-model.md): Data structures and SQLite schema
   - [contracts/api-contracts.md](contracts/api-contracts.md): API endpoints

2. **Implement User Stories**:
   - Start with US-001 (Login & Dashboard) as foundation
   - Follow BLoC pattern for state management
   - Test each feature in both Arabic and English

3. **Configure Backend API**:
   - Ensure ASP.NET Core API is running locally or on test server
   - Update `api_constants.dart` with correct base URL
   - Verify JWT token authentication works

4. **Set Up Firebase**:
   - Create Firebase project
   - Add Android and iOS apps to Firebase Console
   - Download configuration files
   - Test push notifications

---

## Additional Resources

- **Flutter Docs**: https://flutter.dev/docs
- **Dart Language Tour**: https://dart.dev/guides/language/language-tour
- **BLoC Pattern**: https://bloclibrary.dev/
- **Material Design 3**: https://m3.material.io/
- **Flutter Codelabs**: https://flutter.dev/codelabs
- **Firebase for Flutter**: https://firebase.google.com/docs/flutter/setup

---

**End of Quickstart Guide**
