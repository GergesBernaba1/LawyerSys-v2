# Qadaya LawyerSys Mobile Application

A comprehensive legal practice management mobile application built with Flutter.

## 📱 Overview

The Qadaya LawyerSys mobile app provides law firms with a powerful, feature-rich mobile experience for managing cases, clients, documents, time tracking, and more.

## ✨ Recent Enhancements (Sprint 1 - April 2026)

We've significantly improved the app with the following enhancements:

- ✅ **100% Localization Coverage** - All UI strings now support English and Arabic
- ✅ **Crash Reporting** - Integrated Sentry for real-time error tracking
- ✅ **Skeleton Loading Screens** - Professional loading states using shimmer effects
- ✅ **Pagination Utilities** - Efficient data loading with infinite scroll
- ✅ **Enhanced Error Handling** - Type-safe, user-friendly error management
- ✅ **CI/CD Pipeline** - Automated testing, building, and deployment
- ✅ **Improved Code Quality** - Comprehensive linting rules and analysis

📖 **[View Full Enhancement Details](./ENHANCEMENTS_SPRINT1.md)**  
📚 **[Developer Guide for New Utilities](./DEVELOPER_GUIDE_ENHANCEMENTS.md)**

## 🚀 Features

### Core Features
- **Authentication** - Login, registration, password reset, biometric auth
- **Dashboard** - Overview of cases, tasks, and recent activity
- **Cases Management** - Create, view, edit, and track legal cases
- **Customers** - Client management with full CRUD operations
- **Documents** - Upload, view, and manage case documents
- **Time Tracking** - Track billable hours with timers
- **Billing** - Invoices, payments, and receipts
- **Calendar** - Schedule and manage hearings and events
- **Tasks** - Task management and assignment
- **Hearings** - Court hearing scheduling and tracking
- **Notifications** - Real-time push notifications

### Advanced Features
- **AI Assistant** - Summarization, drafting, and deadline suggestions
- **Document Generation** - Template-based document creation
- **E-Sign** - Electronic signature workflows
- **Court Automation** - Automated court filing
- **Client Portal** - Client document access and messaging
- **Trust Accounting** - Trust account management
- **Reports** - Business intelligence and analytics
- **Audit Logs** - Complete audit trail
- **Employee Workqueue** - Task assignment and tracking
- **Consultations** - Consultation booking and management

## 🛠️ Technology Stack

- **Framework**: Flutter 3.x
- **Language**: Dart 3.x
- **State Management**: BLoC (flutter_bloc)
- **Networking**: Dio
- **Local Storage**: sqflite, SharedPreferences, FlutterSecureStorage
- **Notifications**: Firebase Cloud Messaging
- **Authentication**: Local Auth (biometrics)
- **Crash Reporting**: Sentry Flutter
- **Error Handling**: Dartz (functional programming)
- **Image Caching**: cached_network_image
- **Dependency Injection**: get_it, injectable

## 📋 Prerequisites

- Flutter SDK 3.19.0 or higher
- Dart SDK 3.0.0 or higher
- Android Studio / Xcode for mobile development
- Firebase project (for push notifications)
- Sentry account (for crash reporting)

## 🏗️ Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/GergesBernaba1/LawyerSys-v2.git
   cd LawyerSys-v2/MobileApp
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run code generation** (for freezed, json_serializable):
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Configure environment**:
   - Update API base URL in `lib/core/api/api_constants.dart`
   - Add Firebase configuration files:
     - `android/app/google-services.json`
     - `ios/Runner/GoogleService-Info.plist`
   - Update Sentry DSN in `lib/main.dart`

5. **Run the app**:
   ```bash
   flutter run
   ```

### Building for Production

**Android**:
```bash
flutter build apk --release --split-per-abi
```

**iOS**:
```bash
flutter build ios --release
```

## 🧪 Testing

### Run all tests:
```bash
flutter test
```

### Run tests with coverage:
```bash
flutter test --coverage
```

### Run integration tests:
```bash
flutter test integration_test
```

### Run analyzer:
```bash
flutter analyze
```

### Format code:
```bash
dart format .
```

## 📁 Project Structure

```
lib/
├── app.dart                 # Main app widget
├── main.dart                # Entry point
├── core/                    # Core utilities
│   ├── api/                 # API client and constants
│   ├── auth/                # Authentication services
│   ├── error/               # Error handling (Failures)
│   ├── localization/        # Localization files
│   ├── network/             # Network utilities
│   ├── notifications/       # Push notifications
│   ├── realtime/            # SignalR real-time
│   ├── storage/             # Local storage
│   ├── sync/                # Offline sync
│   └── utils/               # Utility functions
├── features/                # Feature modules
│   ├── authentication/      # Login, register, etc.
│   ├── cases/               # Case management
│   ├── customers/           # Customer management
│   ├── documents/           # Document management
│   ├── dashboard/           # Dashboard
│   └── ... (37 modules)
└── shared/                  # Shared widgets and utilities
    ├── screens/             # Shared screens
    ├── utils/               # Pagination, etc.
    └── widgets/             # Reusable widgets
```

## 🌐 Localization

The app supports:
- English (en)
- Arabic (ar)

Localization files are located in `lib/core/localization/l10n/`.

To add new translations:
1. Add keys to `app_en.arb` and `app_ar.arb`
2. Run `flutter pub get` to regenerate localization classes
3. Use in code: `AppLocalizations.of(context)!.yourKey`

## 🔧 Configuration

### API Configuration
Update `lib/core/api/api_constants.dart`:
```dart
static const String baseUrl = 'https://your-api-url.com/api';
```

### Sentry Configuration
Update `lib/main.dart`:
```dart
options.dsn = 'YOUR_SENTRY_DSN_HERE';
```

## 📱 Platform-Specific Setup

### Android
- Minimum SDK: 21
- Target SDK: 34
- Update `android/app/build.gradle` for release signing

### iOS
- Minimum iOS: 12.0
- Update `ios/Runner/Info.plist` for permissions
- Configure code signing in Xcode

## 🤝 Contributing

1. Create a feature branch from `develop`
2. Make your changes
3. Run tests and linting
4. Submit a pull request

## 📄 License

[Specify your license here]

## 📞 Support

For support, email support@qadaya.com or create an issue in the repository.

## 🔗 Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Documentation](https://dart.dev/guides)
- [BLoC Pattern](https://bloclibrary.dev/)
- [Project Wiki](./wiki) (if available)

## 📝 Changelog

See [ENHANCEMENTS_SPRINT1.md](./ENHANCEMENTS_SPRINT1.md) for recent changes and improvements.
