# Astro Encyclopedia - Release Checklist

## 📋 Pre-Release Verification

### 1. Code Quality
- [ ] Run Flutter analyze: `flutter analyze`
- [ ] Fix any errors (warnings are acceptable)
- [ ] Verify all imports are correct

### 2. Asset Verification
- [ ] Verify `assets/offline/` contains all 20 images
- [ ] Verify `assets/data/tier_a/` contains all 20 JSON files
- [ ] Verify `assets/data/content_index.json` exists
- [ ] Verify `assets/icons/` contains app_icon.png, app_icon_foreground.png, splash_logo.png

### 3. App Icons & Splash Screen
Run the following commands to generate icons and splash:

```bash
# Install dependencies first
flutter pub get

# Generate app icons
dart run flutter_launcher_icons

# Generate splash screen
dart run flutter_native_splash:create
```

### 4. Verify App Configuration
- [ ] `android/app/src/main/AndroidManifest.xml`:
  - [ ] Has `<uses-permission android:name="android.permission.INTERNET"/>`
  - [ ] `android:label` is "Astro Encyclopedia"
- [ ] `pubspec.yaml`:
  - [ ] Version is set correctly (e.g., `1.0.0+1`)
  - [ ] All assets paths are defined

---

## 🏗️ Building the Release APK

### Debug Build (for testing)
```bash
cd mobile-app
flutter build apk --debug
```
**Output:** `build/app/outputs/flutter-apk/app-debug.apk`

### Release Build (for distribution)
```bash
cd mobile-app
flutter build apk --release
```
**Output:** `build/app/outputs/flutter-apk/app-release.apk`

### Split APKs (smaller size, per-architecture)
```bash
flutter build apk --split-per-abi --release
```
**Output:**
- `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` (most modern phones)
- `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk` (older phones)
- `build/app/outputs/flutter-apk/app-x86_64-release.apk` (emulators)

### App Bundle (for Play Store)
```bash
flutter build appbundle --release
```
**Output:** `build/app/outputs/bundle/release/app-release.aab`

---

## 📱 Installation

### Install on connected device
```bash
flutter install
```

### Install specific APK
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## 📊 Build Verification

After building, verify:
- [ ] APK size is under 50 MB (target: ~30-40 MB)
- [ ] App launches without crashes
- [ ] Home screen loads immediately (offline-first)
- [ ] APOD loads from network
- [ ] Search works online and offline
- [ ] Details screen shows data
- [ ] Settings screen works (cache clear, etc.)
- [ ] Navigation between tabs preserves state

---

## 🔐 Signing (for Play Store)

### Create keystore (one-time)
```bash
keytool -genkey -v -keystore astro-encyclopedia-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias astro
```

### Configure signing in `android/app/build.gradle.kts`
Add signing config for release builds (see Android documentation).

---

## 📁 Output File Locations

| Build Type | Location |
|------------|----------|
| Debug APK | `build/app/outputs/flutter-apk/app-debug.apk` |
| Release APK | `build/app/outputs/flutter-apk/app-release.apk` |
| Split APKs | `build/app/outputs/flutter-apk/app-*-release.apk` |
| App Bundle | `build/app/outputs/bundle/release/app-release.aab` |

---

## 🚀 Quick Release Commands

```bash
# Full release build sequence
cd mobile-app
flutter clean
flutter pub get
dart run flutter_launcher_icons
dart run flutter_native_splash:create
flutter build apk --release

# Verify output
ls build/app/outputs/flutter-apk/
```

---

## 📝 Version History

| Version | Date | Notes |
|---------|------|-------|
| 1.0.0 | 2025-12-25 | Initial release |

---

*Last updated: December 25, 2025*
