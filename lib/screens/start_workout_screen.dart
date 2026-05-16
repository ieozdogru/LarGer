import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:larger/providers/active_workout_provider.dart';
import 'package:larger/providers/routine_provider.dart';
import 'package:larger/providers/exercise_provider.dart';
import 'package:larger/models/models.dart';

class StartWorkoutScreen extends ConsumerWidget {
  const StartWorkoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routinesState = ref.watch(routineNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('START WORKOUT')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () {
                ref.read(activeWorkoutProvider.notifier).startWorkout();
              },
              child: const Text('START EMPTY WORKOUT'),
            ),
            const SizedBox(height: 32),
            Text(
              'OR CHOOSE A ROUTINE',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: routinesState.when(
                data: (routines) {
                  if (routines.isEmpty) {
                    return const Center(child: Text('No routines saved yet.'));
                  }
                  return ListView.builder(
                    itemCount: routines.length,
                    itemBuilder: (context, index) {
                      final routine = routines[index];
                      return Card(
                        child: ListTile(
                          title: Text(routine.name),
                          trailing: const Icon(
                            Icons.play_arrow,
                            color: Colors.green,
                          ),
                          onTap: () async {
                            final allExercises = await ref.read(
                              exercisesProvider.future,
                            );

                            final preparedExercises = routine.exercises.map((
                              re,
                            ) {
                              final ex = allExercises.firstWhere(
                                (e) => e.id == re.exerciseId,
                                orElse: () =>
                                    Exercise(name: 'Unknown', category: ''),
                              );
                              return WorkoutExercise()
                                ..exerciseId = ex.id
                                ..exerciseName = ex.name
                                ..sets = List.generate(
                                  re.targetSets,
                                  (_) => WorkoutSet(),
                                );
                            }).toList();

                            ref
                                .read(activeWorkoutProvider.notifier)
                                .startWorkout(
                                  routineName: routine.name,
                                  preparedExercises: preparedExercises,
                                );
                          },
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) =>
                    const Center(child: Text('Error loading routines')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
