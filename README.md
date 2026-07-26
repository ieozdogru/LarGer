<p align="center">
  <img src="assets/logo.png" alt="LarGer logo" width="120" />
</p>

<h1 align="center">LarGer</h1>

<p align="center">
  <strong>Local-first gym workout tracker</strong><br />
  Build routines, log sets, review history, and track PRs — on your device.
</p>

<p align="center">
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-stable-02569B?logo=flutter&logoColor=white" />
  <img alt="Dart" src="https://img.shields.io/badge/Dart-%5E3.9.2-0175C2?logo=dart&logoColor=white" />
  <img alt="Firebase Auth" src="https://img.shields.io/badge/Firebase-Auth-FFCA28?logo=firebase&logoColor=black" />
  <img alt="License" src="https://img.shields.io/badge/license-private-lightgrey" />
</p>

---

## Features

| Area | What you get |
|------|----------------|
| **Auth** | Email/password sign-in via Firebase Auth |
| **Workout** | Start empty or from a routine; live timer; log reps/weight; reorder exercises |
| **Routines** | Create, edit, and delete routines with target set counts (same tab as Workout) |
| **History** | Calendar of past sessions; edit or delete workouts |
| **Profile** | Height & body weight, recent exercise analytics, PRs & progression charts |
| **Backup** | Export / import full local data as JSON |
| **Android** | Media key controls (prev / play-pause / next) during active workouts |

Workout data stays **on-device** (Hive). Firebase is used for authentication only (for now).

## Tech stack

| Layer | Choice |
|-------|--------|
| App | Flutter / Dart `^3.9.2` |
| State | Riverpod |
| Local DB | Hive |
| Auth | Firebase Auth |
| Charts | fl_chart |
| Calendar | table_calendar |

## Getting started

### Prerequisites

- [Flutter](https://docs.flutter.dev/get-started/install) (stable)
- Firebase CLI + FlutterFire CLI (for your own Firebase project)
- A device, emulator, or Chrome for web

### 1. Clone & dependencies

```bash
git clone https://github.com/ieozdogru/LarGer.git
cd LarGer
flutter pub get
```

### 2. Firebase setup

Firebase client config is **not** in the repo (public-repo safety). Create your own project, then:

```bash
# One-time tooling
npm install -g firebase-tools   # or: curl -sL https://firebase.tools | bash
dart pub global activate flutterfire_cli

firebase login
dart pub global run flutterfire_cli:flutterfire configure
```

Enable **Email/Password** under Firebase Console → Authentication → Sign-in method.

Place `google-services.json` at `android/app/` if FlutterFire did not already.

### 3. Run

```bash
flutter run                 # default device
flutter run -d chrome       # web
```

### Tests & analyze

```bash
flutter test --concurrency=1
flutter analyze lib test
```

CI runs analyze + tests on pull requests and pushes to `master`.

### Hive adapters

After changing models in `lib/models/models.dart`:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Project structure

```text
lib/
├── main.dart              # Firebase init + auth gate
├── models/                # Domain models + Hive adapters
├── providers/             # Riverpod (auth, routines, workouts, history, profile)
├── screens/               # Login, history, workout, profile, …
├── services/              # Backup, media keys, local clear, debug sample data
├── theme/
├── utils/
└── widgets/
```

## Data

Stored locally in Hive:

| Box | Contents |
|-----|----------|
| `exercises` | Seeded catalog by muscle group |
| `routines` | User routines |
| `sessions` | Completed workouts |
| `bodyWeightLogs` | Weight history |
| `settings` | e.g. height |

Sign-out clears user local data (sessions, routines, body stats) but keeps the exercise catalog. JSON backup is the way to move data between devices.

> **Debug tip:** In debug builds, empty session storage is seeded with sample workouts so History / Analytics have something to show. Release builds do not seed sample data.

## Platforms

Android, iOS, macOS, Linux, Windows, and web. In-workout media key controls are **Android-only**.

## Contributing

1. Fork and create a feature branch  
2. Keep Firebase config out of git (already gitignored)  
3. Run tests before opening a PR  

## License

Private project (`publish_to: 'none'`). Not published on pub.dev.
