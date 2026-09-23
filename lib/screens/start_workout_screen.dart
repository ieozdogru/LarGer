import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:larger/providers/routine_provider.dart';
import 'package:larger/models/models.dart';
import 'package:larger/screens/exercise_selection_screen.dart';
import 'package:larger/utils/workout_start.dart';

class StartWorkoutScreen extends ConsumerWidget {
  const StartWorkoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routinesState = ref.watch(routineNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('WORKOUT')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () => startEmptyWorkout(ref, context),
              child: const Text('START EMPTY WORKOUT'),
            ),
            const SizedBox(height: 32),
            Text(
              'ROUTINES',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: routinesState.when(
                data: (routines) {
                  if (routines.isEmpty) {
                    return const Center(
                      child: Text(
                        'No routines yet. Create one to get started.',
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: routines.length,
                    itemBuilder: (context, index) {
                      final routine = routines[index];
                      return Card(
                        child: ListTile(
                          title: Text(routine.name),
                          subtitle: Text(
                            '${routine.exercises.length} exercises',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.play_arrow,
                                  color: Colors.green,
                                ),
                                onPressed: () =>
                                    _startRoutine(context, ref, routine),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          _CreateRoutineScreen(
                                            editingRoutine: routine,
                                          ),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  _confirmDelete(context, ref, routine);
                                },
                              ),
                            ],
                          ),
                          onTap: () => _startRoutine(context, ref, routine),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const _CreateRoutineScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _startRoutine(
    BuildContext context,
    WidgetRef ref,
    Routine routine,
  ) => startRoutineWorkout(ref, context, routine);

  void _confirmDelete(BuildContext context, WidgetRef ref, Routine routine) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this routine?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                ref
                    .read(routineNotifierProvider.notifier)
                    .deleteRoutine(routine.id);
                Navigator.of(ctx).pop();
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}

class _CreateRoutineScreen extends ConsumerStatefulWidget {
  final Routine? editingRoutine;
  const _CreateRoutineScreen({this.editingRoutine});

  @override
  ConsumerState<_CreateRoutineScreen> createState() =>
      _CreateRoutineScreenState();
}

class _CreateRoutineScreenState extends ConsumerState<_CreateRoutineScreen> {
  final nameController = TextEditingController();
  List<Exercise> selectedExercises = [];
  Map<String, int> targetSets = {};

  @override
  void initState() {
    super.initState();
    if (widget.editingRoutine != null) {
      nameController.text = widget.editingRoutine!.name;
      _loadEditingRoutineData();
    }
  }

  void _loadEditingRoutineData() {
    final box = Hive.box<Exercise>('exercises');
    for (var re in widget.editingRoutine!.exercises) {
      final ex = box.values.firstWhere(
        (e) => e.id == re.exerciseId,
        orElse: () =>
            Exercise(id: re.exerciseId, name: 'Unknown', category: 'Unknown'),
      );
      if (ex.name != 'Unknown') {
        selectedExercises.add(ex);
        targetSets[ex.id] = re.targetSets;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.editingRoutine == null ? 'New Routine' : 'Edit Routine',
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  selectedExercises.isNotEmpty) {
                final routineExercises = selectedExercises.map((e) {
                  return RoutineExercise(
                    exerciseId: e.id,
                    targetSets: targetSets[e.id] ?? 3,
                  );
                }).toList();

                if (widget.editingRoutine == null) {
                  ref
                      .read(routineNotifierProvider.notifier)
                      .createRoutine(nameController.text, routineExercises);
                } else {
                  ref
                      .read(routineNotifierProvider.notifier)
                      .updateRoutine(
                        widget.editingRoutine!.id,
                        nameController.text,
                        routineExercises,
                      );
                }
                Navigator.of(context).pop();
              }
            },
            child: const Text(
              'SAVE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Routine Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final List<Exercise>? result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        const ExerciseSelectionScreen(multiple: true),
                  ),
                );
                if (result != null) {
                  setState(() {
                    for (var ex in result) {
                      if (!selectedExercises.any((e) => e.id == ex.id)) {
                        selectedExercises.add(ex);
                        targetSets[ex.id] = 3; // Default sets
                      }
                    }
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add Exercises'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ReorderableListView.builder(
                buildDefaultDragHandles: false,
                itemCount: selectedExercises.length,
                onReorderItem: (oldIndex, newIndex) {
                  setState(() {
                    final item = selectedExercises.removeAt(oldIndex);
                    selectedExercises.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, index) {
                  final ex = selectedExercises[index];
                  final sets = targetSets[ex.id] ?? 3;

                  return Card(
                    key: ValueKey(ex.id),
                    child: ListTile(
                      leading: ReorderableDragStartListener(
                        index: index,
                        child: const Icon(Icons.drag_handle),
                      ),
                      title: Text(ex.name),
                      subtitle: Row(
                        children: [
                          const Text('Target Sets: '),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () {
                              if (sets > 1) {
                                setState(() {
                                  targetSets[ex.id] = sets - 1;
                                });
                              }
                            },
                          ),
                          Text(
                            '$sets',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () {
                              setState(() {
                                targetSets[ex.id] = sets + 1;
                              });
                            },
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () {
                          setState(() {
                            selectedExercises.removeAt(index);
                            targetSets.remove(ex.id);
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
