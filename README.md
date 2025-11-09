# rembirth

A minimalistic app to help you remember your friends' birthdays.

## Setup
Since this app uses Isar v4 for data persistence, you’ll need to run the following command to generate the necessary code:

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