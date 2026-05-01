# BetMakini - Professional iOS WebView App

BetMakini is a high-performance, App Store-compliant Flutter application built with a native shell and advanced webview integration. Designed to meet the strict 2026 iOS App Store guidelines, it provides a premium user experience through native navigation, biometrics, and robust offline handling.

## 🌟 Key Features

- **Native Shell Architecture**: Uses a native bottom navigation bar and Cupertino transitions to provide an app-like feel, bypassing Rule 4.2.2 rejections.
- **Glassmorphism UI**: Modern 2026 design aesthetic with translucent elements and blurred backgrounds.
- **Advanced WebView (v6.1.5)**: Powered by `flutter_inappwebview` with custom User Agents, JS Bridge support, and secure browsing features.
- **Native UX Enhancements**:
  - **Shimmer Loading**: Professional native loading states.
  - **Connectivity Guard**: Real-time monitoring with a custom offline fallback screen.
  - **Haptic Feedback**: Integrated for a premium tactile experience.
- **App Store Ready**: Pre-configured `Info.plist` with privacy keys for FaceID, Camera, and Microphone.

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.x recommended)
- Xcode (for iOS builds)
- CocoaPods

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure URL**
   Open `lib/core/constants/app_config.dart` and update the `baseUrl`:
   ```dart
   static const String baseUrl = "https://your-website.com";
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## 🛠 Project Structure

```text
lib/
├── core/           # Core themes, constants, and utilities
├── modules/        # Feature modules (WebView, Main Shell, Auth)
└── main.dart       # App entry point
```

## ⚖️ App Store Compliance Notes

BetMakini is designed to comply with:
- **Guideline 4.2.2 (Minimum Functionality)**: By providing a native shell and native system integrations.
- **Guideline 5.3 (Gambling)**: Structure ready for geo-restriction and licensing requirements.
- **Privacy Guidelines**: Includes all necessary `NSUsageDescription` keys.

---
Built with ❤️ by Antigravity AI
