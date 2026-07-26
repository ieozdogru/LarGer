import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:larger/providers/today_provider.dart';
import 'package:larger/theme/app_theme.dart';
import 'package:larger/widgets/expanding_play_start.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestionAsync = ref.watch(todaySuggestionProvider);
    final lastSessionAsync = ref.watch(lastCompletedSessionProvider);
    final todayLabel = DateFormat('EEEE, MMM d').format(DateTime.now());

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.accentRed.withValues(alpha: 0.18),
                    AppTheme.primaryBackground,
                    AppTheme.primaryBackground,
                  ],
                  stops: const [0, 0.45, 1],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'LarGer',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontSize: 42,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'TODAY · $todayLabel',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(flex: 2),
                  suggestionAsync.when(
                    data: (suggestion) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          suggestion.title,
                          style: Theme.of(context).textTheme.headlineLarge
                              ?.copyWith(
                                fontSize: 36,
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
                      height: 80,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (_, _) => Text(
                      'Ready when you are',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontSize: 36,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
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
                  const Spacer(flex: 3),
                  const Expanded(
                    flex: 5,
                    child: ExpandingPlayStart(),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
