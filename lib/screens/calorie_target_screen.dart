import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:larger/providers/calorie_target_provider.dart';
import 'package:larger/providers/profile_provider.dart';
import 'package:larger/services/calorie_intake.dart';
import 'package:larger/theme/app_theme.dart';

class CalorieTargetScreen extends ConsumerStatefulWidget {
  const CalorieTargetScreen({super.key});

  @override
  ConsumerState<CalorieTargetScreen> createState() =>
      _CalorieTargetScreenState();
}

class _CalorieTargetScreenState extends ConsumerState<CalorieTargetScreen> {
  final _ageController = TextEditingController();
  final _bodyFatController = TextEditingController();
  BiologicalSex? _sex;
  ActivityLevel? _activity;
  CalorieGoal? _goal;
  String? _ageError;
  String? _bodyFatError;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(calorieProfileProvider);
    _sex = profile.sex;
    _activity = profile.activity;
    _goal = profile.goal ?? CalorieGoal.maintain;
    if (profile.ageYears != null) {
      _ageController.text = profile.ageYears.toString();
    }
    if (profile.bodyFatPercent != null) {
      final bodyFat = profile.bodyFatPercent!;
      _bodyFatController.text = bodyFat == bodyFat.roundToDouble()
          ? bodyFat.toInt().toString()
          : bodyFat.toString();
    }
  }

  @override
  void dispose() {
    _ageController.dispose();
    _bodyFatController.dispose();
    super.dispose();
  }

  int? _parseAge() => int.tryParse(_ageController.text.trim());

  double? _parseBodyFat() {
    final raw = _bodyFatController.text.trim();
    if (raw.isEmpty) return null;
    return double.tryParse(raw.replaceAll(',', '.'));
  }

  bool _validate() {
    final age = _parseAge();
    String? ageError;
    if (age == null) {
      ageError = 'Enter your age';
    } else if (age < 15 || age > 100) {
      ageError = 'Enter an age from 15 to 100';
    }

    final bodyFat = _parseBodyFat();
    String? bodyFatError;
    final rawBodyFat = _bodyFatController.text.trim();
    if (rawBodyFat.isNotEmpty && bodyFat == null) {
      bodyFatError = 'Enter a valid number';
    } else if (bodyFat != null && (bodyFat <= 0 || bodyFat >= 75)) {
      bodyFatError = 'Enter body fat between 1 and 75%';
    }

    setState(() {
      _ageError = ageError;
      _bodyFatError = bodyFatError;
    });
    return ageError == null &&
        bodyFatError == null &&
        _sex != null &&
        _activity != null &&
        _goal != null;
  }

  Future<void> _save() async {
    if (!_validate()) return;
    await ref
        .read(calorieSettingsProvider)
        .saveProfile(
          sex: _sex!,
          ageYears: _parseAge()!,
          activity: _activity!,
          bodyFatPercent: _parseBodyFat(),
          goal: _goal!,
        );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final height = ref.watch(heightProvider);
    final weight = ref
        .watch(bodyWeightProvider)
        .asData
        ?.value
        .firstOrNull
        ?.weight;
    final age = _parseAge();
    final bodyFat = _parseBodyFat();
    final sex = _sex;
    final activity = _activity;
    final goal = _goal;

    double? estimate;
    if (sex != null &&
        age != null &&
        age >= 15 &&
        age <= 100 &&
        activity != null &&
        goal != null &&
        weight != null) {
      final maintenance = predictiveTdee(
        sex: sex,
        weightKg: weight,
        heightCm: height,
        ageYears: age,
        activity: activity,
        bodyFatPercent: bodyFat,
      ).round();
      estimate = maintenance + goal.delta;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('DAILY CALORIES')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  Text(
                    'This is the starting estimate from your stats. After 14 days of weight and food logs, the target follows what you actually eat and how your weight moves. It changes by at most 150 kcal a week. Lose and Maintain apply right away.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    weight == null
                        ? 'Using height ${height.toStringAsFixed(1)} cm from Profile. Log your weight on Profile to calculate a target.'
                        : 'Using height ${height.toStringAsFixed(1)} cm and weight ${weight.toStringAsFixed(1)} kg from Profile.',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  const _SectionLabel('SEX'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (var i = 0; i < BiologicalSex.values.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(
                          child: _ChoiceChip(
                            label: BiologicalSex.values[i].label,
                            selected: _sex == BiologicalSex.values[i],
                            onTap: () =>
                                setState(() => _sex = BiologicalSex.values[i]),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                  const _SectionLabel('AGE'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => setState(() => _ageError = null),
                    decoration: InputDecoration(
                      hintText: 'Years',
                      errorText: _ageError,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _SectionLabel('ACTIVITY'),
                  const SizedBox(height: 8),
                  for (final level in ActivityLevel.values)
                    _ActivityTile(
                      level: level,
                      selected: _activity == level,
                      onTap: () => setState(() => _activity = level),
                    ),
                  const SizedBox(height: 16),
                  const _SectionLabel('BODY FAT'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _bodyFatController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    onChanged: (_) => setState(() => _bodyFatError = null),
                    decoration: InputDecoration(
                      hintText: 'Optional %',
                      helperText:
                          'If you know it, lean body mass is used instead of the general formula.',
                      errorText: _bodyFatError,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _SectionLabel('GOAL'),
                  const SizedBox(height: 8),
                  for (final goal in CalorieGoal.values)
                    _GoalTile(
                      goal: goal,
                      selected: _goal == goal,
                      onTap: () => setState(() => _goal = goal),
                    ),
                  const SizedBox(height: 24),
                  _EstimateCard(estimate: estimate),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('SAVE TARGET'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(color: AppTheme.accentRed),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppTheme.accentRed : AppTheme.surfaceColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontSize: 16, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.level,
    required this.selected,
    required this.onTap,
  });

  final ActivityLevel level;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: selected ? AppTheme.accentRed : AppTheme.surfaceColor,
      child: ListTile(
        title: Text(level.label),
        subtitle: Text(
          level.description,
          style: TextStyle(color: selected ? Colors.white70 : Colors.grey),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _GoalTile extends StatelessWidget {
  const _GoalTile({
    required this.goal,
    required this.selected,
    required this.onTap,
  });

  final CalorieGoal goal;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: selected ? AppTheme.accentRed : AppTheme.surfaceColor,
      child: ListTile(
        title: Text(goal.label),
        subtitle: Text(
          goal.description,
          style: TextStyle(color: selected ? Colors.white70 : Colors.grey),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _EstimateCard extends StatelessWidget {
  const _EstimateCard({required this.estimate});

  final double? estimate;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'STARTING TARGET',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppTheme.accentRed),
          ),
          const SizedBox(height: 8),
          Text(
            estimate == null ? '—' : '${estimate!.round()} kcal',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ],
      ),
    );
  }
}
