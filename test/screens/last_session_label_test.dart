import 'package:flutter_test/flutter_test.dart';
import 'package:larger/models/models.dart';
import 'package:larger/screens/active_workout_screen.dart';

void main() {
  test('last session line keeps each set weight', () {
    final exercise = WorkoutExercise()
      ..sets = [
        WorkoutSet()
          ..reps = 5
          ..weight = 100,
        WorkoutSet()
          ..reps = 8
          ..weight = 80,
      ];

    expect(formatLastSession(exercise), 'Last time: 100 kg × 5, 80 kg × 8');
  });
}
