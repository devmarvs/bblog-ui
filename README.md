# bblog UI

Flutter client for the [bblog API](https://github.com/devmarvs/bblog-ui), providing a mobile-friendly interface for managing baby/companion care logs.

> **Status:** Work in progress – expect active development and frequent changes.

## Tech Stack

- **Framework:** Flutter 3 (Material 3)
- **State management:** [flutter_riverpod](https://pub.dev/packages/flutter_riverpod)
- **Navigation:** [go_router](https://pub.dev/packages/go_router)
- **Networking:** [dio](https://pub.dev/packages/dio)
- **Secure storage:** [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage)
- **Date/time formatting:** [intl](https://pub.dev/packages/intl)

## Features

- Email/password authentication (signup, login, logout)
- Sub-user management (create and list dependents/pets)
- Activity logging with custom date & time pickers
- History view to review logs per sub-user
- Basic profile screen with sign-out shortcut

## Getting Started

### Prerequisites

- Flutter SDK `3.9.x` or higher (`sdk: ^3.9.2` in `pubspec.yaml`)
- Dart `3.9` (bundled with Flutter)
- Running instance of the bblog REST API (see `lib/core/constants.dart` to configure the base URL)

### Installation

```bash
flutter pub get
```

### Run the App

```bash
flutter run
```

### Run Static Analysis & Tests

```bash
flutter analyze
flutter test
```

## Configuration

Update `kApiBaseUrl` in `lib/core/constants.dart` to point to your bblog API environment before running the app.

## Project Structure

```
lib/
|- core/          # App-wide configuration (theme, router, networking)
|- models/        # Data models mapped from API responses
|- providers/     # Riverpod providers and state notifiers
|- repositories/  # API repositories (Auth, User, Sub-user, Logs)
|- screens/       # UI screens (login, signup, home, etc.)
`- widgets/       # Reusable UI components
```

## License

Distributed under the MIT License. See the original project for more details.
