# Udaan Campus

A comprehensive Flutter-based campus management system and student portal for educational institutions.

## Features

- **Student Authentication**: Secure login system for students
- **Attendance Tracking**: View attendance records for all courses
- **Course Management**: Browse enrolled courses and course details
- **Student Dashboard**: Quick overview of academic performance and announcements
- **Announcements**: Stay updated with campus-wide announcements
- **Profile Management**: View and manage student profile information
- **Responsive Design**: Works seamlessly on all device sizes

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── screens/                  # Screen widgets
│   ├── login_screen.dart
│   └── home_screen.dart
├── models/                   # Data models
│   └── student.dart
├── services/                 # API and other services
│   └── api_service.dart
├── widgets/                  # Reusable widgets
├── constants/                # App-wide constants
│   └── app_constants.dart
└── utils/                    # Utility functions
    └── utils.dart
```

## Getting Started

### Prerequisites

- Flutter SDK (3.12.2 or higher)
- Dart SDK
- Git

### Installation

1. **Clone the repository** (if from version control):
   ```bash
   git clone <repository-url>
   cd udaan_campus
   ```

2. **Get dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the app**:
   ```bash
   flutter run
   ```

## Configuration

### API Configuration

Update the base URL in `lib/constants/app_constants.dart`:

```dart
static const String apiBaseUrl = 'https://your-api-url.com';
```

### Firebase Setup (Optional)

To add Firebase services:

1. Create a Firebase project
2. Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
3. Update dependencies in `pubspec.yaml`

## Dependencies

- **provider**: State management
- **http**: HTTP client
- **dio**: Advanced HTTP client with interceptors
- **shared_preferences**: Local data storage
- **intl**: Internationalization and date formatting
- **google_fonts**: Custom fonts
- **flutter_local_notifications**: Push notifications

Install dependencies:
```bash
flutter pub get
```

## Usage

### Login
1. Launch the app
2. Enter your email and password
3. Tap "Login"

### Dashboard
- View your attendance summary
- Check recent announcements
- Navigate to different sections using bottom navigation

### Attendance
- Track your attendance percentage
- View course-wise attendance details

### Courses
- View all enrolled courses
- Check course details and instructors

### Profile
- View student information
- Access your contact details
- Log out from the app

## Development

### Running Tests

```bash
flutter test
```

### Building for Release

**Android**:
```bash
flutter build apk --release
```

**iOS**:
```bash
flutter build ios --release
```

### Code Generation

If using build_runner:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Project Architecture

The app follows a modular architecture:

- **Screens**: UI layers for different pages
- **Models**: Data classes for API responses
- **Services**: Business logic and API communication
- **Widgets**: Reusable UI components
- **Utils**: Helper functions and utilities

## Contributing

1. Create a new branch for your feature
2. Make your changes
3. Submit a pull request

## Troubleshooting

### Build Issues

If you encounter build errors:

1. Clean the project:
   ```bash
   flutter clean
   ```

2. Get dependencies again:
   ```bash
   flutter pub get
   ```

3. Run pub upgrade:
   ```bash
   flutter pub upgrade
   ```

### Runtime Issues

- Check your internet connection for API calls
- Ensure the backend API is running and accessible
- Check the console logs for error details

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support, contact: support@udaancampus.com

## Roadmap

- [ ] Add more courses and course materials
- [ ] Implement assignment and quiz features
- [ ] Add grade tracking
- [ ] Implement timetable management
- [ ] Add messaging/chat feature
- [ ] Implement push notifications
- [ ] Add offline support
- [ ] Multi-language support

## Version History

### v1.0.0 (Current)
- Initial release
- Login and authentication
- Attendance tracking
- Course management
- Dashboard with announcements

---

**Last Updated**: August 2026
**Created with Flutter** ❤️
