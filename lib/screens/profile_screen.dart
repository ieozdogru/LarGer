import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:larger/providers/calorie_target_provider.dart';
import 'package:larger/providers/exercise_provider.dart';
import 'package:larger/providers/food_provider.dart';
import 'package:larger/providers/history_provider.dart';
import 'package:larger/providers/profile_provider.dart';
import 'package:larger/providers/routine_provider.dart';
import 'package:larger/services/backup_service.dart';
import 'package:larger/services/dev_sample_data.dart';
import 'package:larger/services/local_user_data_service.dart';
import 'package:larger/theme/app_theme.dart';
import 'package:larger/utils/string_extensions.dart';
import 'package:larger/utils/validators.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String? _selectedExerciseId;
  String? _selectedExerciseName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PROFILE')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildBodyStatsSection(),
            const SizedBox(height: 20),
            _buildAnalyticsSection(),
            const SizedBox(height: 20),
            _buildBackupSection(),
            if (kDebugMode) ...[
              const SizedBox(height: 20),
              _buildDeveloperSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(color: AppTheme.accentRed),
    );
  }

  Widget _buildBodyStatsSection() {
    final height = ref.watch(heightProvider);
    final weightAsync = ref.watch(bodyWeightProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionTitle('BODY STATS'),
            const SizedBox(height: 8),
            _statTile(
              label: 'Height',
              value: '${height.toStringAsFixed(1)} cm',
              onTap: _showEditHeightDialog,
            ),
            weightAsync.when(
              data: (logs) {
                if (logs.isEmpty) {
                  return _statTile(
                    label: 'Weight',
                    value: 'Log weight',
                    subtitle: 'No entries yet',
                    onTap: _showLogWeightDialog,
                  );
                }
                final latest = logs.first;
                return _statTile(
                  label: 'Weight',
                  value: '${latest.weight.toStringAsFixed(1)} kg',
                  subtitle:
                      'Logged ${DateFormat('MMM d, yyyy').format(latest.date)}',
                  onTap: _showLogWeightDialog,
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => const ListTile(
                title: Text('Weight'),
                subtitle: Text('Could not load weight logs'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statTile({
    required String label,
    required String value,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: subtitle == null
          ? null
          : Text(subtitle, style: const TextStyle(color: Colors.grey)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
      onTap: onTap,
    );
  }

  void _showEditHeightDialog() {
    final controller = TextEditingController(
      text: ref.read(heightProvider).toStringAsFixed(1),
    );
    String? errorText;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Height (cm)'),
            content: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                hintText: 'e.g. 175.0',
                errorText: errorText,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final validationError = validateHeightCm(controller.text);
                  if (validationError != null) {
                    setDialogState(() => errorText = validationError);
                    return;
                  }
                  final height = double.parse(controller.text.trim());
                  await ref.read(profileNotifierProvider).setHeight(height);
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showLogWeightDialog() {
    final controller = TextEditingController();
    String? errorText;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Log Body Weight (kg)'),
            content: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                hintText: 'e.g. 80.5',
                errorText: errorText,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final validationError = validateWeightKg(controller.text);
                  if (validationError != null) {
                    setDialogState(() => errorText = validationError);
                    return;
                  }
                  final weight = double.parse(controller.text.trim());
                  await ref.read(profileNotifierProvider).logBodyWeight(weight);
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _selectTrackedExercise(TrackedExercise exercise) {
    setState(() {
      _selectedExerciseId = exercise.exerciseId;
      _selectedExerciseName = exercise.exerciseName.toTitleCase();
    });
    FocusScope.of(context).unfocus();
  }

  Widget _buildAnalyticsSection() {
    final trackedAsync = ref.watch(trackedExercisesProvider);
    final recentAsync = ref.watch(recentTrackedExercisesProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionTitle('EXERCISE ANALYTICS'),
            const SizedBox(height: 12),
            trackedAsync.when(
              data: (tracked) {
                if (tracked.isEmpty) {
                  return const Text(
                    'Complete sets in a workout to unlock exercise analytics.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Autocomplete<TrackedExercise>(
                      displayStringForOption: (option) =>
                          option.exerciseName.toTitleCase(),
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        final query = textEditingValue.text.toLowerCase();
                        if (query.isEmpty) return tracked;
                        return tracked.where(
                          (option) =>
                              option.exerciseName.toLowerCase().contains(query),
                        );
                      },
                      onSelected: _selectTrackedExercise,
                      fieldViewBuilder:
                          (context, controller, focusNode, onFieldSubmitted) {
                            return TextField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: InputDecoration(
                                hintText: 'Search exercises with data...',
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: Colors.grey,
                                ),
                                filled: true,
                                fillColor: Colors.grey[900],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            );
                          },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4.0,
                            color: Colors.grey[900],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: 250,
                                maxWidth:
                                    MediaQuery.of(context).size.width - 64,
                              ),
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (context, index) {
                                  final option = options.elementAt(index);
                                  return ListTile(
                                    title: Text(
                                      option.exerciseName.toTitleCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Last: ${DateFormat('MMM d, yyyy').format(option.lastPerformed)}',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                    onTap: () => onSelected(option),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'RECENT',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    recentAsync.when(
                      data: (recent) {
                        return Column(
                          children: recent.map((exercise) {
                            final selected =
                                exercise.exerciseId == _selectedExerciseId;
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              selected: selected,
                              selectedTileColor: AppTheme.accentRed.withValues(
                                alpha: 0.12,
                              ),
                              title: Text(exercise.exerciseName.toTitleCase()),
                              subtitle: Text(
                                DateFormat(
                                  'MMM d, yyyy',
                                ).format(exercise.lastPerformed),
                                style: const TextStyle(color: Colors.grey),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right,
                                color: Colors.grey,
                              ),
                              onTap: () => _selectTrackedExercise(exercise),
                            );
                          }).toList(),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const Text('Error loading exercise history'),
            ),
            const SizedBox(height: 20),
            if (_selectedExerciseId == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Pick a recent exercise or search to see PRs and progress',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              _buildExerciseProgression(),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseProgression() {
    final analyticsAsync = ref.watch(
      exerciseAnalyticsProvider(_selectedExerciseId),
    );

    return analyticsAsync.when(
      data: (analytics) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _selectedExerciseName ?? 'Selected exercise',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (analytics == null || analytics.progression.isEmpty)
              const Text(
                'No data recorded for this exercise yet.',
                style: TextStyle(color: Colors.grey),
              )
            else ...[
              Text(
                'ALL-TIME PR: ${analytics.prWeight} kg',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(height: 200, child: _buildChart(analytics.progression)),
              const SizedBox(height: 16),
              Text(
                'HISTORY',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              ...analytics.progression.reversed.map(
                (p) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          DateFormat('MMM d, yyyy').format(p.date),
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                      Text(
                        '${p.maxWeight} kg × ${p.reps}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Text('Error loading analytics'),
    );
  }

  Widget _buildChart(List<ProgressionEntry> progression) {
    if (progression.length < 2) {
      return const Center(
        child: Text(
          'Need more data to generate chart',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final spots = <FlSpot>[];
    final minX = 0.0;
    final maxX = (progression.length - 1).toDouble();
    var minY = progression.first.maxWeight;
    var maxY = progression.first.maxWeight;

    for (var i = 0; i < progression.length; i++) {
      final w = progression[i].maxWeight;
      spots.add(FlSpot(i.toDouble(), w));
      if (w < minY) minY = w;
      if (w > maxY) maxY = w;
    }

    minY = minY > 10 ? minY - 10 : 0;
    maxY = maxY + 10;

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minX: minX,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppTheme.accentRed,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.accentRed.withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionTitle('BACKUP'),
            const SizedBox(height: 8),
            const Text(
              'Export shares a JSON backup of this device. Import replaces all local workouts, routines, and body stats.',
              style: TextStyle(color: Colors.grey, height: 1.35),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: AppTheme.accentRed,
                side: const BorderSide(color: AppTheme.accentRed),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () async {
                await BackupService().exportData();
              },
              child: const Text(
                'Export Data (JSON)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[900],
                foregroundColor: Colors.white70,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () => _confirmImport(),
              child: const Text(
                'Import Data (JSON)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeveloperSection() {
    final tier = readSampleDataTier();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionTitle('DEVELOPER'),
            const SizedBox(height: 8),
            Text(
              'Current sample tier: ${tier.label}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 4),
            const Text(
              'Debug builds only',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ...SampleDataTier.values.map((sampleTier) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tier == sampleTier
                        ? AppTheme.accentRed
                        : Colors.black,
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: AppTheme.accentRed),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => _seedSampleTier(sampleTier),
                  child: Text('Seed ${sampleTier.label}'),
                ),
              );
            }),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                side: const BorderSide(color: AppTheme.accentRed),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                ref.read(calorieSettingsProvider).resetWelcome();
              },
              child: const Text('Show welcome screen'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _seedSampleTier(SampleDataTier tier) async {
    await clearLocalUserData();
    await seedDevSampleData(tier: tier);
    ref.invalidate(historyProvider);
    ref.invalidate(routineNotifierProvider);
    ref.invalidate(exercisesProvider);
    ref.invalidate(bodyWeightProvider);
    ref.invalidate(heightProvider);
    ref.invalidate(foodEntriesProvider);
    ref.invalidate(calorieProfileProvider);
    ref.invalidate(calorieMemoryProvider);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Seeded ${tier.label} sample data')));
  }

  void _confirmImport() {
    _showImportWarningDialog();
  }

  void _showImportWarningDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'Overwrite local data?',
          style: TextStyle(color: AppTheme.accentRed),
        ),
        content: const Text(
          'Importing a backup permanently erases workouts, routines, food logs, and body stats currently on this device, then replaces them with the file you choose. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentRed,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await BackupService().importData();
              if (!mounted) return;
              final messenger = ScaffoldMessenger.of(context);
              if (success) {
                ref.invalidate(historyProvider);
                ref.invalidate(routineNotifierProvider);
                ref.invalidate(exercisesProvider);
                ref.invalidate(bodyWeightProvider);
                ref.invalidate(heightProvider);
                ref.invalidate(foodEntriesProvider);
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Backup imported successfully!'),
                  ),
                );
              } else {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Import canceled or failed.')),
                );
              }
            },
            child: const Text(
              'Overwrite & Import',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
