# LarGer

Local-first gym workout tracker built with Flutter. Build routines, log sets during active sessions, review history on a calendar, track body weight and personal records, and back up everything as JSON — all stored on device with Hive.

## Features

- **Routines** — Create, edit, and delete routines with exercises and target set counts
- **Active workouts** — Start empty or from a routine; live timer; log reps, weight, and completed sets; reorder exercises; previous-session values while logging
- **Workout summary** — Total volume, notes, and weight/volume PR highlights
- **History** — Calendar view of sessions; edit or delete past workouts
- **Profile** — Height and body-weight logging; exercise analytics with all-time PRs and progression charts
- **Backup** — Export/import full app data as JSON (import overwrites existing data)
- **Android media controls** — Previous / play-pause / next during workouts via system media keys

## Tech stack

| Layer | Choice |
|-------|--------|
| Framework | Flutter (Dart `^3.9.2`) |
| State | Riverpod |
| Storage | Hive (local) |
| Charts | fl_chart |
| Calendar | table_calendar |

## Getting started

### Prerequisites

- [Flutter](https://docs.flutter.dev/get-started/install) (stable; project metadata targets ~3.35.x)
- A device or emulator for your target platform

### Run

```bash
flutter pub get
flutter run
```

### Regenerate Hive adapters

After changing models in `lib/models/models.dart`:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Project structure

```
lib/
├── main.dart
├── models/          # Domain models + Hive adapters
├── providers/       # Riverpod state (Hive, exercises, routines, workouts, history, profile)
├── screens/         # History, workout, routines, profile, and related flows
├── services/        # Backup + Android media controller
├── theme/           # App theme
├── utils/
└── widgets/
```

## Data

All data is stored locally in Hive boxes:

- `exercises` — seeded catalog by muscle group (searchable)
- `routines`
- `sessions`
- `bodyWeightLogs`
- `settings` (e.g. height)

There is no backend or authentication. Backup export/import is the supported way to move data between devices.

## Platforms

Flutter targets include Android, iOS, macOS, Linux, Windows, and web. In-workout media key controls are implemented for Android only.

## License

Private project (`publish_to: 'none'`). Not published on pub.dev.
