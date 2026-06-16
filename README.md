# Purchase Request WebView App

Android Flutter app that loads a hosted website inside a WebView.

## Configure

Update all app-level values in:

```text
lib/config/app_config.dart
```

Important values:

- `appName`
- `websiteUrl`
- `privacyPolicyUrl`
- `additionalWebViewHosts`

The app only allows HTTPS pages inside the WebView. Unknown web domains and special schemes such as `tel:`, `mailto:`, `sms:`, WhatsApp, Facebook, Viber, and Telegram open externally.

## Branding

Placeholder assets are included:

```text
assets/icon/app_icon.png
assets/splash/splash_logo.png
```

After replacing them, generate Android resources:

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

## Run

```bash
flutter pub get
flutter run
```

## Verify

```bash
flutter analyze
flutter test
flutter build apk --release
flutter build appbundle --release
```

The release build currently uses Flutter's debug signing config. Configure a production keystore before publishing to Google Play.
