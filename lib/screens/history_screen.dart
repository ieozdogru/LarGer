import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:larger/models/models.dart';
import 'package:larger/providers/history_provider.dart';
import 'package:larger/theme/app_theme.dart';
import 'package:larger/widgets/bounce_button.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:larger/screens/edit_workout_screen.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsyncValue = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('HISTORY')),
      body: historyAsyncValue.when(
        data: (sessions) {
          final Map<DateTime, WorkoutSession> workoutMap = {};
          for (var s in sessions) {
            final date = DateTime(
              s.startTime.year,
              s.startTime.month,
              s.startTime.day,
            );
            if (!workoutMap.containsKey(date)) {
              workoutMap[date] = s;
            }
          }

          return Column(
            children: [
              TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: DateTime.now(),
                startingDayOfWeek: StartingDayOfWeek.monday,
                rowHeight: 60,
                calendarFormat: CalendarFormat.twoWeeks,
                availableCalendarFormats: const {
                  CalendarFormat.twoWeeks: '2 weeks',
                },
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle: TextStyle(color: Colors.grey),
                  weekendStyle: TextStyle(color: Colors.grey),
                ),
                calendarStyle: const CalendarStyle(
                  defaultTextStyle: TextStyle(color: Colors.white),
                  weekendTextStyle: TextStyle(color: Colors.white70),
                  outsideTextStyle: TextStyle(color: Colors.grey),
                ),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    final normalizedDay = DateTime(
                      day.year,
                      day.month,
                      day.day,
                    );
                    return _buildDayCell(
                      day,
                      workoutMap[normalizedDay],
                      isToday: false,
                    );
                  },
                  todayBuilder: (context, day, focusedDay) {
                    final normalizedDay = DateTime(
                      day.year,
                      day.month,
                      day.day,
                    );
                    return _buildDayCell(
                      day,
                      workoutMap[normalizedDay],
                      isToday: true,
                    );
                  },
                  outsideBuilder: (context, day, focusedDay) {
                    final normalizedDay = DateTime(
                      day.year,
                      day.month,
                      day.day,
                    );
                    return Opacity(
                      opacity: 0.5,
                      child: _buildDayCell(
                        day,
                        workoutMap[normalizedDay],
                        isToday: false,
                      ),
                    );
                  },
                ),
              ),
              const Divider(),
              Expanded(
                child: sessions.isEmpty
                    ? const Center(child: Text('No workouts yet. Go lift!'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: sessions.length,
                        itemBuilder: (context, index) {
                          final session = sessions[index];
                          return Dismissible(
                            key: ValueKey(session.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            onDismissed: (_) {
                              deleteSession(ref, session.id);
                            },
                            child: _WorkoutSummaryCard(session: session),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _WorkoutSummaryCard extends StatelessWidget {
  final WorkoutSession session;

  const _WorkoutSummaryCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy - h:mm a');
    final duration = session.endTime != null
        ? session.endTime!.difference(session.startTime).inMinutes
        : 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: BounceButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => _WorkoutDetailScreen(session: session),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: 'title-${session.id}',
                child: Material(
                  color: Colors.transparent,
                  child: Text(
                    session.routineName ?? 'Empty Workout',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: AppTheme.accentRed),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                dateFormat.format(session.startTime),
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _InfoBadge(
                    label: 'Volume',
                    value: '${session.totalVolume} kg',
                  ),
                  _InfoBadge(label: 'Duration', value: '$duration min'),
                  _InfoBadge(
                    label: 'Exercises',
                    value: '${session.exercises.length}',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final String label;
  final String value;
  const _InfoBadge({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _WorkoutDetailScreen extends StatelessWidget {
  final WorkoutSession session;
  const _WorkoutDetailScreen({required this.session});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Hero(
          tag: 'title-${session.id}',
          child: Material(
            color: Colors.transparent,
            child: Text(
              session.routineName ?? 'Workout Details',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.white),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => EditWorkoutScreen(session: session),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: session.exercises.length,
        itemBuilder: (context, index) {
          final exercise = session.exercises[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.exerciseName ?? 'Unknown',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(),
                  ...exercise.sets.asMap().entries.map((e) {
                    final setIndex = e.key;
                    final set = e.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Set ${setIndex + 1}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${set.reps} reps x ${set.weight} kg',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          Icon(
                            set.isCompleted
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color: set.isCompleted ? Colors.green : Colors.grey,
                            size: 20,
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

Widget _buildDayCell(
  DateTime day,
  WorkoutSession? session, {
  required bool isToday,
}) {
  return Container(
    alignment: Alignment.center,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: session != null
                ? AppTheme.accentRed
                : (isToday ? Colors.grey[800] : Colors.transparent),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '${day.day}',
            style: TextStyle(
              color: Colors.white,
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        if (session != null)
          Padding(
            padding: const EdgeInsets.only(top: 2, left: 2, right: 2),
            child: Text(
              session.routineName ?? 'Workout',
              style: const TextStyle(fontSize: 9, color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
      ],
    ),
  );
}
