import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:larger/models/models.dart';
import 'package:larger/providers/food_provider.dart';
import 'package:larger/screens/food_entry_review_screen.dart';
import 'package:larger/services/nutrition_label_parser.dart';
import 'package:larger/services/nutrition_ocr_service.dart';
import 'package:larger/theme/app_theme.dart';
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
          const SnackBar(content: Text('No nutrition text found. Add it manually.')),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not scan label: $error')),
      );
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

  @override
  Widget build(BuildContext context) {
    final daysWithFood = ref.watch(foodDaysWithEntriesProvider);
    final dayEntries = ref.watch(foodEntriesForDayProvider(_selectedDay));
    final totals = ref.watch(foodDayTotalsProvider(_selectedDay));

    return Scaffold(
      appBar: AppBar(title: const Text('FOOD')),
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
              data: (value) => _DayTotalsBar(totals: value),
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

class _DayTotalsBar extends StatelessWidget {
  const _DayTotalsBar({required this.totals});

  final FoodDayTotals totals;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _TotalChip(label: 'kcal', value: totals.calories),
        _TotalChip(label: 'P', value: totals.proteinG, suffix: 'g'),
        _TotalChip(label: 'C', value: totals.carbsG, suffix: 'g'),
        _TotalChip(label: 'F', value: totals.fatG, suffix: 'g'),
      ],
    );
  }
}

class _TotalChip extends StatelessWidget {
  const _TotalChip({
    required this.label,
    required this.value,
    this.suffix = '',
  });

  final String label;
  final double value;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final shown = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
    return Column(
      children: [
        Text(
          '$shown$suffix',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
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
                    if (entry.servings != 1)
                      '${entry.servings} servings',
                    if (entry.totalCalories != null)
                      '${_pretty(entry.totalCalories!)} kcal',
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
