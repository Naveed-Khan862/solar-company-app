# Solar Company App

A Flutter service-management app for a solar energy company. Customers file service requests (complaints, inspections, panel washing), track their status, and rate completed work; sub-admins handle assigned requests; the admin manages the team and everything in between.

## Features

- **Auth**: email/password, Google Sign-In, forgot password, optional fingerprint login
- **Roles**: user, sub-admin, admin (owner configurable via Firestore)
- **Service requests**: create with priority/address/phone → assigned → status updates → rating after completion
- **Team management**: admins organize sub-admins into teams
- **In-app chat**: support, admin, sub-admin, per-team, and per-request channels (participant-gated)
- **Notifications & reports**: request updates, CSV report export
- **Profile**: photo upload, dark/light theme

## Tech Stack

- Flutter / Dart (Riverpod 2.x for state management)
- Firebase: Auth, Firestore, Storage, Crashlytics, App Check (Play Integrity on release)
- Android + Web targets

## Getting Started

```bash
flutter pub get
flutter run
```

> **Firebase config:** `google-services.json`, `firebase_options.dart`, and release signing files are intentionally **not** committed. Add your own via `flutterfire configure` before building. The Firestore rules (`firestore.rules`) and storage rules (`storage.rules`) are versioned in this repo — review and deploy them to your Firebase project.

## Project Structure

```
lib/
├── main.dart            # entry point (App Check, Crashlytics)
├── screens/             # 16 screens (auth, requests, admin, chat, reports...)
├── providers/           # Riverpod providers (hand-written + codegen)
├── repositories/        # Firestore-backed data layer
├── services/            # auth, local storage, secure credentials
├── models/              # user, profile, service_request, chat, notification
├── widgets/             # themed UI components
└── theme/ constants/    # app chrome
```

## Tests

```bash
flutter test
```

## License

MIT