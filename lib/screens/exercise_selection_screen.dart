import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:larger/models/models.dart';
import 'package:larger/providers/exercise_provider.dart';
import 'package:larger/utils/string_extensions.dart';

class ExerciseSelectionScreen extends ConsumerStatefulWidget {
  final bool multiple;
  const ExerciseSelectionScreen({super.key, this.multiple = false});

  @override
  ConsumerState<ExerciseSelectionScreen> createState() =>
      _ExerciseSelectionScreenState();
}

class _ExerciseSelectionScreenState
    extends ConsumerState<ExerciseSelectionScreen> {
  String searchQuery = '';
  List<Exercise> selectedExercises = [];

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(exercisesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SELECT EXERCISE'),
        actions: [
          if (widget.multiple)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                Navigator.of(context).pop(selectedExercises);
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (val) {
                setState(() {
                  searchQuery = val.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: exercisesAsync.when(
              data: (exercises) {
                final filtered = exercises
                    .where((e) => e.name.toLowerCase().contains(searchQuery))
                    .toList();
                if (filtered.isEmpty) {
                  return const Center(child: Text('No exercises found.'));
                }
                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final ex = filtered[index];
                    final isSelected = selectedExercises.contains(ex);
                    return ListTile(
                      title: Text(ex.name.toTitleCase()),
                      subtitle: Text(ex.category),
                      trailing: widget.multiple
                          ? (isSelected
                                ? const Icon(Icons.check_box, color: Colors.red)
                                : const Icon(Icons.check_box_outline_blank))
                          : null,
                      onTap: () {
                        if (widget.multiple) {
                          setState(() {
                            if (isSelected) {
                              selectedExercises.remove(ex);
                            } else {
                              selectedExercises.add(ex);
                            }
                          });
                        } else {
                          Navigator.of(context).pop(ex);
                        }
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
