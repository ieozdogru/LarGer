import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:larger/models/models.dart';
import 'package:larger/utils/string_extensions.dart';
import 'package:larger/screens/main_layout.dart';

class WorkoutSummaryScreen extends ConsumerStatefulWidget {
  final WorkoutSession session;

  const WorkoutSummaryScreen({super.key, required this.session});

  @override
  ConsumerState<WorkoutSummaryScreen> createState() =>
      _WorkoutSummaryScreenState();
}

class _WorkoutSummaryScreenState extends ConsumerState<WorkoutSummaryScreen> {
  List<String> prMessages = [];

  @override
  void initState() {
    super.initState();
    _calculatePRs();
  }

  void _calculatePRs() {
    final box = Hive.box<WorkoutSession>('sessions');
    final allSessions = box.values
        .where(
          (s) =>
              s.id != widget.session.id &&
              s.endTime != null &&
              s.endTime!.isBefore(widget.session.startTime),
        )
        .toList();

    for (var ex in widget.session.exercises) {
      if (ex.exerciseId == null || ex.sets.isEmpty) continue;

      double maxWeightThisSession = 0.0;
      double maxVolumeThisSession = 0.0;

      for (var s in ex.sets) {
        if (!s.isCompleted) continue;
        if (s.weight > maxWeightThisSession) maxWeightThisSession = s.weight;
        maxVolumeThisSession += (s.weight * s.reps);
      }

      if (maxVolumeThisSession == 0 && maxWeightThisSession == 0) continue;

      double historicalMaxWeight = 0.0;
      double historicalMaxVolume = 0.0;

      for (var pastSess in allSessions) {
        for (var pastEx in pastSess.exercises) {
          if (pastEx.exerciseId == ex.exerciseId) {
            double vol = 0.0;
            for (var ps in pastEx.sets) {
              if (!ps.isCompleted) continue;
              if (ps.weight > historicalMaxWeight) {
                historicalMaxWeight = ps.weight;
              }
              vol += (ps.weight * ps.reps);
            }
            if (vol > historicalMaxVolume) historicalMaxVolume = vol;
          }
        }
      }

      final exName = ex.exerciseName?.toTitleCase() ?? 'Exercise';
      if (historicalMaxWeight > 0 &&
          maxWeightThisSession > historicalMaxWeight) {
        prMessages.add('New PR for $exName Weight: ${maxWeightThisSession}kg!');
      } else if (historicalMaxVolume > 0 &&
          maxVolumeThisSession > historicalMaxVolume) {
        prMessages.add('New PR for $exName Volume: ${maxVolumeThisSession}kg!');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final duration = widget.session.endTime != null
        ? widget.session.endTime!.difference(widget.session.startTime)
        : Duration.zero;

    final formattedDuration =
        "${duration.inHours > 0 ? '${duration.inHours}:' : ''}${(duration.inMinutes % 60).toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}";

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Workout Complete'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const MainLayout()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.emoji_events, size: 80, color: Colors.amber),
              const SizedBox(height: 16),
              Text(
                'CONGRATULATIONS!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              Card(
                color: Colors.grey[900],
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatColumn(label: 'Time', value: formattedDuration),
                      _StatColumn(
                        label: 'Volume',
                        value:
                            '${widget.session.totalVolume.toStringAsFixed(1)} kg',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Session Notes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'How did the workout feel?',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) {
                  widget.session.notes = val;
                  widget.session.save();
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Exercise Notes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(height: 8),
              ...widget.session.exercises.map((ex) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText:
                          'Notes for ${ex.exerciseName?.toTitleCase() ?? 'Exercise'}',
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      ex.notes = val;
                      widget.session.save();
                    },
                  ),
                );
              }),
              const SizedBox(height: 24),
              if (prMessages.isNotEmpty) ...[
                const Text(
                  'Personal Records 🎉',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: prMessages.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.star, color: Colors.amber),
                      title: Text(
                        prMessages[index],
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  },
                ),
              ] else ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(
                    child: Text(
                      'Great job! Keep pushing to hit new PRs.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const MainLayout()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.redAccent,
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;

  const _StatColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
