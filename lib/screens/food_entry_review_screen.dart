import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:larger/models/models.dart';
import 'package:larger/providers/food_provider.dart';
import 'package:larger/theme/app_theme.dart';

class FoodEntryReviewScreen extends ConsumerStatefulWidget {
  const FoodEntryReviewScreen({
    super.key,
    this.existing,
    this.initialName,
    this.initialServingLabel,
    this.initialCalories,
    this.initialProteinG,
    this.initialCarbsG,
    this.initialFatG,
    this.source = 'manual',
    this.loggedAt,
  });

  final FoodEntry? existing;
  final String? initialName;
  final String? initialServingLabel;
  final double? initialCalories;
  final double? initialProteinG;
  final double? initialCarbsG;
  final double? initialFatG;
  final String source;
  final DateTime? loggedAt;

  @override
  ConsumerState<FoodEntryReviewScreen> createState() =>
      _FoodEntryReviewScreenState();
}

class _FoodEntryReviewScreenState extends ConsumerState<FoodEntryReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _servingLabelController;
  late final TextEditingController _servingsController;
  late final TextEditingController _caloriesController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fatController;
  late String _meal;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(
      text: existing?.name ?? widget.initialName ?? '',
    );
    _servingLabelController = TextEditingController(
      text: existing?.servingLabel ?? widget.initialServingLabel ?? '',
    );
    _servingsController = TextEditingController(
      text: _formatNumber(existing?.servings ?? 1),
    );
    _caloriesController = TextEditingController(
      text: _formatNumber(existing?.calories ?? widget.initialCalories),
    );
    _proteinController = TextEditingController(
      text: _formatNumber(existing?.proteinG ?? widget.initialProteinG),
    );
    _carbsController = TextEditingController(
      text: _formatNumber(existing?.carbsG ?? widget.initialCarbsG),
    );
    _fatController = TextEditingController(
      text: _formatNumber(existing?.fatG ?? widget.initialFatG),
    );
    _meal = existing?.meal ?? _defaultMeal();

    for (final controller in [
      _servingsController,
      _caloriesController,
      _proteinController,
      _carbsController,
      _fatController,
    ]) {
      controller.addListener(_onValuesChanged);
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _servingsController,
      _caloriesController,
      _proteinController,
      _carbsController,
      _fatController,
    ]) {
      controller.removeListener(_onValuesChanged);
    }
    _nameController.dispose();
    _servingLabelController.dispose();
    _servingsController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  void _onValuesChanged() {
    if (mounted) setState(() {});
  }

  String _defaultMeal() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'breakfast';
    if (hour < 16) return 'lunch';
    if (hour < 21) return 'dinner';
    return 'snack';
  }

  String _formatNumber(double? value) {
    if (value == null) return '';
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }

  double? _parseOptional(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    return double.tryParse(value.replaceAll(',', '.'));
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter a food name';
    return null;
  }

  String? _validateServings(String? value) {
    final parsed = _parseOptional(value ?? '');
    if (parsed == null) return 'Enter servings';
    if (parsed <= 0) return 'Servings must be greater than 0';
    return null;
  }

  String? _validateOptionalNumber(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return null;
    if (_parseOptional(raw) == null) return 'Enter a valid number';
    return null;
  }

  double get _servings {
    return _parseOptional(_servingsController.text) ?? 1;
  }

  void _nudgeServings(double delta) {
    final next = ((_parseOptional(_servingsController.text) ?? 1) + delta)
        .clamp(0.5, 99.0);
    _servingsController.text = _formatNumber(next);
  }

  String _pretty(double? value) {
    if (value == null) return '—';
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final existing = widget.existing;
    final entry = FoodEntry(
      id: existing?.id,
      name: _nameController.text.trim(),
      meal: _meal,
      loggedAt: existing?.loggedAt ?? widget.loggedAt ?? DateTime.now(),
      servingLabel: _servingLabelController.text.trim().isEmpty
          ? null
          : _servingLabelController.text.trim(),
      servings: _parseOptional(_servingsController.text) ?? 1,
      calories: _parseOptional(_caloriesController.text),
      proteinG: _parseOptional(_proteinController.text),
      carbsG: _parseOptional(_carbsController.text),
      fatG: _parseOptional(_fatController.text),
      source: existing?.source ?? widget.source,
    );

    await ref.read(foodNotifierProvider).save(entry);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final servings = _servings;
    final calories = _parseOptional(_caloriesController.text);
    final protein = _parseOptional(_proteinController.text);
    final carbs = _parseOptional(_carbsController.text);
    final fat = _parseOptional(_fatController.text);

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'EDIT FOOD' : 'LOG FOOD')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'What did you eat?',
                        hintText: 'Chicken, yogurt, protein bar…',
                      ),
                      validator: _validateName,
                    ),
                    const SizedBox(height: 20),
                    _SectionLabel('MEAL'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        for (var i = 0; i < foodMeals.length; i++) ...[
                          if (i > 0) const SizedBox(width: 8),
                          Expanded(
                            child: _MealChip(
                              label: foodMeals[i],
                              selected: _meal == foodMeals[i],
                              onTap: () => setState(() => _meal = foodMeals[i]),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 24),
                    _SectionLabel('SERVING'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _servingLabelController,
                      decoration: const InputDecoration(
                        labelText: 'Serving size',
                        hintText: '100 g, 1 cup, 1 bar…',
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ServingsStepper(
                      controller: _servingsController,
                      validator: _validateServings,
                      onMinus: () => _nudgeServings(-0.5),
                      onPlus: () => _nudgeServings(0.5),
                    ),
                    const SizedBox(height: 24),
                    _SectionLabel('PER SERVING'),
                    const SizedBox(height: 8),
                    _MacroField(
                      controller: _caloriesController,
                      label: 'KCAL',
                      validator: _validateOptionalNumber,
                      emphasized: true,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _MacroField(
                            controller: _proteinController,
                            label: 'PROTEIN',
                            unit: 'g',
                            validator: _validateOptionalNumber,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MacroField(
                            controller: _carbsController,
                            label: 'CARBS',
                            unit: 'g',
                            validator: _validateOptionalNumber,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MacroField(
                            controller: _fatController,
                            label: 'FAT',
                            unit: 'g',
                            validator: _validateOptionalNumber,
                          ),
                        ),
                      ],
                    ),
                    if (servings != 1) ...[
                      const SizedBox(height: 16),
                      _LogPreview(
                        servings: servings,
                        calories: calories,
                        protein: protein,
                        carbs: carbs,
                        fat: fat,
                        pretty: _pretty,
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    child: Text(isEdit ? 'SAVE CHANGES' : 'ADD TO DIARY'),
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

class _MealChip extends StatelessWidget {
  const _MealChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = label[0].toUpperCase() + label.substring(1);
    return Material(
      color: selected ? AppTheme.accentRed : AppTheme.surfaceColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 13,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ServingsStepper extends StatelessWidget {
  const _ServingsStepper({
    required this.controller,
    required this.validator,
    required this.onMinus,
    required this.onPlus,
  });

  final TextEditingController controller;
  final String? Function(String?) validator;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StepperButton(icon: Icons.remove, onTap: onMinus),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: controller,
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            style: Theme.of(context).textTheme.headlineMedium,
            decoration: const InputDecoration(
              labelText: 'Servings eaten',
            ),
            validator: validator,
          ),
        ),
        const SizedBox(width: 12),
        _StepperButton(icon: Icons.add, onTap: onPlus),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 52,
          height: 56,
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}

class _MacroField extends StatelessWidget {
  const _MacroField({
    required this.controller,
    required this.label,
    this.unit,
    this.validator,
    this.emphasized = false,
  });

  final TextEditingController controller;
  final String label;
  final String? unit;
  final String? Function(String?)? validator;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      textAlign: TextAlign.center,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      ],
      style: emphasized
          ? Theme.of(context).textTheme.headlineLarge
          : Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 22),
      decoration: InputDecoration(
        labelText: unit == null ? label : '$label ($unit)',
        floatingLabelAlignment: FloatingLabelAlignment.center,
      ),
      validator: validator,
    );
  }
}

class _LogPreview extends StatelessWidget {
  const _LogPreview({
    required this.servings,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.pretty,
  });

  final double servings;
  final double? calories;
  final double? protein;
  final double? carbs;
  final double? fat;
  final String Function(double?) pretty;

  @override
  Widget build(BuildContext context) {
    String scale(double? value) {
      if (value == null) return '—';
      return pretty(value * servings);
    }

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
            'THIS LOG',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppTheme.accentRed),
          ),
          const SizedBox(height: 8),
          Text(
            '${scale(calories)} kcal',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'P ${scale(protein)}   C ${scale(carbs)}   F ${scale(fat)}',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
