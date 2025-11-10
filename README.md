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