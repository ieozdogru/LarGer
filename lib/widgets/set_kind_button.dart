import 'package:flutter/material.dart';
import 'package:larger/models/models.dart';
import 'package:larger/theme/app_theme.dart';

class SetKindButton extends StatelessWidget {
  final int setNumber;
  final WorkoutSetKind kind;
  final ValueChanged<WorkoutSetKind> onChanged;

  const SetKindButton({
    super.key,
    required this.setNumber,
    required this.kind,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final label = kind == WorkoutSetKind.working
        ? '$setNumber'
        : kind.shortLabel;
    return SizedBox(
      width: 40,
      child: PopupMenuButton<WorkoutSetKind>(
        tooltip: 'Set type',
        padding: EdgeInsets.zero,
        initialValue: kind,
        onSelected: onChanged,
        itemBuilder: (context) => [
          for (final option in WorkoutSetKind.values)
            PopupMenuItem(value: option, child: Text(option.menuLabel)),
        ],
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _kindColor(kind),
          ),
        ),
      ),
    );
  }
}

Color? _kindColor(WorkoutSetKind kind) {
  return switch (kind) {
    WorkoutSetKind.working => null,
    WorkoutSetKind.warmup => Colors.white54,
    WorkoutSetKind.failure => Colors.orange,
    WorkoutSetKind.drop => AppTheme.accentRed,
  };
}
