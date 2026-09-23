import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:larger/providers/calorie_target_provider.dart';
import 'package:larger/providers/food_provider.dart';
import 'package:larger/providers/today_provider.dart';
import 'package:larger/services/calorie_intake.dart';
import 'package:larger/widgets/complication_ring.dart';
import 'package:larger/widgets/expanding_play_start.dart';
import 'package:larger/widgets/page_gradient.dart';
import 'package:larger/widgets/profile_button.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _enter.value = 1;
      } else {
        _enter.forward();
      }
    });
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  Widget _rise(Widget child, double start, double end) {
    final curved = CurvedAnimation(
      parent: _enter,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.12),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final suggestionAsync = ref.watch(todaySuggestionProvider);
    final lastSessionAsync = ref.watch(lastCompletedSessionProvider);
    final totals = ref.watch(
      foodDayTotalsProvider(normalizeFoodDay(DateTime.now())),
    );
    final target = ref.watch(calorieTargetProvider);
    final profile = ref.watch(calorieProfileProvider);
    final todayLabel = DateFormat('EEEE, MMM d').format(DateTime.now());

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: PageGradient()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _rise(
                    Row(
                      children: [
                        const ProfileButton(heroTag: 'profile-today'),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'LarGer',
                                style: Theme.of(context).textTheme.headlineLarge
                                    ?.copyWith(
                                      fontSize: 32,
                                      letterSpacing: 1.1,
                                    ),
                              ),
                              Text(
                                todayLabel,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    0,
                    0.45,
                  ),
                  const SizedBox(height: 20),
                  _rise(
                    totals.when(
                      data: (day) => target.when(
                        data: (view) {
                          final resolution = view.resolution;
                          if (resolution == null) {
                            return const Text(
                              'Set your daily calories to see today as a percent.',
                              style: TextStyle(color: Colors.white70),
                            );
                          }
                          final calorieTarget = resolution.targetKcal.round();
                          return DailyComplications(
                            caloriesEaten: day.calories.round(),
                            calorieTarget: calorieTarget,
                            proteinEaten: day.proteinG.round(),
                            proteinGoal: resolvedGramGoal(
                              stored: profile.proteinGoalG,
                              fallback: defaultProteinGoalG(
                                calorieTarget.toDouble(),
                              ),
                            ),
                            carbsEaten: day.carbsG.round(),
                            carbGoal: resolvedGramGoal(
                              stored: profile.carbGoalG,
                              fallback: defaultCarbGoalG(
                                calorieTarget.toDouble(),
                              ),
                            ),
                          );
                        },
                        loading: () => const LinearProgressIndicator(),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                    0.15,
                    0.6,
                  ),
                  const SizedBox(height: 28),
                  _rise(
                    suggestionAsync.when(
                      data: (suggestion) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            suggestion.title,
                            style: Theme.of(context).textTheme.headlineLarge
                                ?.copyWith(
                                  fontSize: 32,
                                  height: 1.15,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          if (suggestion.subtitle != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              suggestion.subtitle!,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: Colors.white70,
                                    height: 1.35,
                                  ),
                            ),
                          ],
                        ],
                      ),
                      loading: () => const SizedBox(
                        height: 48,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (_, _) => Text(
                        'Ready when you are',
                        style: Theme.of(
                          context,
                        ).textTheme.headlineLarge?.copyWith(fontSize: 32),
                      ),
                    ),
                    0.3,
                    0.75,
                  ),
                  const SizedBox(height: 12),
                  _rise(
                    lastSessionAsync.when(
                      data: (session) {
                        if (session == null) {
                          return const Text(
                            'No sessions yet — press play to begin.',
                            style: TextStyle(color: Colors.white54),
                          );
                        }
                        final when = DateFormat(
                          'MMM d',
                        ).format(session.startTime);
                        final name = session.routineName ?? 'Empty workout';
                        return Text(
                          'Last session · $name · $when',
                          style: const TextStyle(color: Colors.white54),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                    0.4,
                    0.85,
                  ),
                  const Spacer(),
                  Expanded(child: _rise(const ExpandingPlayStart(), 0.55, 1)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
