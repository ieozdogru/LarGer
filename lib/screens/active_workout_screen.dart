import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:larger/models/models.dart';
import 'package:larger/providers/active_workout_provider.dart';
import 'package:larger/screens/exercise_selection_screen.dart';
import 'package:larger/providers/history_provider.dart';
import 'package:larger/screens/workout_summary_screen.dart';
import 'package:larger/services/media_controller.dart';
import 'dart:async';
import 'package:larger/utils/string_extensions.dart';

class ActiveWorkoutScreen extends ConsumerWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeWorkout = ref.watch(activeWorkoutProvider);
    if (activeWorkout == null) return const SizedBox();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(activeWorkout.routineName ?? 'ACTIVE WORKOUT'),
            StreamBuilder<int>(
              stream: Stream.periodic(const Duration(seconds: 1), (x) => x),
              builder: (context, snapshot) {
                final duration = DateTime.now().difference(
                  activeWorkout.startTime,
                );
                final formatted =
                    "${duration.inHours > 0 ? '${duration.inHours}:' : ''}${(duration.inMinutes % 60).toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}";
                return Text(
                  formatted,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                );
              },
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Discard Workout'),
                content: const Text(
                  'Are you sure you want to discard this workout? Your current progress will be lost.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Keep Lifting'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text(
                      'Discard Workout',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              ref.read(activeWorkoutProvider.notifier).cancelWorkout();
            }
          },
        ),
      ),
      body: ReorderableListView.builder(
        padding: const EdgeInsets.only(bottom: 160),
        itemCount: activeWorkout.exercises.length,
        onReorderItem: (oldIndex, newIndex) {
          ref
              .read(activeWorkoutProvider.notifier)
              .reorderExercises(oldIndex, newIndex);
        },
        proxyDecorator: (child, index, animation) {
          final exercise = activeWorkout.exercises[index];
          return Material(
            color: Colors.transparent,
            child: Card(
              color: Theme.of(context).cardColor,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 12,
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  exercise.exerciseName?.toTitleCase() ?? 'Unknown',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
          );
        },
        itemBuilder: (context, index) {
          final exercise = activeWorkout.exercises[index];
          return _ActiveExerciseCard(
            key: ValueKey(exercise.exerciseId ?? index.toString()),
            exercise: exercise,
            exerciseIndex: index,
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 120),
        child: FloatingActionButton.extended(
          backgroundColor: Theme.of(context).primaryColor,
          onPressed: () async {
            final Exercise? result = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ExerciseSelectionScreen(),
              ),
            );
            if (result != null) {
              ref.read(activeWorkoutProvider.notifier).addExercise(result);
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _MediaControlPanel(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Finish Workout'),
                      content: const Text(
                        'Are you sure you want to finish this workout?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text(
                            'Finish',
                            style: TextStyle(color: Colors.green),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirm != true) return;

                  final session = await ref
                      .read(activeWorkoutProvider.notifier)
                      .finishWorkout();
                  if (session != null && context.mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) =>
                            WorkoutSummaryScreen(session: session),
                      ),
                    );
                  }
                },
                child: const Text('FINISH WORKOUT'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaControlPanel extends StatefulWidget {
  const _MediaControlPanel();

  @override
  State<_MediaControlPanel> createState() => _MediaControlPanelState();
}

class _MediaControlPanelState extends State<_MediaControlPanel> {
  bool isPlaying = false;
  bool isHidden = true;
  StreamSubscription? sub;

  @override
  void initState() {
    super.initState();
    sub = MediaController.playbackStateStream.listen((playing) {
      if (!mounted) return;
      if (playing) {
        setState(() {
          isPlaying = true;
          isHidden = false;
        });
      } else {
        setState(() {
          isPlaying = false;
        });
      }
    });
  }

  @override
  void dispose() {
    sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isHidden) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.skip_previous, size: 24),
              onPressed: () => MediaController.previous(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
              iconSize: 28,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => MediaController.playPause(),
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.skip_next, size: 24),
              onPressed: () => MediaController.next(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    setState(() {
                      isHidden = true;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _ActiveExerciseCard extends ConsumerWidget {
  final WorkoutExercise exercise;
  final int exerciseIndex;

  const _ActiveExerciseCard({
    super.key,
    required this.exercise,
    required this.exerciseIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prevExercise = ref.watch(
      previousSessionProvider(exercise.exerciseId),
    );

    String ghostText = 'First time for this exercise!';
    if (prevExercise != null) {
      final setsStr = prevExercise.sets.map((s) => '${s.reps}').join(', ');
      final maxW = prevExercise.sets
          .map((s) => s.weight)
          .reduce((a, b) => a > b ? a : b);
      ghostText = 'Last time: $maxW kg x $setsStr';
    }

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
                    exercise.exerciseName ?? 'Unknown',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.grey),
                  onPressed: () => ref
                      .read(activeWorkoutProvider.notifier)
                      .removeExercise(exerciseIndex),
                ),
              ],
            ),
            Text(
              ghostText,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),
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
                SizedBox(width: 40), // For delete icon
              ],
            ),
            const SizedBox(height: 8),
            ...exercise.sets.asMap().entries.map((e) {
              final setIndex = e.key;
              final set = e.value;
              WorkoutSet? ghostSet;
              if (prevExercise != null && setIndex < prevExercise.sets.length) {
                ghostSet = prevExercise.sets[setIndex];
              }
              return _ActiveSetRow(
                key: ValueKey(set.id),
                exerciseIndex: exerciseIndex,
                setIndex: setIndex,
                workoutSet: set,
                ghostSet: ghostSet,
              );
            }),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => ref
                  .read(activeWorkoutProvider.notifier)
                  .addSet(exerciseIndex),
              icon: const Icon(Icons.add),
              label: const Text('Add Set'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveSetRow extends ConsumerStatefulWidget {
  final int exerciseIndex;
  final int setIndex;
  final WorkoutSet workoutSet;
  final WorkoutSet? ghostSet;

  const _ActiveSetRow({
    required this.exerciseIndex,
    required this.setIndex,
    required this.workoutSet,
    this.ghostSet,
  });

  @override
  ConsumerState<_ActiveSetRow> createState() => _ActiveSetRowState();
}

class _ActiveSetRowState extends ConsumerState<_ActiveSetRow> {
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
        ref
            .read(activeWorkoutProvider.notifier)
            .updateSet(
              widget.exerciseIndex,
              widget.setIndex,
              weight: double.tryParse(_weightController.text) ?? 0.0,
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
        ref
            .read(activeWorkoutProvider.notifier)
            .updateSet(
              widget.exerciseIndex,
              widget.setIndex,
              reps: int.tryParse(_repsController.text) ?? 0,
            );
      }
    });
  }

  @override
  void didUpdateWidget(_ActiveSetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_weightFocus.hasFocus &&
        oldWidget.workoutSet.weight != widget.workoutSet.weight) {
      _weightController.text = widget.workoutSet.weight == 0
          ? ''
          : widget.workoutSet.weight.toString();
    }
    if (!_repsFocus.hasFocus &&
        oldWidget.workoutSet.reps != widget.workoutSet.reps) {
      _repsController.text = widget.workoutSet.reps == 0
          ? ''
          : widget.workoutSet.reps.toString();
    }
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
                decoration: InputDecoration(
                  hintText: widget.ghostSet != null
                      ? '${widget.ghostSet!.weight}'
                      : '0',
                ),
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
                decoration: InputDecoration(
                  hintText: widget.ghostSet != null
                      ? '${widget.ghostSet!.reps}'
                      : '0',
                ),
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
                double weight = double.tryParse(_weightController.text) ?? 0.0;
                int reps = int.tryParse(_repsController.text) ?? 0;

                if (!widget.workoutSet.isCompleted &&
                    weight == 0.0 &&
                    reps == 0 &&
                    widget.ghostSet != null) {
                  weight = widget.ghostSet!.weight;
                  reps = widget.ghostSet!.reps;
                  _weightController.text = weight.toString();
                  _repsController.text = reps.toString();
                }

                ref
                    .read(activeWorkoutProvider.notifier)
                    .updateSet(
                      widget.exerciseIndex,
                      widget.setIndex,
                      weight: weight,
                      reps: reps,
                      isCompleted: !widget.workoutSet.isCompleted,
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
              onPressed: () {
                ref
                    .read(activeWorkoutProvider.notifier)
                    .removeSet(widget.exerciseIndex, widget.setIndex);
              },
            ),
          ),
        ],
      ),
    );
  }
}
