# ScanVault 📄

A Flutter document scanning app that lets you scan, organize, and manage your documents with ease. Built with clean architecture principles and GetX state management.

![Flutter](https://img.shields.io/badge/Flutter-3.38%2B-blue?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.10%2B-blue?logo=dart)
![License](https://img.shields.io/badge/License-MIT-green)

---

## ✨ Features

- **Document Scanning** - Scan documents using your device camera with automatic edge detection
- **Multi-page Support** - Scan up to 24 pages in a single session
- **PDF & Image Export** - Save scans as PDF or JPEG images
- **History Management** - Browse, search, and filter your scan history
- **Favorites** - Mark important documents for quick access
- **Missing File Detection** - Automatically detects if files were deleted outside the app
- **Duplicate Prevention** - Intelligent deduplication prevents duplicate entries
- **Lazy Loading** - Smooth scrolling with pagination for large collections

---

## 📱 Screenshots

<!-- Add your screenshots here -->
| Home Screen | Scan View | File Details |
|-------------|-----------|--------------|
| Screenshot  | Screenshot | Screenshot   |

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `>=3.38.0`
- Dart SDK `>=3.10.0`
- Android SDK (minSdk 28) for Android builds
- Xcode 15+ for iOS builds

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/scan_vault.git
   cd scan_vault
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

---

## 🏗️ Architecture

ScanVault follows a **clean architecture** pattern with clear separation of concerns:

```
lib/
├── data/
│   ├── models/           # Data models (ProcessedFile)
│   ├── repositories/     # Data access layer
│   └── sources/          # Database configuration
├── presentation/
│   ├── controllers/      # GetX controllers
│   ├── screens/          # UI screens
│   ├── widgets/          # Reusable widgets
│   └── utils/            # Formatters & helpers
└── services/
    ├── scan_service.dart    # Document scanning logic
    └── scan_storage.dart    # File storage management
```

### Key Components

| Component | Description |
|-----------|-------------|
| `ProcessedFileRepository` | Abstract interface for file operations |
| `SqfliteProcessedFileRepository` | SQLite implementation with deduplication |
| `HistoryController` | GetX controller managing UI state |
| `ScanService` | Wrapper for document scanner SDK |

---

## 📦 Dependencies

| Package | Purpose |
|---------|---------|
| `get` | State management & dependency injection |
| `sqflite` | Local SQLite database |
| `path_provider` | File system access |
| `simplest_document_scanner` | Camera-based document scanning |
| `open_filex` | Open files with system apps |
| `uuid` | Generate unique identifiers |
| `intl` | Date/number formatting |

---

## 🧪 Testing

Run the test suite:

```bash
flutter test
```

### Test Coverage

- **Repository Tests** - CRUD operations, deduplication, existence checks
- **Widget Tests** - UI component rendering

---

## 🔧 Configuration

### Android

The app requires Android SDK 28+ due to the document scanner library. This is configured in:

```kotlin
// android/app/build.gradle.kts
android {
    defaultConfig {
        minSdk = 28
    }
}
```

### iOS

No additional configuration required. The scanner uses the native VisionKit framework.

---

## 📋 Edge Case Handling

| Scenario | Behavior |
|----------|----------|
| File deleted externally | Shows "Missing" badge, disables "Open" |
| Duplicate scan | Merges with existing entry |
| Delete failure | Shows warning with failed paths |
| Large collection | Paginated loading (30 items/page) |

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 🙏 Acknowledgments

- [simplest_document_scanner](https://pub.dev/packages/simplest_document_scanner) for the scanning SDK
- [GetX](https://pub.dev/packages/get) for state management
