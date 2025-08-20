# Habits & Notes

A simple Flutter app to track habits and attach notes. Works offline (Hive) and syncs with Firebase (Auth + Firestore).

## Requirements
- Flutter 3.x (stable)
- Firebase project (Auth + Firestore enabled)

## Setup (1–2 minutes)
1) Install deps
```bash
flutter pub get
```

2) Firebase
- Create a project in Firebase Console
- Enable Email/Password in Authentication
- Create a Firestore database
- Add configs to your app:
  - Android: `android/app/google-services.json`
  - iOS: `ios/Runner/GoogleService-Info.plist`
- Android Gradle (if not already present)
```gradle
// android/build.gradle
buildscript { dependencies { classpath 'com.google.gms:google-services:4.3.15' } }
// android/app/build.gradle
apply plugin: 'com.google.gms.google-services'
```

3) Generate Hive adapters
```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

4) Run
```bash
flutter run
```

## Use it
- Sign in (or sign up)
- Create a habit (pick a color)
- Tap the card’s Complete button to mark today
- Open a habit to add/edit/delete notes

## Project layout
```
lib/
  data/        # models + repositories
  logic/       # cubits (auth, habits, notes, sync)
  services/    # firebase, hive, analytics, sync
  ui/          # screens + widgets
```

## Firestore rules (optional)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      match /habits/{habitId} { allow read, write: if request.auth != null && request.auth.uid == userId; }
      match /notes/{noteId}  { allow read, write: if request.auth != null && request.auth.uid == userId; }
    }
  }
}
```

## Troubleshooting
- Stuck on splash / cannot sign in → verify Firebase configs and bundle IDs
- Firestore “permission-denied” → check rules and that you’re signed in
- Hive adapter errors → re-run the build_runner command above

## License
MIT
