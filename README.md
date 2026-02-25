# rembirth

A minimalistic app to help you remember your friends' birthdays.

## Setup
Since this app uses Isar v3 for data persistence, you’ll need to run the following command to generate the necessary code:

```sh
  dart run build_runner build
```

```sh
  flutter gen-l10n
```

```sh
  flutter build apk --release    
```

```sh
  adb install -r .\build\app\outputs\flutter-apk\app-release.apk        
```

## Debug

Get shared preferences.
```sh
  adb shell "run-as com.example.rembirth cat shared_prefs/FlutterSharedPreferences.xml"
```

Get all scheduled notifications for the app.
```sh
  adb shell dumpsys alarm | grep com.example.rembirth
```

## Release
Releases are fully automated using GitHub Actions. To deploy a new version:

1.  **Update Version:** Bump the version in `pubspec.yaml`
    * **Important:** The **build number** must **always increase** and **never reset** for any version changes
2.  **Commit, Tag & Push:** Use the commit message format `🔖 vX.Y.Z+N` for the version change in the `pubspec.yaml`, create a tag matching the version (excluding the build number) and push it.

```bash
git tag v1.0.0
git push origin v1.0.0
```