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
  <img alt="License" src="https://img.shields.io/badge/license-private-lightgrey" />
</p>

---

## Features

| Area | What you get |
|------|----------------|
| **Workout** | Start empty or from a routine; live timer; log reps/weight; reorder exercises |
| **Routines** | Create, edit, and delete routines with target set counts (same tab as Workout) |
| **History** | Calendar of past sessions; edit or delete workouts |
| **Profile** | Height & body weight, recent exercise analytics, PRs & progression charts |
| **Backup** | Export / import full local data as JSON |
| **Android** | Media key controls (prev / play-pause / next) during active workouts |

Workout data stays **on-device** (Hive).

## Tech stack

| Layer | Choice |
|-------|--------|
| App | Flutter / Dart `^3.9.2` |
| State | Riverpod |
| Local DB | Hive |
| Charts | fl_chart |
| Calendar | table_calendar |

## Getting started

### Prerequisites

- [Flutter](https://docs.flutter.dev/get-started/install) (stable)
- A device, emulator, or Chrome for web

### 1. Clone & dependencies

```bash
git clone https://github.com/ieozdogru/LarGer.git
cd LarGer
flutter pub get
```

### 2. Run

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
├── main.dart              # Hive init + app shell
├── models/                # Domain models + Hive adapters
├── providers/             # Riverpod (routines, workouts, history, profile)
├── screens/               # History, today, food, profile, …
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

JSON backup is the way to move data between devices. The exercise catalog stays on the device independently of workout history.

> **Debug tip:** In debug builds, empty session storage is seeded with sample workouts so History / Analytics have something to show. Release builds do not seed sample data.

## Platforms

Android, iOS, macOS, Linux, Windows, and web. In-workout media key controls are **Android-only**.

## Contributing

1. Fork and create a feature branch  
2. Run tests before opening a PR  

## License

Private project (`publish_to: 'none'`). Not published on pub.dev.
