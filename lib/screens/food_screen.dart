import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:larger/models/models.dart';
import 'package:larger/providers/calorie_target_provider.dart';
import 'package:larger/providers/food_provider.dart';
import 'package:larger/screens/calorie_target_screen.dart';
import 'package:larger/screens/food_entry_review_screen.dart';
import 'package:larger/services/calorie_intake.dart';
import 'package:larger/services/nutrition_label_parser.dart';
import 'package:larger/services/nutrition_ocr_service.dart';
import 'package:larger/theme/app_theme.dart';
import 'package:larger/widgets/complication_ring.dart';
import 'package:larger/widgets/page_gradient.dart';
import 'package:larger/widgets/profile_button.dart';
import 'package:table_calendar/table_calendar.dart';

class FoodScreen extends ConsumerStatefulWidget {
  const FoodScreen({super.key});

  @override
  ConsumerState<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends ConsumerState<FoodScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  final _ocr = const NutritionOcrService();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedDay = now;
    _selectedDay = normalizeFoodDay(now);
  }

  Future<void> _addManually() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FoodEntryReviewScreen(loggedAt: _selectedDay),
      ),
    );
  }

  Future<void> _scan(ImageSource source) async {
    try {
      final text = await _ocr.recognize(source);
      if (!mounted) return;
      if (text == null || text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No nutrition text found. Add it manually.'),
          ),
        );
        return;
      }

      final parsed = NutritionLabelParser.parse(text);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FoodEntryReviewScreen(
            initialServingLabel: parsed.servingLabel,
            initialCalories: parsed.calories,
            initialProteinG: parsed.proteinG,
            initialCarbsG: parsed.carbsG,
            initialFatG: parsed.fatG,
            source: 'ocr',
            loggedAt: _selectedDay,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not scan label: $error')));
    }
  }

  Future<void> _showAddOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_ocr.isSupported) ...[
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Scan label with camera'),
                  onTap: () {
                    Navigator.pop(context);
                    _scan(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Scan label from photos'),
                  onTap: () {
                    Navigator.pop(context);
                    _scan(ImageSource.gallery);
                  },
                ),
              ],
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Add manually'),
                onTap: () {
                  Navigator.pop(context);
                  _addManually();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _openCalorieTarget() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const CalorieTargetScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final daysWithFood = ref.watch(foodDaysWithEntriesProvider);
    final dayEntries = ref.watch(foodEntriesForDayProvider(_selectedDay));
    final totals = ref.watch(foodDayTotalsProvider(_selectedDay));
    final target = ref.watch(calorieTargetProvider);
    final profile = ref.watch(calorieProfileProvider);

    return GradientPage(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: const ProfileButton(heroTag: 'profile-food'),
        title: const Text('FOOD'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddOptions,
        backgroundColor: AppTheme.accentRed,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = normalizeFoodDay(selected);
                _focusedDay = focused;
              });
            },
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
                return _buildDayCell(
                  day,
                  hasFood: daysWithFood.maybeWhen(
                    data: (days) => days.contains(normalizeFoodDay(day)),
                    orElse: () => false,
                  ),
                  isToday: false,
                  isSelected: isSameDay(day, _selectedDay),
                );
              },
              todayBuilder: (context, day, focusedDay) {
                return _buildDayCell(
                  day,
                  hasFood: daysWithFood.maybeWhen(
                    data: (days) => days.contains(normalizeFoodDay(day)),
                    orElse: () => false,
                  ),
                  isToday: true,
                  isSelected: isSameDay(day, _selectedDay),
                );
              },
              selectedBuilder: (context, day, focusedDay) {
                return _buildDayCell(
                  day,
                  hasFood: daysWithFood.maybeWhen(
                    data: (days) => days.contains(normalizeFoodDay(day)),
                    orElse: () => false,
                  ),
                  isToday: isSameDay(day, DateTime.now()),
                  isSelected: true,
                );
              },
              outsideBuilder: (context, day, focusedDay) {
                return Opacity(
                  opacity: 0.5,
                  child: _buildDayCell(
                    day,
                    hasFood: daysWithFood.maybeWhen(
                      data: (days) => days.contains(normalizeFoodDay(day)),
                      orElse: () => false,
                    ),
                    isToday: false,
                    isSelected: false,
                  ),
                );
              },
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: totals.when(
              data: (value) => target.when(
                data: (view) => _DayIntakeCard(
                  totals: value,
                  view: view,
                  profile: profile,
                  onEditTarget: _openCalorieTarget,
                ),
                loading: () => const LinearProgressIndicator(),
                error: (error, _) => Text('Could not load target: $error'),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => Text('Could not load totals: $error'),
            ),
          ),
          Expanded(
            child: dayEntries.when(
              data: (entries) {
                if (entries.isEmpty) {
                  return const Center(
                    child: Text('No food logged for this day.'),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                  children: [
                    for (final meal in foodMeals)
                      _MealSection(
                        meal: meal,
                        entries: entries
                            .where((entry) => entry.meal == meal)
                            .toList(),
                      ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayIntakeCard extends StatelessWidget {
  const _DayIntakeCard({
    required this.totals,
    required this.view,
    required this.profile,
    required this.onEditTarget,
  });

  final FoodDayTotals totals;
  final CalorieTargetView view;
  final CalorieProfile profile;
  final VoidCallback onEditTarget;

  @override
  Widget build(BuildContext context) {
    final eaten = totals.calories.round();
    final resolution = view.resolution;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (resolution == null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _MissingTarget(
                  gap: view.gap,
                  eaten: eaten,
                  onEditTarget: onEditTarget,
                ),
              )
            else
              _GoalRings(
                totals: totals,
                resolution: resolution,
                profile: profile,
                onEditTarget: onEditTarget,
              ),
          ],
        ),
      ),
    );
  }
}

class _GoalRings extends StatelessWidget {
  const _GoalRings({
    required this.totals,
    required this.resolution,
    required this.profile,
    required this.onEditTarget,
  });

  final FoodDayTotals totals;
  final CalorieResolution resolution;
  final CalorieProfile profile;
  final VoidCallback onEditTarget;

  @override
  Widget build(BuildContext context) {
    final target = resolution.targetKcal.round();
    final proteinGoal = resolvedGramGoal(
      stored: profile.proteinGoalG,
      fallback: defaultProteinGoalG(target.toDouble()),
    );
    final carbGoal = resolvedGramGoal(
      stored: profile.carbGoalG,
      fallback: defaultCarbGoalG(target.toDouble()),
    );

    return Column(
      children: [
        DailyComplications(
          caloriesEaten: totals.calories.round(),
          calorieTarget: target,
          proteinEaten: totals.proteinG.round(),
          proteinGoal: proteinGoal,
          carbsEaten: totals.carbsG.round(),
          carbGoal: carbGoal,
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _basisLabel(resolution.basis),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
              GestureDetector(
                onTap: onEditTarget,
                child: const Text(
                  'EDIT',
                  style: TextStyle(
                    color: AppTheme.accentRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MissingTarget extends StatelessWidget {
  const _MissingTarget({
    required this.gap,
    required this.eaten,
    required this.onEditTarget,
  });

  final CalorieTargetGap? gap;
  final int eaten;
  final VoidCallback onEditTarget;

  @override
  Widget build(BuildContext context) {
    final message = gap == CalorieTargetGap.needsWeight
        ? 'Log your weight on Profile to see this as a percent of your daily calories.'
        : 'Add your age, sex, and activity to see this as a percent of your daily calories.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$eaten kcal', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text(message, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: onEditTarget,
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.accentRed,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('SET DAILY CALORIES'),
          ),
        ),
      ],
    );
  }
}

String _basisLabel(CalorieBasis basis) {
  switch (basis) {
    case CalorieBasis.estimated:
      return 'From your height, weight, age, and activity';
    case CalorieBasis.adaptive:
      return 'From your weight trend and the calories you logged';
    case CalorieBasis.held:
      return 'Kept the same — a few days this week have no food log';
  }
}

class _MealSection extends ConsumerWidget {
  const _MealSection({required this.meal, required this.entries});

  final String meal;
  final List<FoodEntry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (entries.isEmpty) return const SizedBox.shrink();
    final title = meal[0].toUpperCase() + meal.substring(1);
    final target = ref
        .watch(calorieTargetProvider)
        .asData
        ?.value
        .resolution
        ?.targetKcal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppTheme.accentRed),
          ),
        ),
        for (final entry in entries)
          Dismissible(
            key: ValueKey(entry.id),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (_) {
              ref.read(foodNotifierProvider).delete(entry.id);
            },
            child: Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(entry.name),
                subtitle: Text(
                  [
                    if (entry.servingLabel != null) entry.servingLabel,
                    if (entry.servings != 1) '${entry.servings} servings',
                    if (entry.totalCalories != null)
                      '${_pretty(entry.totalCalories!)} kcal',
                    if (entry.totalCalories != null &&
                        target != null &&
                        target > 0)
                      '${percentOfTarget(amount: entry.totalCalories!, target: target)}% of daily calories',
                  ].join(' · '),
                ),
                trailing: Text(
                  [
                    if (entry.totalProteinG != null)
                      'P ${_pretty(entry.totalProteinG!)}',
                    if (entry.totalCarbsG != null)
                      'C ${_pretty(entry.totalCarbsG!)}',
                    if (entry.totalFatG != null)
                      'F ${_pretty(entry.totalFatG!)}',
                  ].join('  '),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FoodEntryReviewScreen(existing: entry),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  String _pretty(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }
}

Widget _buildDayCell(
  DateTime day, {
  required bool hasFood,
  required bool isToday,
  required bool isSelected,
}) {
  return Container(
    alignment: Alignment.center,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.accentRed
                : hasFood
                ? AppTheme.accentRed.withValues(alpha: 0.45)
                : (isToday ? Colors.grey[800] : Colors.transparent),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '${day.day}',
            style: TextStyle(
              color: Colors.white,
              fontWeight: isToday || isSelected
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ),
        if (hasFood)
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Text(
              'Food',
              style: TextStyle(fontSize: 9, color: Colors.grey),
            ),
          ),
      ],
    ),
  );
}
