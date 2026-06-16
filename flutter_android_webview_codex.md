# Flutter Android WebView App - Codex Implementation Guide

## 1. Project Goal

Create a simple Android mobile app using **Flutter** that loads an existing hosted website inside a WebView.

The website is already hosted and will be displayed inside the mobile app.

### Main Objective

Build a clean, stable, production-ready Android WebView application with:

- Flutter framework
- Android WebView support
- Website URL loading
- Back button handling
- Loading indicator
- Internet error handling
- Pull-to-refresh
- External link handling
- File upload support
- Download support
- App icon and splash screen preparation
- Android permission configuration
- Release build support

---

## 2. Technology Stack

Use the following stack:

```text
Framework: Flutter
Language: Dart
Platform: Android
WebView Package: webview_flutter
Target Output: APK / AAB
```

Recommended packages:

```yaml
dependencies:
  flutter:
    sdk: flutter

  webview_flutter: latest
  connectivity_plus: latest
  url_launcher: latest
  permission_handler: latest
  flutter_native_splash: latest
  flutter_launcher_icons: latest
```

Codex should use the latest stable compatible package versions.

---

## 3. App Concept

The app is a WebView wrapper for a hosted website.

Example:

```text
Flutter Android App
        ↓
WebView Screen
        ↓
Loads Hosted Website URL
```

Replace this placeholder with the actual website URL:

```dart
const String websiteUrl = "https://yourdomain.com";
```

---

## 4. Required App Features

### 4.1 WebView Page

Create a main WebView screen that loads the hosted website.

Requirements:

- Load the website URL.
- Enable JavaScript.
- Enable DOM storage.
- Support HTTPS website.
- Show loading progress.
- Handle navigation inside the app.
- Prevent blank screen on slow connection.

---

### 4.2 Loading Indicator

Show a loading indicator while the website is loading.

Recommended behavior:

```text
Page loading starts → show progress bar
Page loading finishes → hide progress bar
Page loading error → show error page
```

The loading indicator should be compact and not disturb the user experience.

---

### 4.3 Android Back Button Handling

When the user presses the Android back button:

```text
If WebView can go back:
    Go back in WebView history
Else:
    Exit app or ask user to press again to exit
```

Preferred UX:

```text
Press back once → go to previous web page
If no previous page → press back twice to exit
```

---

### 4.4 Internet Connection Handling

The app should detect internet availability.

If there is no internet connection, show a clean error screen:

```text
No Internet Connection
Please check your connection and try again.
[Retry]
```

When the user taps Retry:

```text
Check connection again
Reload WebView if internet is available
```

---

### 4.5 WebView Error Handling

Handle common WebView errors:

- No internet
- Timeout
- Page not found
- SSL error
- Server unavailable

Show a user-friendly error page instead of a blank screen.

Example message:

```text
Unable to load the page.
Please check your internet connection or try again later.
```

---

### 4.6 Pull to Refresh

Add pull-to-refresh support.

Behavior:

```text
User pulls down on WebView
        ↓
Current webpage reloads
```

Use Flutter's refresh UI if compatible with the selected WebView implementation.

---

### 4.7 External Link Handling

Some links should open outside the WebView.

Open these externally:

```text
tel:
mailto:
sms:
whatsapp:
facebook:
messenger:
viber:
telegram:
external PDF links if required
```

Use `url_launcher` for external links.

Normal internal website links should remain inside the WebView.

---

### 4.8 File Upload Support

Support file upload from HTML input fields:

```html
<input type="file" />
```

The app should allow users to upload:

- Images
- PDF files
- Documents

Required Android permissions may include:

```xml
READ_EXTERNAL_STORAGE
READ_MEDIA_IMAGES
READ_MEDIA_VIDEO
CAMERA
```

Use only the permissions actually needed by the app.

---

### 4.9 Download Support

If the website contains downloadable files, support Android file download.

Examples:

- PDF
- Excel
- Word
- Images

Expected behavior:

```text
User taps download link
        ↓
File downloads to Android Downloads folder
        ↓
User sees success/failure message
```

If full download manager implementation is too large, create a basic structure and TODO section for download handling.

---

## 5. Recommended Folder Structure

Create a clean Flutter project structure:

```text
lib/
├── main.dart
├── app.dart
├── config/
│   └── app_config.dart
├── screens/
│   └── webview_screen.dart
├── widgets/
│   ├── loading_progress_bar.dart
│   └── error_view.dart
└── services/
    ├── connectivity_service.dart
    └── external_url_service.dart
```

---

## 6. Configuration File

Create:

```text
lib/config/app_config.dart
```

Content:

```dart
class AppConfig {
  static const String appName = "Your App Name";
  static const String websiteUrl = "https://yourdomain.com";
}
```

All URL and app name configuration should be managed from this file.

Do not hardcode the website URL in multiple files.

---

## 7. Main App Requirements

### 7.1 main.dart

Responsibilities:

- Initialize Flutter binding.
- Launch the app.

Expected structure:

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}
```

---

### 7.2 app.dart

Responsibilities:

- Define MaterialApp.
- Disable debug banner.
- Set app title.
- Load WebViewScreen as home.

Requirements:

```dart
MaterialApp(
  debugShowCheckedModeBanner: false,
  title: AppConfig.appName,
  home: const WebViewScreen(),
)
```

---

## 8. WebView Screen Requirements

Create:

```text
lib/screens/webview_screen.dart
```

The screen should include:

- WebView controller
- Loading progress state
- Error state
- Internet check
- Back button handling
- Pull refresh
- External link detection

Pseudo behavior:

```text
On screen load:
    Check internet
    If internet available:
        Load website URL
    Else:
        Show error view
```

Navigation behavior:

```text
If URL starts with tel:, mailto:, sms:, whatsapp:, etc:
    Open external app
Else:
    Continue loading inside WebView
```

---

## 9. Android Configuration

Update:

```text
android/app/src/main/AndroidManifest.xml
```

Required permission:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

Optional permissions depending on website features:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="28" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
```

Add inside application if needed:

```xml
android:usesCleartextTraffic="false"
```

Use HTTPS website only.

---

## 10. App Branding

Prepare the following assets:

```text
assets/
├── icon/
│   └── app_icon.png
└── splash/
    └── splash_logo.png
```

Use:

```text
flutter_launcher_icons
flutter_native_splash
```

Expected branding items:

- App name
- App icon
- Splash screen
- Primary color
- Privacy policy URL

---

## 11. Splash Screen

Configure `flutter_native_splash`.

Example configuration in `pubspec.yaml`:

```yaml
flutter_native_splash:
  color: "#FFFFFF"
  image: assets/splash/splash_logo.png
  android: true
  ios: false
```

Generate splash screen:

```bash
dart run flutter_native_splash:create
```

---

## 12. App Icon

Configure `flutter_launcher_icons`.

Example configuration in `pubspec.yaml`:

```yaml
flutter_launcher_icons:
  android: true
  ios: false
  image_path: "assets/icon/app_icon.png"
```

Generate app icon:

```bash
dart run flutter_launcher_icons
```

---

## 13. Build Commands

Run the app:

```bash
flutter pub get
flutter run
```

Build APK:

```bash
flutter build apk --release
```

Build Android App Bundle for Google Play:

```bash
flutter build appbundle --release
```

---

## 14. Testing Checklist

Before release, test the following:

### Website Loading

- [ ] Website loads correctly
- [ ] HTTPS works
- [ ] Login works
- [ ] Logout works
- [ ] Session persists correctly
- [ ] Website is mobile responsive

### Navigation

- [ ] Internal links open inside app
- [ ] Android back button works
- [ ] Double back to exit works
- [ ] External links open external apps

### Network

- [ ] App handles no internet
- [ ] Retry button works
- [ ] Slow internet does not show blank screen

### Upload / Download

- [ ] File upload works
- [ ] Image upload works
- [ ] PDF upload works
- [ ] File download works or shows proper TODO/fallback

### Android Device Testing

- [ ] Android 8+
- [ ] Android 10+
- [ ] Android 12+
- [ ] Android 13+
- [ ] Android 14+

### Release

- [ ] App icon added
- [ ] Splash screen added
- [ ] App name correct
- [ ] Version number correct
- [ ] Privacy policy ready
- [ ] Release APK builds successfully
- [ ] AAB builds successfully

---

## 15. Google Play Store Preparation

Prepare:

```text
App name
Short description
Full description
App icon
Feature graphic
Screenshots
Privacy policy URL
Support email
Package name
Signed AAB file
```

Recommended package name format:

```text
com.companyname.appname
```

Example:

```text
com.sunfix.purchase_request
```

---

## 16. Security Requirements

Codex must follow these rules:

- Do not store user passwords inside Flutter code.
- Do not hardcode sensitive API keys.
- Use HTTPS only.
- Do not allow unknown external domains unless required.
- Validate external URL handling.
- Do not enable cleartext HTTP traffic unless explicitly required.
- Do not expose website cookies or session data in logs.

---

## 17. UX Requirements

The app should feel simple and smooth.

Required UX behavior:

- Fast app launch
- Clean splash screen
- No browser address bar
- Loading progress feedback
- Friendly error messages
- Smooth back navigation
- Minimal UI chrome
- Full-screen WebView layout

Recommended visual style:

```text
Clean
Compact
Business-friendly
Lightweight
Professional
```

---

## 18. Codex Implementation Tasks

Codex should implement the project in this order:

1. Create Flutter project structure.
2. Add required dependencies.
3. Configure `AppConfig`.
4. Create `WebViewScreen`.
5. Implement website loading.
6. Add loading progress bar.
7. Add internet connection checking.
8. Add error screen with retry button.
9. Add Android back button handling.
10. Add external URL handling.
11. Add pull-to-refresh.
12. Configure Android permissions.
13. Add app icon configuration.
14. Add splash screen configuration.
15. Add release build notes.
16. Verify build with `flutter analyze`.
17. Verify release build with `flutter build apk --release`.

---

## 19. Acceptance Criteria

The implementation is complete when:

- App runs on Android emulator and real device.
- Website loads inside WebView.
- JavaScript website features work.
- Back button works properly.
- No internet screen appears when offline.
- Retry button reloads page.
- External links open correctly.
- App icon and splash screen are configurable.
- APK release build succeeds.
- Code is clean and easy to modify.

---

## 20. Notes for Codex

Use clean, maintainable Flutter code.

Avoid unnecessary complexity.

Do not create native Android code unless required.

Prioritize:

```text
Stability
Simple UX
Maintainability
Production readiness
```

All configurable values should be centralized in:

```text
lib/config/app_config.dart
```

Use comments only where helpful.

Do not over-engineer the app.
