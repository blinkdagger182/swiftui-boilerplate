# SwiftUI MVVM+C Boilerplate

A clean, scalable architecture for SwiftUI projects using MVVM+C (Model-View-ViewModel + Coordinator) pattern.

## Project Features

- **Clean MVVM+C Architecture**: Clear separation of concerns with Models, Views, ViewModels, and Coordinators
- **Onboarding Flow**: 3 screen onboarding flow that can be swiped through or skipped
- **Dependency Injection**: Using environment objects for clean dependency management
- **RevenueCat Integration**: Complete subscription management system
- **Feature Flags System**: Toggle features remotely with a mock implementation
- **Version Control with Supabase**: Force and optional update system with Supabase backend
- **Reactive Programming**: Using Combine for reactive data flows
- **Code Quality Tools**: SwiftLint and SwiftFormat configured for best practices
- **Light & Dark Mode Support**: Automatic support for both light and dark modes

## Project Structure

```
SwiftUI-MVVM-Boilerplate/
├── App/                     # App entry point and coordinator views
├── Core/                    # Core components
│   ├── Data/                # Data layer (persistence, caching)
│   ├── Extensions/          # Swift extensions
│   ├── Models/              # Domain models
│   ├── Network/             # Networking components
│   ├── Services/            # Application services
│   └── Utilities/           # Helper utilities
├── Features/                # Feature modules
│   ├── MainScreen/          # Main screen feature
│   ├── Onboarding/          # Onboarding feature
│   └── Subscription/        # Subscription feature
├── Resources/               # App resources
│   ├── Assets/              # Asset catalogs
│   ├── Configurations/      # Configuration files
│   └── Fonts/               # Custom fonts
└── UI/                      # Shared UI components
    ├── Components/          # Reusable views
    ├── Modifiers/           # View modifiers
    └── Styles/              # UI styles
```

## Getting Started

### Prerequisites

- Xcode 15.0 or later
- iOS 16.0+ deployment target
- Swift 5.9 or later

### Installation

1. Clone the repository
2. Open the project in Xcode
3. Install dependencies (if using CocoaPods or Swift Package Manager)
4. Build and run

## RevenueCat Integration

This boilerplate includes a complete RevenueCat integration for handling subscriptions:

1. Replace the dummy API key in `SplashView.swift` with your actual RevenueCat API key
2. Configure your product IDs in `SubscriptionManager.swift`
3. Set up your entitlements in the RevenueCat dashboard

## Supabase Version Control

The project includes a version control system using Supabase:

1. The system checks for app updates during app startup
2. It can force updates for critical versions or show optional update prompts
3. Users can dismiss optional updates until the next version is available

To set up:

1. Create a Supabase project and database with an `app_versions` table with the following structure:
   - `id`: Auto-incrementing integer primary key
   - `created_at`: Timestamp
   - `platform`: Text (e.g., "ios", "android")
   - `version_name`: Text (e.g., "1.2.0")
   - `version_code`: Integer (e.g., 120)
   - `release_notes`: Text with update information
   - `force_update`: Boolean indicating if update is mandatory

2. Update the Supabase URL and API key in `UpdateService.swift`

## Feature Flags

The project includes a feature flags system for toggling features remotely:

- In development/debug mode, flags can be toggled locally
- In production, flags would be fetched from a remote server

To add a new feature flag:

1. Add a new case to the `FeatureFlag` enum in `FeatureFlagsService.swift`
2. Access it using `featureFlagsService.isEnabled(.yourFeature)`

## License

This project is licensed under the MIT License - see the LICENSE file for details. # swiftui-boilerplate
