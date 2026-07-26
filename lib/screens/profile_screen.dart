import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:larger/providers/auth_provider.dart';
import 'package:larger/providers/exercise_provider.dart';
import 'package:larger/providers/profile_provider.dart';
import 'package:larger/theme/app_theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:larger/services/backup_service.dart';
import 'package:larger/providers/history_provider.dart';
import 'package:larger/providers/routine_provider.dart';
import 'package:larger/utils/string_extensions.dart';
import 'package:larger/models/models.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String? _selectedExerciseId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PROFILE & ANALYTICS')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildAccountSection(),
            const SizedBox(height: 24),
            _buildBodyStatsSection(),
            const SizedBox(height: 24),
            _buildAnalyticsSection(),
            const SizedBox(height: 32),
            _buildBackupSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSection() {
    final user = ref.watch(firebaseAuthProvider).currentUser;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ACCOUNT',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: AppTheme.accentRed),
            ),
            const Divider(),
            Text(
              user?.email ?? 'Signed in',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  await ref.read(authNotifierProvider.notifier).signOut();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.accentRed,
                  side: const BorderSide(color: AppTheme.accentRed),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('SIGN OUT'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyStatsSection() {
    final height = ref.watch(profileNotifierProvider).getHeight();
    final weightAsync = ref.watch(bodyWeightProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BODY STATS',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: AppTheme.accentRed),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Height:', style: Theme.of(context).textTheme.titleMedium),
                TextButton(
                  onPressed: _showEditHeightDialog,
                  child: Text(
                    '${height.toStringAsFixed(1)} cm',
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current Weight:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                weightAsync.when(
                  data: (logs) {
                    final weight = logs.isNotEmpty ? logs.first.weight : 0.0;
                    return TextButton(
                      onPressed: _showLogWeightDialog,
                      child: Text(
                        logs.isNotEmpty
                            ? '${weight.toStringAsFixed(1)} kg'
                            : 'Log Weight',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const Text('Error'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditHeightDialog() {
    final controller = TextEditingController(
      text: ref.read(profileNotifierProvider).getHeight().toString(),
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Height (cm)'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'e.g. 175.0'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final h = double.tryParse(controller.text);
              if (h != null) {
                ref.read(profileNotifierProvider).setHeight(h);
                setState(() {});
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showLogWeightDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Body Weight (kg)'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'e.g. 80.5'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final w = double.tryParse(controller.text);
              if (w != null) {
                ref.read(profileNotifierProvider).logBodyWeight(w);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsSection() {
    final exercisesAsync = ref.watch(exercisesProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'EXERCISE ANALYTICS',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: AppTheme.accentRed),
            ),
            const Divider(),
            const SizedBox(height: 8),
            exercisesAsync.when(
              data: (exercises) {
                return Autocomplete<Exercise>(
                  displayStringForOption: (Exercise option) =>
                      option.name.toTitleCase(),
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return exercises;
                    }
                    return exercises.where((Exercise option) {
                      return option.name.toLowerCase().contains(
                        textEditingValue.text.toLowerCase(),
                      );
                    });
                  },
                  onSelected: (Exercise selection) {
                    setState(() {
                      _selectedExerciseId = selection.id;
                    });
                    FocusScope.of(context).unfocus();
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onFieldSubmitted) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            hintText: 'Search exercise...',
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
                            maxWidth: MediaQuery.of(context).size.width - 64,
                          ),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (BuildContext context, int index) {
                              final Exercise option = options.elementAt(index);
                              return ListTile(
                                title: Text(
                                  option.name.toTitleCase(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                                onTap: () {
                                  onSelected(option);
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('Error loading exercises'),
            ),
            const SizedBox(height: 24),
            if (_selectedExerciseId != null) _buildExerciseProgression(),
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
        if (analytics == null || analytics.progression.isEmpty) {
          return const Center(
            child: Text(
              'No data recorded for this exercise yet.',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            const Text(
              'HISTORY',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...analytics.progression.reversed.map(
              (p) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('MMM d, yyyy').format(p.date),
                      style: const TextStyle(color: Colors.grey),
                    ),
                    Text(
                      '${p.maxWeight} kg x ${p.reps}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Text('Error loading analytics'),
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

    List<FlSpot> spots = [];
    double minX = 0;
    double maxX = (progression.length - 1).toDouble();
    double minY = progression.first.maxWeight;
    double maxY = progression.first.maxWeight;

    for (int i = 0; i < progression.length; i++) {
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
        const SizedBox(height: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: AppTheme.accentRed,
            side: const BorderSide(color: AppTheme.accentRed),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: () => _showImportWarningDialog(),
          child: const Text(
            'Import Backup',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  void _showImportWarningDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Warning: Overwrite Data?',
          style: TextStyle(color: AppTheme.accentRed),
        ),
        content: const Text(
          'This will erase all current local data and replace it with the backup. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentRed,
            ),
            onPressed: () async {
              Navigator.pop(context);
              final success = await BackupService().importData();
              if (success && mounted) {
                ref.invalidate(historyProvider);
                ref.invalidate(routineNotifierProvider);
                ref.invalidate(exercisesProvider);
                ref.invalidate(bodyWeightProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Backup imported successfully!'),
                  ),
                );
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Import canceled or failed.')),
                );
              }
            },
            child: const Text(
              'Confirm Overwrite',
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
