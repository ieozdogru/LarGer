import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:larger/models/models.dart';
import 'package:larger/providers/history_provider.dart';
import 'package:larger/utils/string_extensions.dart';
import 'package:larger/screens/exercise_selection_screen.dart';

class EditWorkoutScreen extends ConsumerStatefulWidget {
  final WorkoutSession session;

  const EditWorkoutScreen({super.key, required this.session});

  @override
  ConsumerState<EditWorkoutScreen> createState() => _EditWorkoutScreenState();
}

class _EditWorkoutScreenState extends ConsumerState<EditWorkoutScreen> {
  late WorkoutSession _editableSession;
  late TextEditingController _sessionNotesController;

  @override
  void initState() {
    super.initState();
    // Deep copy session
    _editableSession = WorkoutSession(id: widget.session.id)
      ..routineName = widget.session.routineName
      ..startTime = widget.session.startTime
      ..endTime = widget.session.endTime
      ..totalVolume = widget.session.totalVolume
      ..isCompleted = widget.session.isCompleted
      ..notes = widget.session.notes
      ..exercises = widget.session.exercises.map((ex) {
        return WorkoutExercise()
          ..exerciseId = ex.exerciseId
          ..exerciseName = ex.exerciseName
          ..notes = ex.notes
          ..sets = ex.sets
              .map(
                (s) => WorkoutSet()
                  ..reps = s.reps
                  ..weight = s.weight
                  ..isCompleted = s.isCompleted,
              )
              .toList();
      }).toList();

    _sessionNotesController = TextEditingController(
      text: _editableSession.notes,
    );
  }

  @override
  void dispose() {
    _sessionNotesController.dispose();
    super.dispose();
  }

  void _saveUpdates() async {
    // Unfocus any active text field so its state gets updated before saving
    FocusScope.of(context).unfocus();

    // Minor delay to ensure focus listener updates complete
    await Future.delayed(const Duration(milliseconds: 50));

    double totalVolume = 0.0;
    for (var ex in _editableSession.exercises) {
      for (var s in ex.sets) {
        if (s.isCompleted) {
          totalVolume += (s.reps * s.weight);
        }
      }
    }
    _editableSession.totalVolume = totalVolume;
    _editableSession.notes = _sessionNotesController.text;

    final box = Hive.box<WorkoutSession>('sessions');
    await box.put(_editableSession.id, _editableSession);
    ref.invalidate(historyProvider);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _deleteWorkout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Workout'),
        content: const Text(
          'Are you sure you want to delete this workout from history?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final box = Hive.box<WorkoutSession>('sessions');
              await box.delete(_editableSession.id);
              ref.invalidate(historyProvider);
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () async {
            // Edit duration
            final duration = _editableSession.endTime != null
                ? _editableSession.endTime!.difference(
                    _editableSession.startTime,
                  )
                : const Duration(hours: 1);
            int newMinutes = duration.inMinutes;
            final controller = TextEditingController(
              text: newMinutes.toString(),
            );
            final result = await showDialog<String>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Edit Duration (minutes)'),
                content: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, controller.text),
                    child: const Text('Save'),
                  ),
                ],
              ),
            );
            if (result != null) {
              final mins = int.tryParse(result);
              if (mins != null) {
                setState(() {
                  _editableSession.endTime = _editableSession.startTime.add(
                    Duration(minutes: mins),
                  );
                });
              }
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Edit Past Workout'),
              Text(
                'Duration: ${_editableSession.endTime != null ? _editableSession.endTime!.difference(_editableSession.startTime).inMinutes : 0} mins (Tap to edit)',
                style: const TextStyle(fontSize: 12, color: Colors.amber),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saveUpdates,
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
      body: ListView.builder(
        padding: const EdgeInsets.only(bottom: 100),
        itemCount: _editableSession.exercises.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Session Notes',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _sessionNotesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Add general notes about this session...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          final exerciseIndex = index - 1;
          final exercise = _editableSession.exercises[exerciseIndex];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          exercise.exerciseName?.toTitleCase() ?? 'Unknown',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.grey),
                        onPressed: () {
                          setState(() {
                            _editableSession.exercises.removeAt(exerciseIndex);
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: exercise.notes,
                    decoration: const InputDecoration(
                      hintText: 'Exercise notes (optional)',
                      isDense: true,
                    ),
                    onChanged: (val) {
                      exercise.notes = val;
                    },
                  ),
                  const Divider(),
                  const Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: Text(
                          'SET',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'KG',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'REPS',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(width: 40, child: Icon(Icons.check)),
                      SizedBox(width: 40),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...exercise.sets.asMap().entries.map((e) {
                    final setIndex = e.key;
                    final set = e.value;
                    return _EditSetRow(
                      setIndex: setIndex,
                      workoutSet: set,
                      onUpdate: (weight, reps, isCompleted) {
                        setState(() {
                          set.weight = weight ?? set.weight;
                          set.reps = reps ?? set.reps;
                          set.isCompleted = isCompleted ?? set.isCompleted;
                        });
                      },
                      onRemove: () {
                        setState(() {
                          exercise.sets.removeAt(setIndex);
                        });
                      },
                    );
                  }),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        final lastSet = exercise.sets.isNotEmpty
                            ? exercise.sets.last
                            : null;
                        exercise.sets.add(
                          WorkoutSet()
                            ..reps = lastSet?.reps ?? 0
                            ..weight = lastSet?.weight ?? 0.0,
                        );
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Set'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 60),
        child: FloatingActionButton.extended(
          backgroundColor: Theme.of(context).primaryColor,
          onPressed: () async {
            final Exercise? result = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ExerciseSelectionScreen(),
              ),
            );
            if (result != null) {
              setState(() {
                _editableSession.exercises.add(
                  WorkoutExercise()
                    ..exerciseId = result.id
                    ..exerciseName = result.name
                    ..sets = [WorkoutSet()],
                );
              });
            }
          },
          label: const Text('Add Exercise'),
          icon: const Icon(Icons.add),
        ),
      ),
      bottomSheet: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          icon: const Icon(Icons.delete, color: Colors.white),
          label: const Text(
            'Delete Workout',
            style: TextStyle(color: Colors.white),
          ),
          onPressed: _deleteWorkout,
        ),
      ),
    );
  }
}

class _EditSetRow extends StatefulWidget {
  final int setIndex;
  final WorkoutSet workoutSet;
  final void Function(double? weight, int? reps, bool? isCompleted) onUpdate;
  final VoidCallback? onRemove;

  const _EditSetRow({
    required this.setIndex,
    required this.workoutSet,
    required this.onUpdate,
    this.onRemove,
  });

  @override
  State<_EditSetRow> createState() => _EditSetRowState();
}

class _EditSetRowState extends State<_EditSetRow> {
  late TextEditingController _weightController;
  late TextEditingController _repsController;
  late FocusNode _weightFocus;
  late FocusNode _repsFocus;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: widget.workoutSet.weight == 0
          ? ''
          : widget.workoutSet.weight.toString(),
    );
    _repsController = TextEditingController(
      text: widget.workoutSet.reps == 0
          ? ''
          : widget.workoutSet.reps.toString(),
    );
    _weightFocus = FocusNode();
    _repsFocus = FocusNode();

    _weightFocus.addListener(() {
      if (_weightFocus.hasFocus) {
        _weightController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _weightController.text.length,
        );
      } else {
        widget.onUpdate(
          double.tryParse(_weightController.text) ?? 0.0,
          null,
          null,
        );
      }
    });

    _repsFocus.addListener(() {
      if (_repsFocus.hasFocus) {
        _repsController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _repsController.text.length,
        );
      } else {
        widget.onUpdate(null, int.tryParse(_repsController.text) ?? 0, null);
      }
    });
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    _weightFocus.dispose();
    _repsFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text('${widget.setIndex + 1}', textAlign: TextAlign.center),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TextFormField(
                controller: _weightController,
                focusNode: _weightFocus,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(hintText: '0'),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TextFormField(
                controller: _repsController,
                focusNode: _repsFocus,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(hintText: '0'),
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: IconButton(
              icon: Icon(
                widget.workoutSet.isCompleted
                    ? Icons.check_box
                    : Icons.check_box_outline_blank,
                color: widget.workoutSet.isCompleted
                    ? Colors.green
                    : Colors.grey,
              ),
              onPressed: () {
                widget.onUpdate(
                  double.tryParse(_weightController.text),
                  int.tryParse(_repsController.text),
                  !widget.workoutSet.isCompleted,
                );
              },
            ),
          ),
          SizedBox(
            width: 40,
            child: IconButton(
              icon: const Icon(
                Icons.remove_circle,
                color: Colors.redAccent,
                size: 20,
              ),
              onPressed: () => widget.onRemove?.call(),
            ),
          ),
        ],
      ),
    );
  }
}
