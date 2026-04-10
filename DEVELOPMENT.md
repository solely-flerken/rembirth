# Development

## Prerequisites

This app uses Isar v3 for local data persistence. Generate the required code before building:

```sh
dart run build_runner build
```

Generate localizations:

```sh
flutter gen-l10n
```

## Build

```sh
flutter build apk --release
```

Signed app bundle:

```sh
flutter build appbundle --release
```

Install on a connected device:

```sh
adb install -r .\build\app\outputs\flutter-apk\app-release.apk
```

## Debug

Get shared preferences:

```sh
adb shell "run-as com.solely.rembirth cat shared_prefs/FlutterSharedPreferences.xml"
```

Get all scheduled alarms for the app:

```sh
adb shell dumpsys alarm | grep com.solely.rembirth
```

## Release

Releases are fully automated via GitHub Actions. To deploy a new version:

1. **Update version** — Bump the version in `pubspec.yaml`
   - The **build number** must **always increase** and never reset across any version change
2. **Release notes** — Optionally update the `whatsnew/` directory
3. **Commit, tag & push** — Use the commit message format `🔖 vX.Y.Z+N`, create a matching tag (without the build number), and push:

```sh
git tag v1.0.0
git push origin v1.0.0
```
