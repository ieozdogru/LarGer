import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:larger/models/models.dart';
import 'package:larger/providers/routine_provider.dart';
import 'package:larger/screens/start_workout_screen.dart';
import 'package:larger/theme/app_theme.dart';
import 'package:larger/utils/workout_start.dart';

class ExpandingPlayStart extends ConsumerStatefulWidget {
  const ExpandingPlayStart({super.key});

  @override
  ConsumerState<ExpandingPlayStart> createState() => _ExpandingPlayStartState();
}

class _ExpandingPlayStartState extends ConsumerState<ExpandingPlayStart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _menuFade;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _scale = Tween<double>(begin: 1, end: 1.12).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _menuFade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_expanded) {
      await _controller.reverse();
      if (mounted) setState(() => _expanded = false);
    } else {
      setState(() => _expanded = true);
      await _controller.forward();
    }
  }

  Future<void> _collapse() async {
    if (!_expanded) return;
    await _controller.reverse();
    if (mounted) setState(() => _expanded = false);
  }

  Future<void> _runAndClose(Future<void> Function() action) async {
    await _collapse();
    await action();
  }

  @override
  Widget build(BuildContext context) {
    final routinesAsync = ref.watch(routineNotifierProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            if (_expanded)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _collapse,
                  behavior: HitTestBehavior.opaque,
                  child: FadeTransition(
                    opacity: _menuFade,
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.55),
                    ),
                  ),
                ),
              ),
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_expanded)
                  Flexible(
                    child: FadeTransition(
                      opacity: _menuFade,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Material(
                            color: AppTheme.surfaceColor,
                            borderRadius: BorderRadius.circular(20),
                            elevation: 8,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: 320,
                                maxHeight: (constraints.maxHeight - 104)
                                    .clamp(120.0, constraints.maxHeight),
                              ),
                              child: routinesAsync.when(
                                data: (routines) => _PlayMenu(
                                  routines: routines,
                                  onStartEmpty: () => _runAndClose(
                                    () => startEmptyWorkout(ref),
                                  ),
                                  onStartRoutine: (routine) => _runAndClose(
                                    () => startRoutineWorkout(ref, routine),
                                  ),
                                  onManage: () => _runAndClose(() async {
                                    if (!context.mounted) return;
                                    await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const StartWorkoutScreen(),
                                      ),
                                    );
                                  }),
                                ),
                                loading: () => const Padding(
                                  padding: EdgeInsets.all(24),
                                  child: CircularProgressIndicator(),
                                ),
                                error: (_, _) => const Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Text('Could not load routines'),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ScaleTransition(
                  scale: _scale,
                  child: GestureDetector(
                    onTap: _toggle,
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.accentRed,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accentRed.withValues(alpha: 0.45),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        _expanded ? Icons.close : Icons.play_arrow_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _PlayMenu extends StatelessWidget {
  final List<Routine> routines;
  final VoidCallback onStartEmpty;
  final ValueChanged<Routine> onStartRoutine;
  final VoidCallback onManage;

  const _PlayMenu({
    required this.routines,
    required this.onStartEmpty,
    required this.onStartRoutine,
    required this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(
              Icons.fitness_center,
              color: AppTheme.accentRed,
            ),
            title: const Text('Start empty workout'),
            onTap: onStartEmpty,
          ),
          if (routines.isNotEmpty) ...[
            const Divider(height: 1),
            ...routines.map(
              (routine) => ListTile(
                leading: const Icon(Icons.play_circle_outline),
                title: Text(routine.name),
                subtitle: Text('${routine.exercises.length} exercises'),
                onTap: () => onStartRoutine(routine),
              ),
            ),
          ],
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.list_alt),
            title: Text(
              routines.isEmpty ? 'Create / manage routines' : 'Manage routines',
            ),
            onTap: onManage,
          ),
        ],
      ),
    );
  }
}
