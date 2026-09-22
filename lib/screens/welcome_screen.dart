import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:larger/providers/calorie_target_provider.dart';
import 'package:larger/providers/profile_provider.dart';
import 'package:larger/services/calorie_intake.dart';
import 'package:larger/theme/app_theme.dart';
import 'package:larger/utils/validators.dart';

/// First-launch questions, one at a time.
/// Step 0 is the hello screen. Steps 1–6 are the questions.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  static const _questionCount = 6;

  var _step = 0;
  var _saving = false;
  var _goingForward = true;
  String? _error;
  BiologicalSex? _sex;
  ActivityLevel? _activity;
  CalorieGoal? _goal;
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  String _normalized(TextEditingController controller) {
    return controller.text.trim().replaceAll(',', '.');
  }

  String? _validateCurrent() {
    switch (_step) {
      case 1:
        return _sex == null ? 'Pick one' : null;
      case 2:
        final age = int.tryParse(_ageController.text.trim());
        if (age == null) return 'Enter your age';
        if (age < 15 || age > 100) return 'Enter an age from 15 to 100';
        return null;
      case 3:
        return validateHeightCm(_normalized(_heightController));
      case 4:
        return validateWeightKg(_normalized(_weightController));
      case 5:
        return _activity == null ? 'Pick one' : null;
      case 6:
        return _goal == null ? 'Pick one' : null;
      default:
        return null;
    }
  }

  Future<void> _next() async {
    final error = _validateCurrent();
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    if (_step == _questionCount) {
      await _finish();
      return;
    }
    setState(() {
      _error = null;
      _goingForward = true;
      _step += 1;
    });
  }

  void _back() {
    if (_step == 0 || _saving) return;
    setState(() {
      _error = null;
      _goingForward = false;
      _step -= 1;
    });
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    try {
      final age = int.parse(_ageController.text.trim());
      final height = double.parse(_normalized(_heightController));
      final weight = double.parse(_normalized(_weightController));
      final bodyFat = ref.read(calorieProfileProvider).bodyFatPercent;

      await ref.read(profileNotifierProvider).setHeight(height);
      await ref.read(profileNotifierProvider).logBodyWeight(weight);
      await ref
          .read(calorieSettingsProvider)
          .saveProfile(
            sex: _sex!,
            ageYears: age,
            activity: _activity!,
            bodyFatPercent: bodyFat,
            goal: _goal!,
          );
      if (!mounted) return;
      await ref.read(calorieSettingsProvider).markWelcomeCompleted();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Could not save. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final questionNumber = _step;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_step == 0)
                const SizedBox(height: 8)
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$questionNumber of $_questionCount',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: questionNumber / _questionCount,
                        minHeight: 6,
                        backgroundColor: Colors.white12,
                        color: AppTheme.accentRed,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 24),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 420),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  layoutBuilder: (current, previous) {
                    return Stack(
                      alignment: Alignment.topCenter,
                      children: [...previous, ?current],
                    );
                  },
                  transitionBuilder: (child, animation) {
                    final slide = Tween<Offset>(
                      begin: Offset(_goingForward ? 0.16 : -0.16, 0),
                      end: Offset.zero,
                    ).animate(animation);
                    return ClipRect(
                      child: FadeTransition(
                        opacity: animation,
                        child: SlideTransition(position: slide, child: child),
                      ),
                    );
                  },
                  child: SingleChildScrollView(
                    key: ValueKey(_step),
                    child: _stepBody(),
                  ),
                ),
              ),
              if (_error != null) ...[
                Text(
                  _error!,
                  style: const TextStyle(color: AppTheme.accentRed),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  if (_step > 0) ...[
                    TextButton(
                      onPressed: _saving ? null : _back,
                      child: const Text('BACK'),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving ? null : _next,
                      child: Text(_primaryLabel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _primaryLabel {
    if (_saving) return 'SAVING';
    if (_step == 0) return 'START';
    if (_step == _questionCount) return 'DONE';
    return 'NEXT';
  }

  Widget _stepBody() {
    switch (_step) {
      case 0:
        return _HelloStep();
      case 1:
        return _QuestionStep(
          title: 'Are you a man or a woman?',
          helper: 'Men and women start from different calorie formulas.',
          child: _TwoChoices(
            left: BiologicalSex.male.label,
            right: BiologicalSex.female.label,
            leftSelected: _sex == BiologicalSex.male,
            rightSelected: _sex == BiologicalSex.female,
            onLeft: () => setState(() {
              _sex = BiologicalSex.male;
              _error = null;
            }),
            onRight: () => setState(() {
              _sex = BiologicalSex.female;
              _error = null;
            }),
          ),
        );
      case 2:
        return _QuestionStep(
          title: 'How old are you?',
          helper: 'Used for the starting calorie estimate.',
          child: _NumberAnswer(
            controller: _ageController,
            hint: 'Years',
            digitsOnly: true,
            onChanged: () => setState(() => _error = null),
          ),
        );
      case 3:
        return _QuestionStep(
          title: 'How tall are you?',
          helper: 'In centimeters.',
          child: _NumberAnswer(
            controller: _heightController,
            hint: 'cm',
            onChanged: () => setState(() => _error = null),
          ),
        );
      case 4:
        return _QuestionStep(
          title: 'What do you weigh?',
          helper: 'In kilograms. You can log it again later.',
          child: _NumberAnswer(
            controller: _weightController,
            hint: 'kg',
            onChanged: () => setState(() => _error = null),
          ),
        );
      case 5:
        return _QuestionStep(
          title: 'How active are you?',
          helper: 'A normal week, including workouts.',
          child: Column(
            children: [
              for (final level in ActivityLevel.values)
                _OptionTile(
                  title: level.label,
                  subtitle: level.description,
                  selected: _activity == level,
                  onTap: () => setState(() {
                    _activity = level;
                    _error = null;
                  }),
                ),
            ],
          ),
        );
      default:
        return _QuestionStep(
          title: 'What do you want to do?',
          helper: 'Lose weight is 500 kcal under maintenance.',
          child: Column(
            children: [
              for (final goal in CalorieGoal.values)
                _OptionTile(
                  title: goal.label,
                  subtitle: goal.description,
                  selected: _goal == goal,
                  onTap: () => setState(() {
                    _goal = goal;
                    _error = null;
                  }),
                ),
            ],
          ),
        );
    }
  }
}

class _HelloStep extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome',
          style: Theme.of(
            context,
          ).textTheme.headlineLarge?.copyWith(fontSize: 48),
        ),
        const SizedBox(height: 16),
        Text(
          'LarGer keeps your workouts and food on this phone.',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: Colors.white70, height: 1.35),
        ),
        const SizedBox(height: 12),
        Text(
          'Six short questions set your daily calories.',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: Colors.white70, height: 1.35),
        ),
      ],
    );
  }
}

class _QuestionStep extends StatelessWidget {
  const _QuestionStep({
    required this.title,
    required this.helper,
    required this.child,
  });

  final String title;
  final String helper;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(height: 1.2),
        ),
        const SizedBox(height: 8),
        Text(helper, style: const TextStyle(color: Colors.grey, height: 1.35)),
        const SizedBox(height: 28),
        child,
      ],
    );
  }
}

class _TwoChoices extends StatelessWidget {
  const _TwoChoices({
    required this.left,
    required this.right,
    required this.leftSelected,
    required this.rightSelected,
    required this.onLeft,
    required this.onRight,
  });

  final String left;
  final String right;
  final bool leftSelected;
  final bool rightSelected;
  final VoidCallback onLeft;
  final VoidCallback onRight;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ChoiceButton(
            label: left,
            selected: leftSelected,
            onTap: onLeft,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ChoiceButton(
            label: right,
            selected: rightSelected,
            onTap: onRight,
          ),
        ),
      ],
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
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
          padding: const EdgeInsets.symmetric(vertical: 28),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontSize: 22),
          ),
        ),
      ),
    );
  }
}

class _NumberAnswer extends StatelessWidget {
  const _NumberAnswer({
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.digitsOnly = false,
  });

  final TextEditingController controller;
  final String hint;
  final VoidCallback onChanged;
  final bool digitsOnly;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: true,
      textAlign: TextAlign.center,
      keyboardType: digitsOnly
          ? TextInputType.number
          : const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          digitsOnly ? RegExp(r'[0-9]') : RegExp(r'[0-9.,]'),
        ),
      ],
      style: Theme.of(context).textTheme.headlineLarge,
      decoration: InputDecoration(hintText: hint),
      onChanged: (_) => onChanged(),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: selected ? AppTheme.accentRed : AppTheme.surfaceColor,
      child: ListTile(
        title: Text(title),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: selected ? Colors.white70 : Colors.grey),
        ),
        onTap: onTap,
      ),
    );
  }
}
